extends Node

@export var player_side_path: NodePath
@export var opp_side_path: NodePath
@export var input_manager_path: NodePath
@export var result_screen_path: NodePath
@export var pause_menu_path: NodePath
@export var pause_menu_opp_path: NodePath
@export var player_skills_path: NodePath
@export var opp_skills_path: NodePath

const CARD_MOVE_SPEED = 0.1
const TURN_TIME = 1
const ATTACK_TIME = 0.15
const STARTING_HEALTH = 20
const BATTLE_POS_OFFSET = 25
const DIRECT_ATTACK_LUNGE = 1400.0

var player_side: Node
var opp_side: Node
var input_manager: Node
var result_screen: Control
var pause_menu: Control
var pause_menu_opp: Control
var player_skills_node: Node
var opp_skills_node: Node

var turn_timer: Timer
var player_cards_on_field = []
var opp_cards_on_field = []
var player_health: int
var opponent_health: int
var first_turn := true
var is_my_turn := false
var attacked_this_turn := false
var game_over := false


func _ready() -> void:
	player_side = get_node(player_side_path)
	opp_side = get_node(opp_side_path)
	input_manager = get_node(input_manager_path)
	result_screen = get_node(result_screen_path)
	pause_menu = get_node(pause_menu_path)
	pause_menu_opp = get_node(pause_menu_opp_path)
	player_skills_node = get_node(player_skills_path)
	opp_skills_node = get_node(opp_skills_path)

	turn_timer = Timer.new()
	turn_timer.one_shot = true
	add_child(turn_timer)

	player_health = STARTING_HEALTH
	opponent_health = STARTING_HEALTH

	player_side.get_node("FieldManager").card_placed.connect(_on_card_placed.bind(GameState.OWNER_PLAYER))
	opp_side.get_node("FieldManager").card_placed.connect(_on_card_placed.bind(GameState.OWNER_OPPONENT))

	player_side.get_node("AttackButton").pressed.connect(_on_attack_button_pressed)
	player_side.get_node("EndTurnButton").pressed.connect(_on_end_turn_button_pressed)

	is_my_turn = GameState.current_pvp_type == GameState.PVPType.HOST
	enable_end_turn_btn(is_my_turn)
	enable_attack_btn(false)


func get_opp_skills_node():
	return opp_skills_node


func _on_card_placed(card, which_owner) -> void:
	if which_owner == GameState.OWNER_PLAYER:
		if card.card_type == "entity":
			player_cards_on_field.append(card)
			if not first_turn and not attacked_this_turn and is_my_turn and not game_over:
				enable_attack_btn(true)
		else:
			card.skill_script.trigger_skill(self, card, input_manager)
	else:
		if card.card_type == "entity":
			opp_cards_on_field.append(card)
		else:
			card.skill_script.trigger_skill_opp(self, card, input_manager)


func _on_attack_button_pressed() -> void:
	if game_over or first_turn or attacked_this_turn or not is_my_turn or player_cards_on_field.is_empty():
		return
	attacked_this_turn = true
	input_manager.inputs_disabled = true
	enable_attack_btn(false)
	enable_end_turn_btn(false)

	rpc("_remote_resolve_attacks")
	await resolve_attacks(GameState.OWNER_PLAYER)

	if game_over:
		return
	input_manager.inputs_disabled = false
	enable_end_turn_btn(true)


@rpc("any_peer")
func _remote_resolve_attacks() -> void:
	await resolve_attacks(GameState.OWNER_OPPONENT)


func _on_end_turn_button_pressed() -> void:
	if game_over or not is_my_turn:
		return
	AudioController.play_menu_click()
	enable_end_turn_btn(false)
	enable_attack_btn(false)
	input_manager.inputs_disabled = true

	first_turn = false
	is_my_turn = false
	rpc("_remote_start_turn")


@rpc("any_peer")
func _remote_start_turn() -> void:
	first_turn = false
	is_my_turn = true
	attacked_this_turn = false
	player_side.get_node("Deckpile").reset_draw()
	enable_end_turn_btn(true)
	enable_attack_btn(not player_cards_on_field.is_empty())
	input_manager.inputs_disabled = false


# ---------- Combat ----------
func resolve_attacks(attacking_owner):
	var attacking_list = (player_cards_on_field if attacking_owner == GameState.OWNER_PLAYER else opp_cards_on_field).duplicate()
	var defending_list = opp_cards_on_field if attacking_owner == GameState.OWNER_PLAYER else player_cards_on_field

	for card in attacking_list:
		if game_over or card.defeated:
			continue
		var blocker = _find_matching_color_defender(card, defending_list)
		if blocker:
			await _clash(card, blocker, attacking_owner)
		elif not blocker and attacking_owner == GameState.OWNER_OPPONENT:
			await _direct_attack(card, attacking_owner)
			if player_health == 0:
				return
		else:
			await _direct_attack(card, attacking_owner)
			if opponent_health == 0:
				return


func _find_matching_color_defender(card, defending_list):
	for defender in defending_list:
		if not defender.defeated and defender.card_color == card.card_color:
			return defender
	return null


func _direct_attack(card, attacker_owner) -> void:
	card.z_index = 7
	var lunge_offset = Vector2(-DIRECT_ATTACK_LUNGE, 0) if attacker_owner == GameState.OWNER_PLAYER else Vector2(DIRECT_ATTACK_LUNGE, 0)

	var lunge_tween = get_tree().create_tween()
	lunge_tween.tween_property(card, "position", card.position + lunge_offset, CARD_MOVE_SPEED)
	AudioController.play_direct_attack()
	await wait(ATTACK_TIME)

	if attacker_owner == GameState.OWNER_PLAYER:
		opponent_health = max(0, opponent_health - card.attack)
		opp_side.get_node("Hp/OppHp").text = str(opponent_health)
	else:
		player_health = max(0, player_health - card.attack)
		player_side.get_node("Hp/PlayerHp").text = str(player_health)

	if player_health == 0 or opponent_health == 0:
		end_game()
		return

	var return_tween = get_tree().create_tween()
	return_tween.tween_property(card, "position", card.card_placement.position, CARD_MOVE_SPEED)
	card.z_index = 0
	await wait(TURN_TIME)


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

	attacking_card.health = max(0, attacking_card.health - defending_card.attack)
	attacking_card.get_node("HpL").text = str(attacking_card.health)

	await wait(TURN_TIME)
	attacking_card.z_index = 0

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


func _destroy_card(card, card_owner) -> void:
	if card.card_placement == null:
		return

	card.defeated = true
	card.card_placement.card_placed_in = false
	card.card_placement = null
	card.get_node("Area2D/CollisionShape2D").disabled = true

	if card_owner == GameState.OWNER_PLAYER:
		player_cards_on_field.erase(card)
	else:
		opp_cards_on_field.erase(card)

	var cemetery = player_side.get_node("Cemetery") if card_owner == GameState.OWNER_PLAYER else opp_side.get_node("Cemetery")
	var move_tween = get_tree().create_tween()
	move_tween.tween_property(card, "position", cemetery.position, CARD_MOVE_SPEED)


func wait(time):
	turn_timer.wait_time = time
	turn_timer.start()
	await turn_timer.timeout


func enable_end_turn_btn(is_enabled):
	var btn = player_side.get_node("EndTurnButton")
	btn.disabled = not is_enabled
	btn.visible = is_enabled


func enable_attack_btn(is_enabled):
	var btn = player_side.get_node("AttackButton")
	btn.disabled = not is_enabled
	btn.visible = is_enabled


func end_game():
	if game_over:
		return
	game_over = true
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
