extends Node2D

## Routes mouse clicks to whatever was clicked on the player's side of the board.
##
## Acts purely as a dispatcher: it raycasts at the cursor, works out whether a
## card or the deck was hit, and hands the action over to the right script. The
## collision mask is what distinguishes them, so every clickable area has to be
## set to the matching layer in the editor.
##
## Only one instance is needed per match, always pointing at the player's side:
## the AI never generates clicks, and the opponent's side is not interactive.

@export var player_side_path: NodePath

const COLLISION_MASK_CARD = 1
const COLLISION_MASK_DECK = 4

var field_manager_reference
var deck_reference
## Blocks all input while an action is resolving or when it is not the player's
## turn. Toggled by the duel managers.
var inputs_disabled = false

func _ready() -> void:
	var player_side = get_node(player_side_path)
	field_manager_reference = player_side.get_node("FieldManager")
	deck_reference = player_side.get_node("Deckpile")


func _input(event) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			raycast_at_cursor()


## Detects what is under the cursor and dispatches accordingly: clicking a card
## attempts to play it, while clicking the deck draws.
func raycast_at_cursor():
	if inputs_disabled:
		return
	var space_state = get_world_2d().direct_space_state
	var parameters = PhysicsPointQueryParameters2D.new()
	parameters.position = get_global_mouse_position()
	parameters.collide_with_areas = true
	var result = space_state.intersect_point(parameters)
	if result.is_empty():
		return

	# The cursor can be over several colliders at once, so they are sorted out
	# by collision mask before deciding what was actually clicked.
	var cards = []
	var deck_hit = false
	for hit in result:
		match hit.collider.collision_mask:
			COLLISION_MASK_CARD:
				cards.append(hit)
			COLLISION_MASK_DECK:
				deck_hit = true

	if not cards.is_empty():
		# Overlapping cards are resolved by depth, so the click lands on the
		# one the player can actually see on top.
		var top_card = field_manager_reference.get_highest_z_card(cards)
		field_manager_reference.card_selected(top_card)
	elif deck_hit:
		if GameState.current_mode == GameState.GameMode.AI:
			deck_reference.draw_card_local()
		elif GameState.current_mode == GameState.GameMode.PVP:
			deck_reference.deck_clicked_networked()
