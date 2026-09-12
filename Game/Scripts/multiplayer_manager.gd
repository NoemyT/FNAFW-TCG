extends Node

## Autoload (Singleton) tracking the state of a PvP match and reacting to
## connection loss.
##
## Holds the references that the match scene registers on startup, so that
## scripts which cannot reach into the scene tree, such as the other autoloads,
## still have a way to find the opponent's side and the disconnect menu.

## The opponent's half of the board, used across the codebase to mirror actions
## onto the other player's side.
var opp_field: Node = null
var disconnect_menu: Node = null
## Whether a match is currently running. Guards the disconnect handling below,
## so a connection closing outside of a match is ignored.
var game_active := false

func _ready() -> void:
	# Each side learns about the disconnection through a different signal:
	# the client through server_disconnected, the host through peer_disconnected.
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


## Ends the match when the connection drops, showing the disconnect menu so the
## player knows why it stopped. Falls back to returning to the title screen if
## the menu was never registered.
func _handle_disconnect() -> void:
	game_active = false
	AudioController.stop_battle_music()
	if disconnect_menu:
		disconnect_menu.visible = true
	else:
		reset()
		get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


## Clears the match state and drops the connection. Called when leaving a match,
## so a finished one never leaks into the next.
func reset():
	opp_field = null
	disconnect_menu = null
	game_active = false
	multiplayer.multiplayer_peer = null
