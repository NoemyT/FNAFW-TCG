extends Node2D

@export var player_side_path: NodePath
@export var opp_side_path: NodePath
@export var disconnect_menu_path: NodePath

const STARTING_HEALTH = 20

var player_side: Node
var opp_side: Node


func _ready() -> void:
	if GameState.current_mode != GameState.GameMode.PVP:
		queue_free()
		return

	player_side = get_node(player_side_path)
	opp_side = get_node(opp_side_path)

	MultiplayerManager.opp_field = opp_side
	MultiplayerManager.disconnect_menu = get_node(disconnect_menu_path)
	MultiplayerManager.game_active = true

	player_side.get_node("Hp/PlayerHp").text = str(STARTING_HEALTH)
	opp_side.get_node("Hp/OppHp").text = str(STARTING_HEALTH)

	if GameState.current_pvp_type == GameState.PVPType.HOST:
		await player_side.get_node("Deckpile").draw_first_hand_networked(true)
	elif GameState.current_pvp_type == GameState.PVPType.CLIENT:
		player_side.get_node("Deckpile").draw_first_hand_networked(false)
