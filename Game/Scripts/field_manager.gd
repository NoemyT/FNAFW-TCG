extends Node2D

signal card_placed(card)

@export_enum("player", "opponent") var owner_id: String = GameState.OWNER_PLAYER
@export var hand_path: NodePath
@export var placements_path: NodePath
@export var field_skills_path: NodePath
@export var duel_manager_path: NodePath

const COLLISION_MASK_CARD = 1
const DEFAULT_CARD_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1
const ENLARGE_CARD_SCALE = 1.1

var hand_reference
var placements_reference
var field_skills_reference
var is_hovering

func _ready() -> void:
	hand_reference = get_node(hand_path)
	placements_reference = get_node(placements_path)
	field_skills_reference = get_node(field_skills_path)


func card_selected(card):
	if not card.card_placement:
		try_place_card(card)


func try_place_card(card) -> Node:
	if GameState.current_mode == GameState.GameMode.PVP and owner_id == GameState.OWNER_PLAYER:
		var duel_manager = get_node(duel_manager_path)
		if not duel_manager.is_my_turn:
			return null

	var slot = _find_open_slot_for(card)
	if not slot:
		return null

	if GameState.current_mode == GameState.GameMode.PVP and owner_id == GameState.OWNER_PLAYER:
		var player_id = multiplayer.get_unique_id()
		_place_card_for_all(player_id, str(card.name), str(slot.name))
		rpc("_place_card_for_all", player_id, str(card.name), str(slot.name))
	else:
		_place_card(card, slot)

	return slot


@rpc("any_peer")
func _place_card_for_all(player_id, card_name, slot_name) -> void:
	if multiplayer.get_unique_id() == player_id:
		_place_card(get_node(card_name), placements_reference.get_node(slot_name))
	else:
		var opp_fm = MultiplayerManager.opp_field.get_node("FieldManager")
		var opp_placements = MultiplayerManager.opp_field.get_node("Placements")
		opp_fm._place_card(opp_fm.get_node(card_name), opp_placements.get_node(slot_name))


@rpc("any_peer")
func relay_skill_result(card_name, data) -> void:
	var opp_field_manager = MultiplayerManager.opp_field.get_node("FieldManager")
	var name_str = String(card_name)
	if not opp_field_manager.has_node(name_str):
		return
	opp_field_manager.get_node(name_str).skill_result_received.emit(data)


func _find_open_slot_for(card) -> Node:
	for slot in placements_reference.get_children():
		if slot.card_placement_owner != owner_id:
			continue
		if slot.card_placed_in:
			continue
		if slot.card_placement_type != card.card_type:
			continue
		if card.card_type == "entity" and slot.card_placement_color != card.card_color:
			continue
		return slot
	return null


func _place_card(card, slot) -> void:
	hand_reference.remove_card_from_hand(card)

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", slot.position, DEFAULT_CARD_SPEED)
	tween.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE), DEFAULT_CARD_SPEED)

	card.z_index = -1
	card.card_placement = slot
	slot.card_placed_in = true

	if owner_id == GameState.OWNER_OPPONENT:
		var animation_name = "card_play_entity_opponent" if card.card_type == "entity" else "card_play_skill_opponent"
		card.get_node("AnimationPlayer").play(animation_name)

	card_placed.emit(card)


func card_raycast():
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	parameters.collision_mask = COLLISION_MASK_CARD
	var result = space_state.intersect_point(parameters)
	if result.size() > 0:
		return get_highest_z_card(result)
	return null


func get_highest_z_card(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card


func connect_card_signals(card):
	card.connect("hovered", on_hovered_card)
	card.connect("hovered_off", on_hovered_off_card)


func on_hovered_card(card):
	if owner_id != GameState.OWNER_PLAYER:
		return
	if card.card_placement:
		return
	if !is_hovering:
		is_hovering = true
		highlight_card(card, true)


func on_hovered_off_card(card):
	if owner_id != GameState.OWNER_PLAYER:
		return
	if !card.defeated:
		if !card.card_placement:
			highlight_card(card, false)
			var new_card_hovered = card_raycast()
			if new_card_hovered:
				highlight_card(new_card_hovered, true)
			else:
				is_hovering = false


func highlight_card(card, hovered):
	if card.card_placement:
		return
	if hovered:
		card.scale = Vector2(ENLARGE_CARD_SCALE, ENLARGE_CARD_SCALE)
		card.z_index = 2
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = 1
