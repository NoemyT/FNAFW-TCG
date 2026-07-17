extends Control

const PORT = 999
const DISCOVER_PORT = 998
const BROADCAST_ADDRESS = "255.255.255.255"
const BROADCAST_INTERVAL = 0.5

var is_connecting := false
var attempted_action := ""
var udp := PacketPeerUDP.new()
var broadcast_timer := 0.0

func hide_menu():
	$".".visible = false


func _process(delta: float) -> void:
	if is_connecting and attempted_action == "host":
		broadcast_timer += delta
		if broadcast_timer >= BROADCAST_INTERVAL:
			broadcast_timer = 0.0
			udp.put_packet("DUEL_HOST_AVAILABLE".to_utf8_buffer())

	elif is_connecting and attempted_action == "join":
		while udp.get_available_packet_count() > 0:
			var packet = udp.get_packet()
			if packet.get_string_from_utf8() == "DUEL_HOST_AVAILABLE":
				var host_ip = udp.get_packet_ip()
				_connect_to_host(host_ip)
				return


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
	var error = peer.create_server(PORT, 1)
	if error != OK:
		_show_connection_error()
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected, CONNECT_ONE_SHOT)

	udp.set_broadcast_enabled(true)
	udp.set_dest_address(BROADCAST_ADDRESS, DISCOVER_PORT)


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

	var error = udp.bind(DISCOVER_PORT)
	if error != OK:
		_show_connection_error()


func _connect_to_host(ip) -> void:
	udp.close()

	var peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(ip, PORT)
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
	attempted_action = ""
	$Panel/IndicatorHost.stop()
	$Panel/IndicatorJoin.stop()
	udp.close()
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
	attempted_action = ""
	$Panel/IndicatorHost.stop()
	$Panel/IndicatorJoin.stop()
	udp.close()
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
	attempted_action = ""


func _clear_error_labels() -> void:
	$Panel/HostError.visible = false
	$Panel/JoinError.visible = false


func _on_back_pressed() -> void:
	AudioController.play_menu_click()
	if is_connecting:
		_teardown_connection_attempt()
	_clear_error_labels()
	hide_menu()
