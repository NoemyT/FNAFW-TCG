extends Node

const HOLD_DURATION = 1.5

var esc_hold_time = 0.0
var pause_menu: Control = null
var pause_menu_opp: Control = null
var paused = false
var opponent_paused = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


func _process(delta: float) -> void:
	if not pause_menu:
		return

	if Input.is_action_pressed("QuitOrPause"):
		esc_hold_time += delta
		if esc_hold_time >= HOLD_DURATION:
			get_tree().quit()
	else:
		if Input.is_action_just_released("QuitOrPause"):
			if esc_hold_time < HOLD_DURATION:
				trigger_pause_menu()
		esc_hold_time = 0.0


func _input(event) -> void:
	if event.is_action_pressed("Fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func trigger_pause_menu():
	if opponent_paused and not paused:
		return

	if paused:
		pause_menu.hide()
		get_tree().paused = false
	else:
		pause_menu.show()
		get_tree().paused = true
	paused = !paused

	if multiplayer.multiplayer_peer:
		notify_opponent_pause.rpc(paused)


@rpc("any_peer")
func notify_opponent_pause(is_paused):
	opponent_paused = is_paused
	if not pause_menu_opp:
		return
	if is_paused:
		get_tree().paused = true
		pause_menu_opp.show()
	else:
		pause_menu_opp.hide()
		get_tree().paused = false


@rpc("any_peer")
func notify_opponent_quit():
	opponent_paused = false
	if pause_menu_opp:
		get_tree().paused = false
		pause_menu_opp.hide()
	if paused:
		if pause_menu:
			pause_menu.hide()
		get_tree().paused = false
		paused = false


func _on_peer_disconnected(peer_id) -> void:
	opponent_paused = false
	if pause_menu_opp:
		get_tree().paused = false
		pause_menu_opp.hide()
	if paused:
		if pause_menu:
			pause_menu.hide()
		get_tree().paused = false
		paused = false
