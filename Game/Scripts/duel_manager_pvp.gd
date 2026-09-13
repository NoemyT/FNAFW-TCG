extends Node

## Runs a PvP match: turn flow, combat resolution and end of game.
##
## Shares most of its logic with the AI duel manager, since combat itself works
## the same regardless of who is playing. What differs is that every action a
## player takes has to reach the other machine, so the entry points below are
## paired with RPCs that replay the same action on the opponent's instance.
##
## Sits outside both halves of the board, in the duel scene, and reaches into
## them through the exported paths below.

@export var player_side_path: NodePath
@export var opp_side_path: NodePath
@export var input_manager_path: NodePath
@export var result_screen_path: NodePath
@export var player_skills_path: NodePath
@export var opp_skills_path: NodePath
@export var coin_flip_path: NodePath

## Duration of the card movement tweens.
const CARD_MOVE_SPEED = 0.1
## Pause between steps of a turn, giving both players time to follow what is
## happening instead of seeing everything resolve at once.
const TURN_TIME = 1
const ATTACK_TIME = 0.2
const STARTING_HEALTH = 20
## How far an attacking card moves towards the card it clashes with.
const BATTLE_POS_OFFSET = 25
## How far a card lunges across the board when attacking life points directly.
const DIRECT_ATTACK_LUNGE = 1400
const CARD_MOVING_Z_INDEX = 3

var player_side: Node
var opp_side: Node
var input_manager: Node
var result_screen: Control
var player_skills_node: Node
var opp_skills_node: Node
var coin_flip: Control

var turn_timer: Timer
var player_cards_on_field = []
var opp_cards_on_field = []
var player_health: int
var opponent_health: int
## Blocks attacking on the opening turn, so the player who goes second has a
## chance to set up a defence. Cleared as soon as the first turn ends.
var first_turn := true
## Whether it is this instance's turn. Both players run their own copy of this
## script, so each one tracks its own side of the alternation.
var is_my_turn := false
var attacked_this_turn := false
## Set once the match is decided, keeping any pending action from resolving
## after the result screen is already up.
var game_over := false
## Ever increasing counters giving each discarded card a higher depth than the
## last, so the graveyard stacks in the order cards arrive.
var player_cemetery_z_counter := 0
var opp_cemetery_z_counter := 0


func _ready() -> void:
	player_side = get_node(player_side_path)
	opp_side = get_node(opp_side_path)
	input_manager = get_node(input_manager_path)
	result_screen = get_node(result_screen_path)
	player_skills_node = get_node(player_skills_path)
	opp_skills_node = get_node(opp_skills_path)
	coin_flip = get_node(coin_flip_path)

	turn_timer = Timer.new()
	turn_timer.one_shot = true
	add_child(turn_timer)

	player_health = STARTING_HEALTH
	opponent_health = STARTING_HEALTH

	player_side.get_node("FieldManager").card_placed.connect(_on_card_placed.bind(GameState.OWNER_PLAYER))
	opp_side.get_node("FieldManager").card_placed.connect(_on_card_placed.bind(GameState.OWNER_OPPONENT))

	player_side.get_node("AttackButton").pressed.connect(_on_attack_button_pressed)
	player_side.get_node("EndTurnButton").pressed.connect(_on_end_turn_button_pressed)

	enable_end_turn_btn(false)
	enable_attack_btn(false)
	input_manager.inputs_disabled = true

	# Only the host rolls for turn order, then sends the result over. Rolling on
	# both machines would give two different answers, and each player could end
	# up believing it was their turn.
	if GameState.current_pvp_type == GameState.PVPType.HOST:
		await get_tree().create_timer(0.2).timeout
		var host_starts = randf() < 0.5
		rpc("_remote_coin_flip", host_starts)
		_do_coin_flip(host_starts)


## Gives skill scripts access to the opponent's animation node, since a skill
## played by the other player has to animate over this side of the board.
func get_opp_skills_node():
	return opp_skills_node


