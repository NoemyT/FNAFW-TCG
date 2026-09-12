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
	if result.size() > 0:
		var result_collision_mask = result[0].collider.collision_mask
		if result_collision_mask == COLLISION_MASK_CARD:
			var card_found = result[0].collider.get_parent()
			if card_found:
				field_manager_reference.card_selected(card_found)
		elif result_collision_mask == COLLISION_MASK_DECK:
			# Drawing differs between modes: in PvP the draw has to be
			# broadcast so the opponent sees it happen.
			if GameState.current_mode == GameState.GameMode.AI:
				deck_reference.draw_card_local()
			elif GameState.current_mode == GameState.GameMode.PVP:
				deck_reference.deck_clicked_networked()
