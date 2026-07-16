extends Control

const PORT = 999
const SERVER_ADDRESS = "192.168.*.*"

var is_connecting := false
var attempted_action := ""


func hide_menu():
	$".".visible = false


func _on_host_pressed() -> void:
	if is_connecting:
		_cancel_connection()
		return

	AudioController.play_menu_click()
	_clear_error_labels()
	GameState.set_pvp_mode(GameState.PVPType.HOST)
	is_connecting = true
	attempted_action = "host"
	$Panel/IndicatorHost.start()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(PORT)
	if error != OK:
		_show_connection_error()
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected, CONNECT_ONE_SHOT)


func _on_join_pressed() -> void:
	if is_connecting:
		_cancel_connection()
		return

	AudioController.play_menu_click()
	_clear_error_labels()
	GameState.set_pvp_mode(GameState.PVPType.CLIENT)
	is_connecting = true
	attempted_action = "join"
	$Panel/IndicatorJoin.start()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(SERVER_ADDRESS, PORT)
	if error != OK:
		_show_connection_error()
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.connected_to_server.connect(_on_connected_to_server, CONNECT_ONE_SHOT)
	multiplayer.connection_failed.connect(_on_connection_failed, CONNECT_ONE_SHOT)


func _cancel_connection() -> void:
	AudioController.play_menu_click()
	_teardown_connection_attempt()


func _teardown_connection_attempt() -> void:
	is_connecting = false
	$Panel/IndicatorHost.stop()
	$Panel/IndicatorJoin.stop()
	if multiplayer.peer_connected.is_connected(_on_peer_connected):
		multiplayer.peer_connected.disconnect(_on_peer_connected)
	if multiplayer.connected_to_server.is_connected(_on_connected_to_server):
		multiplayer.connected_to_server.disconnect(_on_connected_to_server)
	if multiplayer.connection_failed.is_connected(_on_connection_failed):
		multiplayer.connection_failed.disconnect(_on_connection_failed)
	multiplayer.multiplayer_peer = null
	GameState.reset()


func _on_peer_connected(_id: int) -> void:
	_on_connection_established()


func _on_connected_to_server() -> void:
	_on_connection_established()


func _on_connection_established() -> void:
	is_connecting = false
	$Panel/IndicatorHost.stop()
	$Panel/IndicatorJoin.stop()
	AudioController.stop_menu_music()
	AudioController.play_battle_music()
	get_tree().change_scene_to_file("res://Game/DuelPVP.tscn")


func _on_connection_failed() -> void:
	_teardown_connection_attempt()
	_show_connection_error()


func _show_connection_error() -> void:
	is_connecting = false
	$Panel/IndicatorHost.stop()
	$Panel/IndicatorJoin.stop()
	if attempted_action == "host":
		$Panel/HostError.visible = true
	elif attempted_action == "join":
		$Panel/JoinError.visible = true


func _clear_error_labels() -> void:
	$Panel/HostError.visible = false
	$Panel/JoinError.visible = false


func _on_back_pressed() -> void:
	AudioController.play_menu_click()
	if is_connecting:
		_teardown_connection_attempt()
	_clear_error_labels()
	hide_menu()
