extends Node2D

## Prepares a PvP match once both players are connected.
##
## Registers the match references with MultiplayerManager, sets the starting
## health on both sides and deals the opening hands. Present only in the PvP
## duel scene, where it removes itself if the game is running in AI mode.

@export var player_side_path: NodePath
@export var opp_side_path: NodePath
@export var disconnect_menu_path: NodePath

const STARTING_HEALTH = 20

var player_side: Node
var opp_side: Node


func _ready() -> void:
	# Guard for the case where this scene is opened outside of PvP, since none
	# of the setup below would apply.
	if GameState.current_mode != GameState.GameMode.PVP:
		queue_free()
		return

	player_side = get_node(player_side_path)
	opp_side = get_node(opp_side_path)

	# MultiplayerManager is an autoload and cannot reach into the match scene,
	# so the references it needs are handed to it here.
	MultiplayerManager.opp_field = opp_side
	MultiplayerManager.disconnect_menu = get_node(disconnect_menu_path)
	MultiplayerManager.game_active = true

	player_side.get_node("Hp/PlayerHp").text = str(STARTING_HEALTH)
	opp_side.get_node("Hp/OppHp").text = str(STARTING_HEALTH)

	# Both sides deal their own opening hand and announce each card to the
	# other. The host waits for the deal to finish before continuing, since the
	# coin flip that follows is started on its side.
	if GameState.current_pvp_type == GameState.PVPType.HOST:
		await player_side.get_node("Deckpile").draw_first_hand_networked()
	elif GameState.current_pvp_type == GameState.PVPType.CLIENT:
		player_side.get_node("Deckpile").draw_first_hand_networked()
