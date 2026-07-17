extends Node2D

@export_enum("player", "opponent") var owner_id: String = GameState.OWNER_PLAYER
@export var hand_path: NodePath
@export var field_manager_path: NodePath

const CARD_DRAW_SPEED = 0.4
const STARTING_HAND_SIZE = 7
const MAX_DRAWS_PER_TURN = 3
const MAX_HAND_SIZE = 7

var deck = []
var draws_this_turn := MAX_DRAWS_PER_TURN
var deck_timer: Timer
var remote_deck_count := -1

func _ready() -> void:
	deck_timer = Timer.new()
	deck_timer.one_shot = true
	deck_timer.wait_time = 1.0
	add_child(deck_timer)

	_build_deck()

	if GameState.current_mode == GameState.GameMode.AI:
		_draw_starting_hand_local()
	elif GameState.current_mode == GameState.GameMode.PVP and owner_id == GameState.OWNER_OPPONENT:
		remote_deck_count = CardDatabase.get_total_deck_size()


func _build_deck() -> void:
	deck = CardDatabase.build_shuffled_deck()


# ---------- AI mode: local draws ----------
func _draw_starting_hand_local() -> void:
	for i in range(STARTING_HAND_SIZE):
		var card_name = deck[0]
		deck.erase(card_name)
		_spawn_card(card_name)


func draw_card_local():
	if draws_this_turn >= MAX_DRAWS_PER_TURN:
		return
	if get_node(hand_path).hand.size() >= MAX_HAND_SIZE:
		return
	draws_this_turn += 1
	var card_name = deck[0]
	deck.erase(card_name)
	_spawn_card(card_name)


func can_draw():
	return draws_this_turn < MAX_DRAWS_PER_TURN


# ---------- PVP mode: host-authoritative, networked ----------
@warning_ignore("unused_parameter")
func draw_first_hand_networked(is_host):
	deck_timer.start()
	await deck_timer.timeout
	deck_timer.wait_time = 0.1
	var player_id = multiplayer.get_unique_id()
	for i in range(STARTING_HAND_SIZE):
		var card_name = deck[0]
		_draw_for_all(player_id, card_name)
		rpc("_draw_for_all", player_id, card_name)
		deck_timer.start()
		await deck_timer.timeout


func deck_clicked_networked():
	if draws_this_turn >= MAX_DRAWS_PER_TURN:
		return
	if get_node(hand_path).hand.size() >= MAX_HAND_SIZE:
		return
	draws_this_turn += 1
	var card_name = deck[0]
	var player_id = multiplayer.get_unique_id()
	_draw_for_all(player_id, card_name)
	rpc("_draw_for_all", player_id, card_name)


@rpc("any_peer")
func _draw_for_all(player_id, card_name) -> void:
	if multiplayer.get_unique_id() == player_id:
		draw_card_networked(card_name)
	else:
		MultiplayerManager.opp_field.get_node("Deckpile").receive_card(card_name)


func receive_card(card_name):
	_spawn_card(card_name)
	if remote_deck_count >= 0:
		remote_deck_count -= 1
		if remote_deck_count <= 0:
			_hide_deck_visual()


func draw_card_networked(card_name):
	deck.erase(card_name)
	_spawn_card(card_name)


# ---------- Shared spawn ----------
func _spawn_card(card_name) -> void:
	var new_card = CardFactory.create_card(card_name, owner_id)
	new_card.position = self.position
	get_node(field_manager_path).add_child(new_card)
	new_card.name = "Card"

	new_card.get_node("Area2D/CollisionShape2D").disabled = true
	get_node(hand_path).add_card_to_hand(new_card, CARD_DRAW_SPEED)
	get_tree().create_timer(CARD_DRAW_SPEED).timeout.connect(
		func():
			if is_instance_valid(new_card):
				new_card.get_node("Area2D/CollisionShape2D").disabled = false
	)

	if owner_id == GameState.OWNER_OPPONENT:
		new_card.get_node("AnimationPlayer").play("card_flip_opponent")
	elif new_card.card_type == "entity":
		new_card.get_node("AnimationPlayer").play("card_play_entity")
	else:
		new_card.get_node("AnimationPlayer").play("card_play_skill")

	if deck.size() == 0:
		_hide_deck_visual()


func _hide_deck_visual() -> void:
	if has_node("Area2D/CollisionShape2D"):
		$Area2D/CollisionShape2D.disabled = true
	if has_node("Sprite2D"):
		$Sprite2D.visible = false


func reset_draw():
	draws_this_turn = 0