## Plays the coin flip and sets up the first turn from its result.
##
## Both machines receive the same roll, but each shows the side matching its own
## outcome, so whoever starts sees heads and the other sees tails.
func _do_coin_flip(host_starts) -> void:
	PlayerInputs.block_pause = true
	var is_host = GameState.current_pvp_type == GameState.PVPType.HOST
	var local_starts = host_starts if is_host else not host_starts

	await coin_flip.flip(local_starts)

	is_my_turn = local_starts
	GameState.is_player_turn = is_my_turn
	enable_end_turn_btn(is_my_turn)
	enable_attack_btn(false)
	input_manager.inputs_disabled = not is_my_turn
	PlayerInputs.block_pause = false


## Carries the host's roll over to the client.
@rpc("any_peer")
func _remote_coin_flip(host_starts) -> void:
	_do_coin_flip(host_starts)


## Reacts to a card landing on the field, on either side. The placement itself
## is already synchronized by FieldManager, so this only tracks entities for
## combat and fires skill effects.
func _on_card_placed(card, which_owner) -> void:
	if which_owner == GameState.OWNER_PLAYER:
		if card.card_type == "entity":
			player_cards_on_field.append(card)
			refresh_attack_btn_visibility()
		else:
			if is_my_turn:
				card.skill_script.trigger_skill(self, card, input_manager)
	else:
		if card.card_type == "entity":
			opp_cards_on_field.append(card)
		else:
			card.skill_script.trigger_skill_opp(self, card, input_manager)


## Resolves this player's attack. Every entity on the field attacks at once, so
## this runs through them in sequence and only hands control back at the end.
func _on_attack_button_pressed() -> void:
	if game_over or first_turn or attacked_this_turn or not is_my_turn or player_cards_on_field.is_empty():
		return
	attacked_this_turn = true
	input_manager.inputs_disabled = true
	enable_attack_btn(false)
	enable_end_turn_btn(false)

	await resolve_attacks()

	if game_over:
		return
	input_manager.inputs_disabled = false
	enable_end_turn_btn(true)


## Shows the attack button only when attacking is actually possible, so the
## player is never offered an action that would be refused.
func refresh_attack_btn_visibility():
	var can_attack = not first_turn and not attacked_this_turn and is_my_turn and not game_over and not player_cards_on_field.is_empty()
	enable_attack_btn(can_attack)


## Resolves one card's attack: it clashes with an enemy card of the same color
## if there is one, and otherwise hits life points directly. Shared by both
## machines, so the same attack plays out identically on each.
func _resolve_single_attack(card, defending_list, attacking_owner) -> void:
	var blocker = _find_matching_color_defender(card, defending_list)
	if blocker:
		await _clash(card, blocker, attacking_owner)
	else:
		await _direct_attack(card, attacking_owner)


## Replays an attack on the receiving machine, from the opponent's side.
##
## The card is identified by name rather than by reference, since the same card
## sits in a different place in each instance's scene tree.
@rpc("any_peer")
func _remote_resolve_single_attack(card_name) -> void:
	var name_str = String(card_name)
	if not opp_side.get_node("FieldManager").has_node(name_str):
		return
	var card = opp_side.get_node("FieldManager").get_node(name_str)
	if card.defeated:
		return
	await _resolve_single_attack(card, player_cards_on_field, GameState.OWNER_OPPONENT)


## Ends this player's turn and hands it over. The RPC is sent before checking
## for a stalemate, so the other player is notified either way.
func _on_end_turn_button_pressed() -> void:
	if game_over or not is_my_turn:
		return
	AudioController.play_menu_click()
	enable_end_turn_btn(false)
	enable_attack_btn(false)
	input_manager.inputs_disabled = true

	first_turn = false
	is_my_turn = false
	GameState.is_player_turn = false
	rpc("_remote_start_turn")
	_check_for_stalemate()


## Starts this player's turn, called by the opponent ending theirs. This is
## what drives the alternation between the two machines.
@rpc("any_peer")
func _remote_start_turn() -> void:
	first_turn = false
	is_my_turn = true
	GameState.is_player_turn = true
	attacked_this_turn = false
	if _check_for_stalemate():
		return
	player_side.get_node("Deckpile").reset_draw()
	enable_end_turn_btn(true)
	enable_attack_btn(not player_cards_on_field.is_empty())
	input_manager.inputs_disabled = false


