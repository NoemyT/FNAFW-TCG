extends Control

## Host/join submenu, where the peer-to-peer connection is established.
##
## Uses two separate channels: ENet over PORT carries the match itself, while
## raw UDP broadcasts over DISCOVER_PORT let clients find a host without anyone
## having to type an IP address. The host announces itself periodically, and the
## client reads the sender's address straight out of the packet it receives.

## Port used by ENet for the match connection.
const PORT = 999
## Separate port used only for host discovery, keeping that traffic away from
## the match connection.
const DISCOVER_PORT = 998
## Broadcast address, which reaches every device on the local network at once.
const BROADCAST_ADDRESS = "255.255.255.255"
const BROADCAST_INTERVAL = 0.5

var is_connecting := false
## Which button started the current attempt, "host" or "join". Drives both the
## behaviour in _process and which error label is shown on failure.
var attempted_action := ""
var udp := PacketPeerUDP.new()
var broadcast_timer := 0.0

func hide_menu():
	$".".visible = false


## Drives whichever side of the discovery the player chose: the host announces
## itself on a fixed interval, while the client listens for those announcements.
## Both stop as soon as is_connecting is cleared, so a filled room no longer
## advertises itself.
func _process(delta) -> void:
	if is_connecting and attempted_action == "host":
		broadcast_timer += delta
		if broadcast_timer >= BROADCAST_INTERVAL:
			broadcast_timer = 0.0
			udp.put_packet("DUEL_HOST_AVAILABLE".to_utf8_buffer())

	elif is_connecting and attempted_action == "join":
		while udp.get_available_packet_count() > 0:
			var packet = udp.get_packet()
			if packet.get_string_from_utf8() == "DUEL_HOST_AVAILABLE":
				# The sender's address is what identifies the host, so no IP
				# needs to be entered by hand.
				var host_ip = udp.get_packet_ip()
				_connect_to_host(host_ip)
				return


## Starts hosting a match. Pressing the button again cancels the attempt.
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
	# The second argument caps the room at a single client, so a third player
	# can never join a match in progress.
	var error = peer.create_server(PORT, 1)
	if error != OK:
		# Fails when the port is already taken, which is what prevents two
		# hosts from running on the same machine.
		_show_connection_error()
		return

	multiplayer.multiplayer_peer = peer
	multiplayer.peer_connected.connect(_on_peer_connected, CONNECT_ONE_SHOT)

	udp.set_broadcast_enabled(true)
	udp.set_dest_address(BROADCAST_ADDRESS, DISCOVER_PORT)


## Starts listening for available hosts. Pressing the button again cancels it.
## No ENet peer is created yet, since the address is only known once a
## broadcast arrives.
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


## Connects to a host found through discovery. The UDP peer is closed first,
## since from here on all communication goes through ENet.
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


## Undoes everything a connection attempt set up.
## The signal connections have to be dropped by hand: CONNECT_ONE_SHOT only
## clears them once the signal fires, so a cancelled attempt would leave them
## hanging and fire on the next one.
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


## Each side is notified through a different signal, so both funnel into the
## same handler below.
@warning_ignore("unused_parameter")
func _on_peer_connected(peer_id) -> void:
	_on_connection_established()


func _on_connected_to_server() -> void:
	_on_connection_established()


## Connection confirmed on both ends: discovery is shut down and the match
## scene is loaded.
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


## Shows the error label matching whichever attempt failed.
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
