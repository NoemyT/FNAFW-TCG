extends Node2D

## Manages the cards belonging to one side of the board.
##
## Cards are created as children of this node, which makes it the natural place
## to handle placing them on the field, highlighting them on hover, and, in PvP,
## relaying skill results between the two instances.
##
## Placing a card is semi automatic: instead of dragging, the player clicks a
## card and this script finds the matching slot on its own, based on the card's
## type and color.
##
## One instance per side, with owner_id deciding whether it acts on the player's
## input or only mirrors what the other side does.

## Emitted once a card lands on the field. Listened to by the duel managers,
## which track the cards in play and trigger skill effects.
signal card_placed(card)

@export_enum("player", "opponent") var owner_id: String = GameState.OWNER_PLAYER
@export var hand_path: NodePath
@export var placements_path: NodePath
@export var field_skills_path: NodePath
@export var duel_manager_path: NodePath

const COLLISION_MASK_CARD = 1
const DEFAULT_CARD_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1
const DEFAULT_CARD_ROTATION = 0
const ENLARGE_CARD_SCALE = 1.1
## Depth of a card resting on the field.
const ON_FIELD_Z_INDEX = 1
## Depth of a card in flight, above every resting card so it is never drawn
## behind one while moving.
const CARD_MOVING_Z_INDEX = 3
const CARD_HOVERED_IN_HAND_INDEX = 3
const CARD_STILL_IN_HAND_INDEX = 2

var hand_reference
var placements_reference
var field_skills_reference
var is_hovering

func _ready() -> void:
	hand_reference = get_node(hand_path)
	placements_reference = get_node(placements_path)
	field_skills_reference = get_node(field_skills_path)


## Entry point for a click on a card, called by InputManager. Cards already on
## the field are ignored, since they act only through the attack button.
func card_selected(card):
	if not card.card_placement:
		try_place_card(card)


## Attempts to place a card on the field, returning the slot it landed on or
## null if it could not be played.
##
## It is an attempt because two things can refuse it: playing outside of one's
## turn, or having no free slot matching the card. The turn check lives here
## rather than relying on input being disabled, so that the refusal holds no
## matter which path the call came from.
func try_place_card(card):
	if owner_id == GameState.OWNER_PLAYER:
		var duel_manager = get_node(duel_manager_path)
		if GameState.current_mode == GameState.GameMode.PVP:
			if not duel_manager.is_my_turn:
				return null
		elif GameState.current_mode == GameState.GameMode.AI:
			if duel_manager.is_opp_turn:
				return null

	var slot = _find_open_slot_for(card)
	if not slot:
		return null

	# In PvP the placement has to reach the other instance, so it goes through
	# the RPC below. Everywhere else it is applied directly.
	if GameState.current_mode == GameState.GameMode.PVP and owner_id == GameState.OWNER_PLAYER:
		var player_id = multiplayer.get_unique_id()
		_place_card_for_all(player_id, str(card.name), str(slot.name))
		rpc("_place_card_for_all", player_id, str(card.name), str(slot.name))
	else:
		_place_card(card, slot)

	return slot


## Applies a placement on both machines. Whoever played the card places it on
## their own side, while the other instance mirrors it onto the opponent's side.
##
## Cards and slots are identified by name rather than by reference, since the
## same card sits in a different place in each instance's scene tree.
@rpc("any_peer")
func _place_card_for_all(player_id, card_name, slot_name) -> void:
	if multiplayer.get_unique_id() == player_id:
		_place_card(get_node(card_name), placements_reference.get_node(slot_name))
	else:
		var opp_fm = MultiplayerManager.opp_field.get_node("FieldManager")
		var opp_placements = MultiplayerManager.opp_field.get_node("Placements")
		opp_fm._place_card(opp_fm.get_node(card_name), opp_placements.get_node(slot_name))


## Delivers a randomized skill result to the matching card on the other machine.
##
## Some skills roll their target, damage or success chance, and without this the
## two instances would each roll their own and disagree on what happened. The
## roll is made by whoever played the skill and handed over through here.
##
## The RPC is dispatched from this node rather than from the card itself because
## RPCs are routed by node path, and a card's path differs between instances.
## The card name is passed instead, and resolved against the opponent's side.
@rpc("any_peer")
func relay_skill_result(card_name, data) -> void:
	var opp_field_manager = MultiplayerManager.opp_field.get_node("FieldManager")
	var name_str = String(card_name)
	if not opp_field_manager.has_node(name_str):
		return
	opp_field_manager.get_node(name_str).skill_result_received.emit(data)


## Finds a free slot the card can legally occupy: one on this side, still empty,
## of a matching type, and for entities also of a matching color. Returns null
## when none is available, which is what caps the field at four entities.
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


## Moves a card from the hand onto a slot and marks that slot as taken.
func _place_card(card, slot) -> void:
	hand_reference.remove_card_from_hand(card)

	card.z_index = CARD_MOVING_Z_INDEX

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", slot.position, DEFAULT_CARD_SPEED)
	tween.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE), DEFAULT_CARD_SPEED)
	tween.tween_property(card, "rotation", DEFAULT_CARD_ROTATION, DEFAULT_CARD_SPEED)
	# The resting depth is only applied once the card has landed. Setting it any
	# earlier would let the card be drawn behind the ones already on the field
	# while it is still moving.
	tween.chain().tween_callback(func(): card.z_index = ON_FIELD_Z_INDEX)

	card.card_placement = slot
	slot.card_placed_in = true

	# Opponent cards are face down while in hand, so playing one is also when
	# its contents are revealed.
	if owner_id == GameState.OWNER_OPPONENT:
		var animation_name = "card_play_entity_opponent" if card.card_type == "entity" else "card_play_skill_opponent"
		card.get_node("AnimationPlayer").play(animation_name)

	card_placed.emit(card)


## Finds the card under the cursor, used to carry the highlight over when the
## mouse moves from one overlapping card to another.
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


## Picks the topmost card out of a set of overlapping ones, so the hover lands
## on the card actually visible to the player.
func get_highest_z_card(cards):
	var highest_z_card = cards[0].collider.get_parent()
	var highest_z_index = highest_z_card.z_index
	for i in range(1, cards.size()):
		var current_card = cards[i].collider.get_parent()
		if current_card.z_index > highest_z_index:
			highest_z_card = current_card
			highest_z_index = current_card.z_index
	return highest_z_card


## Hooks a newly created card's hover signals. Called by the card itself as it
## enters the tree.
func connect_card_signals(card):
	card.connect("hovered", on_hovered_card)
	card.connect("hovered_off", on_hovered_off_card)


## Highlights a card under the cursor. The owner check keeps the opponent's side
## from reacting to hover, since those cards are not the player's to inspect.
func on_hovered_card(card):
	if owner_id != GameState.OWNER_PLAYER:
		return
	if card.card_placement:
		return
	if !is_hovering:
		is_hovering = true
		highlight_card(card, true)


## Clears the highlight and immediately checks whether another card lies under
## the cursor, which keeps the highlight from flickering while sweeping across
## the fan of cards in hand.
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


## Enlarges a card and lifts it above its neighbours while hovered. Only applies
## to cards in hand, since cards on the field do not respond to hover.
func highlight_card(card, hovered):
	if card.card_placement:
		return
	if hovered:
		card.scale = Vector2(ENLARGE_CARD_SCALE, ENLARGE_CARD_SCALE)
		card.z_index = CARD_HOVERED_IN_HAND_INDEX
	else:
		card.scale = Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE)
		card.z_index = CARD_STILL_IN_HAND_INDEX