## Resolves every attack from this side, one card at a time.
##
## The RPC is sent per card rather than once for the whole turn: each call is a
## point where both machines line up again, which keeps the animations from
## drifting apart over a long sequence of attacks.
func resolve_attacks():
	var attacking_list = player_cards_on_field.duplicate()

	for card in attacking_list:
		if game_over or card.defeated:
			continue
		rpc("_remote_resolve_single_attack", card.name)
		await _resolve_single_attack(card, opp_cards_on_field, GameState.OWNER_PLAYER)
		if game_over:
			return


## Finds an enemy card of the same color that can block this attack, or null if
## the attack goes through unblocked.
func _find_matching_color_defender(card, defending_list):
	for defender in defending_list:
		if not defender.defeated and defender.card_color == card.card_color:
			return defender
	return null


## Attacks the opponent's life points directly. The card lunges across the
## board, deals its damage and returns to its slot.
func _direct_attack(card, attacker_owner) -> void:
	card.z_index = 5
	var lunge_offset = Vector2(-DIRECT_ATTACK_LUNGE, 0) if attacker_owner == GameState.OWNER_PLAYER else Vector2(DIRECT_ATTACK_LUNGE, 0)

	var lunge_tween = get_tree().create_tween()
	lunge_tween.tween_property(card, "position", card.position + lunge_offset, CARD_MOVE_SPEED)
	AudioController.play_direct_attack()
	await wait(ATTACK_TIME)

	if attacker_owner == GameState.OWNER_PLAYER:
		opponent_health = max(0, opponent_health - card.attack)
		opp_side.get_node("Hp/OppHp").text = str(opponent_health)
		flash_damage_color(opp_side.get_node("Hp/OppHp"), Color.RED, 0.2)
	else:
		player_health = max(0, player_health - card.attack)
		player_side.get_node("Hp/PlayerHp").text = str(player_health)
		flash_damage_color(player_side.get_node("Hp/PlayerHp"), Color.RED, 0.2)

	if player_health == 0 or opponent_health == 0:
		end_game()
		return

	var return_tween = get_tree().create_tween()
	return_tween.tween_property(card, "position", card.card_placement.position, CARD_MOVE_SPEED)
	await wait(TURN_TIME)

	card.z_index = 1


## Briefly tints a label red and fades it back, drawing attention to a life
## total that just changed.
func flash_damage_color(label, flash_color, duration):
	var original_color = label.modulate
	label.modulate = flash_color
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate", original_color, duration)


## Resolves a clash between two cards of the same color. Damage is mutual, so
## either or both may end up destroyed.
func _clash(attacking_card, defending_card, attacker_owner) -> void:
	attacking_card.z_index = 5
	var y_offset = BATTLE_POS_OFFSET if attacker_owner == GameState.OWNER_PLAYER else -BATTLE_POS_OFFSET
	var bump_pos = Vector2(defending_card.position.x, defending_card.position.y + y_offset)

	var attack_tween = get_tree().create_tween()
	attack_tween.tween_property(attacking_card, "position", bump_pos, CARD_MOVE_SPEED)
	AudioController.play_clash_attack()
	await wait(ATTACK_TIME)

	var return_tween = get_tree().create_tween()
	return_tween.tween_property(attacking_card, "position", attacking_card.card_placement.position, CARD_MOVE_SPEED)
	await wait(TURN_TIME)

	defending_card.health = max(0, defending_card.health - attacking_card.attack)
	defending_card.get_node("HpL").text = str(defending_card.health)
	damage_color(defending_card.get_node("HpL"), Color.RED, 0.2)

	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("HpL").text = str(attacking_card.health)
	damage_color(attacking_card.get_node("HpL"), Color.RED, 0.2)

	await wait(TURN_TIME)
	attacking_card.z_index = 1

	var destroyed = false
	if attacking_card.health == 0:
		_destroy_card(attacking_card, attacker_owner)
		destroyed = true
	if defending_card.health == 0:
		var defender_owner = GameState.OWNER_OPPONENT if attacker_owner == GameState.OWNER_PLAYER else GameState.OWNER_PLAYER
		_destroy_card(defending_card, defender_owner)
		destroyed = true

	if destroyed:
		await wait(TURN_TIME)


