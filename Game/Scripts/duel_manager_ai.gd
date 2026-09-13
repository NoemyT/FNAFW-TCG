extends Node

## Runs a match against the AI: turn flow, combat resolution and end of game.
##
## Also drives the AI itself, which does not run on any kind of learning model
## but on a fixed set of rules, in the spirit of an expert system: draw up to the
## limit, place the strongest entity that fits, play one skill if it would hit
## something, then attack with everything on the field.
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
## Pause between steps of a turn, giving the player time to follow what is
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
var is_opp_turn := false
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

	input_manager.inputs_disabled = true
	enable_end_turn_btn(false)
	enable_attack_btn(false)

	turn_timer = Timer.new()
	turn_timer.one_shot = true
	add_child(turn_timer)

	player_health = STARTING_HEALTH
	opponent_health = STARTING_HEALTH
	player_side.get_node("Hp/PlayerHp").text = str(player_health)
	opp_side.get_node("Hp/OppHp").text = str(opponent_health)

	player_side.get_node("FieldManager").card_placed.connect(_on_card_placed.bind(GameState.OWNER_PLAYER))
	opp_side.get_node("FieldManager").card_placed.connect(_on_card_placed.bind(GameState.OWNER_OPPONENT))

	player_side.get_node("AttackButton").pressed.connect(_on_attack_button_pressed)
	player_side.get_node("EndTurnButton").pressed.connect(_on_end_turn_button_pressed)

	# Pausing is blocked during the coin flip so the sequence cannot be
	# interrupted halfway through.
	PlayerInputs.block_pause = true
	await get_tree().create_timer(0.2).timeout

	var player_starts = randf() < 0.5
	await coin_flip.flip(player_starts)
	PlayerInputs.block_pause = false

	if player_starts:
		GameState.is_player_turn = true
		enable_end_turn_btn(true)
		input_manager.inputs_disabled = false
	else:
		GameState.is_player_turn = false
		await opp_turn()


## Gives skill scripts access to the opponent's animation node, since a skill
## played by the AI has to animate over the player's half of the board.
func get_opp_skills_node():
	return opp_skills_node


## Reacts to a card landing on the field: entities are tracked for combat,
## while skills fire their effect right away.
func _on_card_placed(card, which_owner) -> void:
	if which_owner == GameState.OWNER_PLAYER:
		if card.card_type == "entity":
			player_cards_on_field.append(card)
			refresh_attack_btn_visibility()
		else:
			card.skill_script.trigger_skill(self, card, input_manager)
	else:
		if card.card_type == "entity":
			opp_cards_on_field.append(card)


## Resolves the player's attack. Every entity on the field attacks at once, so
## this runs through them in sequence and only hands control back at the end.
func _on_attack_button_pressed() -> void:
	if game_over or first_turn or attacked_this_turn or is_opp_turn or player_cards_on_field.is_empty():
		return
	attacked_this_turn = true
	input_manager.inputs_disabled = true
	enable_attack_btn(false)
	enable_end_turn_btn(false)

	await resolve_attacks(GameState.OWNER_PLAYER)

	if player_health == 0 or opponent_health == 0:
		return
	input_manager.inputs_disabled = false
	enable_end_turn_btn(true)


## Shows the attack button only when attacking is actually possible, so the
## player is never offered an action that would be refused.
func refresh_attack_btn_visibility():
	var can_attack = not first_turn and not attacked_this_turn and not is_opp_turn and not game_over and not player_cards_on_field.is_empty()
	enable_attack_btn(can_attack)


func _on_end_turn_button_pressed() -> void:
	if game_over:
		return
	AudioController.play_menu_click()
	enable_end_turn_btn(false)
	enable_attack_btn(false)
	input_manager.inputs_disabled = true

	first_turn = false

	if _check_for_stalemate():
		return

	await opp_turn()


## Runs the AI's whole turn: draw, place, attack, then hand the turn back.
## Each step is awaited so the player can follow what the AI is doing.
func opp_turn():
	if game_over:
		return
	is_opp_turn = true
	GameState.is_player_turn = false
	await wait(TURN_TIME)

	var opp_deck = opp_side.get_node("Deckpile")
	opp_deck.reset_draw()
	var opp_hand = opp_side.get_node("Hand")
	while opp_deck.deck.size() > 0 and opp_hand.hand.size() < opp_deck.MAX_HAND_SIZE and opp_deck.can_draw():
		opp_deck.draw_card_local()
		await wait(TURN_TIME)

	await _ai_try_place_card()

	if not first_turn and not opp_cards_on_field.is_empty():
		await resolve_attacks(GameState.OWNER_OPPONENT)
		if game_over:
			return

	_end_opp_turn()


## The AI's placement logic, and the closest thing it has to strategy.
##
## Entities are placed greedily, strongest first, looping until nothing else
## fits. A skill is only played if the player actually has cards on the field,
## since every skill damages cards and playing one against an empty board would
## simply waste it. Unlike the player, the AI uses at most one skill per turn.
func _ai_try_place_card() -> void:
	var opp_hand = opp_side.get_node("Hand")
	var opp_field_manager = opp_side.get_node("FieldManager")

	var placed_any := true
	while placed_any:
		placed_any = false
		var entities = opp_hand.hand.filter(func(c): return c.card_type == "entity")
		entities.sort_custom(func(a, b): return a.attack > b.attack)

		for card in entities:
			if opp_field_manager.try_place_card(card):
				await wait(TURN_TIME)
				placed_any = true
				break

	var skills = opp_hand.hand.filter(func(c): return c.card_type == "skill")
	for card in skills:
		if player_cards_on_field:
			if opp_field_manager.try_place_card(card):
				await card.skill_script.trigger_skill_opp(self, card, input_manager)
				break
		else:
			return


## Hands the turn back to the player and re-enables their actions.
func _end_opp_turn() -> void:
	player_side.get_node("Deckpile").reset_draw()
	is_opp_turn = false
	GameState.is_player_turn = true
	attacked_this_turn = false
	first_turn = false

	if _check_for_stalemate():
		return

	enable_end_turn_btn(true)
	enable_attack_btn(not player_cards_on_field.is_empty())
	input_manager.inputs_disabled = false


# ---------- Combat ----------

## Resolves every attack from one side in a single pass.
##
## Each attacking card looks for an enemy card of the same color: finding one
## means they clash and damage each other, while finding none means the attack
## goes straight to the opponent's life points. The list is duplicated because
## cards may be destroyed while it is being walked.
func resolve_attacks(attacking_owner):
	var attacking_list = (player_cards_on_field if attacking_owner == GameState.OWNER_PLAYER else opp_cards_on_field).duplicate()
	var defending_list = opp_cards_on_field if attacking_owner == GameState.OWNER_PLAYER else player_cards_on_field

	for card in attacking_list:
		if game_over or card.defeated:
			continue
		var blocker = _find_matching_color_defender(card, defending_list)
		if blocker:
			await _clash(card, blocker, attacking_owner)
		else:
			await _direct_attack(card, attacking_owner)
			if player_health == 0 or opponent_health == 0:
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


## Ends the match when one side runs out of life, showing the matching result
## screen. Guarded so it only ever runs once.
func end_game():
	if game_over:
		return
	game_over = true
	PlayerInputs.block_pause = true
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
