extends Node

var opp_field: Node = null
var disconnect_menu: Node = null
var game_active := false

func _ready() -> void:
	multiplayer.server_disconnected.connect(_on_disconnected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _on_disconnected() -> void:
	if not game_active:
		return
	_handle_disconnect()


@warning_ignore("unused_parameter")
func _on_peer_disconnected(peer_id) -> void:
	if not game_active:
		return
	_handle_disconnect()


func _handle_disconnect() -> void:
	game_active = false
	AudioController.stop_battle_music()
	if disconnect_menu:
		disconnect_menu.visible = true
	else:
		reset()
		get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func reset():
	opp_field = null
	disconnect_menu = null
	game_active = false
	multiplayer.multiplayer_peer = null