## Tints a card's health label as it takes damage.
func damage_color(label, color, duration):
	var tween = get_tree().create_tween()
	tween.tween_property(label, "modulate", color, duration)


## Sends a destroyed card to the graveyard: its slot is freed for a new card,
## it stops taking part in combat, and it is stacked on top of the pile.
func _destroy_card(card, card_owner) -> void:
	if card.card_placement == null:
		return

	card.defeated = true
	card.card_placement.card_placed_in = false
	card.card_placement = null
	card.get_node("Area2D/CollisionShape2D").disabled = true
	card.z_index = CARD_MOVING_Z_INDEX

	if card_owner == GameState.OWNER_PLAYER:
		player_cards_on_field.erase(card)
		player_cemetery_z_counter += 1
		card.z_index = player_cemetery_z_counter
	else:
		opp_cards_on_field.erase(card)
		opp_cemetery_z_counter += 1
		card.z_index = opp_cemetery_z_counter

	var cemetery = player_side.get_node("Cemetery") if card_owner == GameState.OWNER_PLAYER else opp_side.get_node("Cemetery")
	var move_tween = get_tree().create_tween()
	move_tween.tween_property(card, "position", cemetery.position, CARD_MOVE_SPEED)


## Pauses for the given time. Used throughout to pace the match.
func wait(time):
	turn_timer.wait_time = time
	turn_timer.start()
	await turn_timer.timeout


## Buttons are hidden as well as disabled, so the player only ever sees an
## action that is currently available.
func enable_end_turn_btn(is_enabled):
	var btn = player_side.get_node("EndTurnButton")
	btn.disabled = not is_enabled
	btn.visible = is_enabled


func enable_attack_btn(is_enabled):
	var btn = player_side.get_node("AttackButton")
	btn.disabled = not is_enabled
	btn.visible = is_enabled


## Ends the match when one side runs out of life. Both machines reach this on
## their own, since combat resolves identically on each, so no extra RPC is
## needed to agree on the result.
func end_game():
	if game_over:
		return
	game_over = true
	PlayerInputs.block_pause = true
	MultiplayerManager.game_active = false
	enable_attack_btn(false)
	enable_end_turn_btn(false)
	result_screen.visible = true

	if player_health == 0:
		AudioController.stop_battle_music()
		AudioController.play_defeat_music()
		result_screen.get_node("AnimationPlayer").play("ResultDefeat")
	elif opponent_health == 0:
		AudioController.stop_battle_music()
		AudioController.play_victory_music()
		result_screen.get_node("AnimationPlayer").play("ResultWin")


## Checks whether both players have run out of cards entirely, with none left
## in deck, hand or field. Called on every turn change, since that is the only
## point where the card counts can have changed.
func _check_for_stalemate() -> bool:
	var player_deck = player_side.get_node("Deckpile").deck
	var player_hand = player_side.get_node("Hand").hand
	var opp_deck = opp_side.get_node("Deckpile").deck
	var opp_hand = opp_side.get_node("Hand").hand

	var player_out_of_cards = player_deck.is_empty() and player_hand.is_empty() and player_cards_on_field.is_empty()
	var opp_out_of_cards = opp_deck.is_empty() and opp_hand.is_empty() and opp_cards_on_field.is_empty()

	if player_out_of_cards and opp_out_of_cards:
		_end_game_stalemate()
		return true
	return false


## Ends a match that ran out of cards. With no way left to deal damage, the
## player with more life wins, and equal life is a draw.
func _end_game_stalemate() -> void:
	if game_over:
		return
	game_over = true
	PlayerInputs.block_pause = true
	enable_attack_btn(false)
	enable_end_turn_btn(false)
	result_screen.visible = true
	AudioController.stop_battle_music()

	if player_health == opponent_health:
		AudioController.play_draw_music()
		result_screen.get_node("AnimationPlayer").play("ResultDraw")
	elif player_health > opponent_health:
		AudioController.play_victory_music()
		result_screen.get_node("AnimationPlayer").play("ResultWin")
	else:
		AudioController.play_defeat_music()
		result_screen.get_node("AnimationPlayer").play("ResultDefeat")
