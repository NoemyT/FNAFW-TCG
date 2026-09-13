extends Node

## Autoload (Singleton) handling keyboard shortcuts that work anywhere in the game.
##
## Covers pausing, force quitting and fullscreen toggling. In PvP it also keeps
## both players' pause states in sync, so that one player pausing freezes the
## match on both machines instead of leaving the other stuck in a live game.

## How long the pause key must be held down to force quit the game.
const HOLD_DURATION = 1.5

var esc_hold_time = 0.0

## References registered by the menus themselves when they enter the tree.
## They stay null outside of a match, which is what the guards below check for.
var pause_menu: Control = null
var pause_menu_opp: Control = null
var tutorial: Control = null
var tutorial_opp: Control = null

var paused = false
var opponent_paused = false

## Blocks pausing during sequences that must not be interrupted, such as the
## coin flip and the end of a match.
var block_pause = false

func _ready() -> void:
	# PROCESS_MODE_ALWAYS keeps this node running while the tree is paused,
	# which is what allows the player to unpause.
	process_mode = Node.PROCESS_MODE_ALWAYS
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)


## Watches the pause key: a short press toggles the pause menu, while holding
## it down for HOLD_DURATION quits the game.
func _process(delta) -> void:
	if not pause_menu:
		return
	# The disconnect menu takes priority, otherwise the player could stack the
	# pause menu on top of it and appear to be softlocked.
	if MultiplayerManager.disconnect_menu and MultiplayerManager.disconnect_menu.visible:
		return

	if block_pause:
		esc_hold_time = 0.0
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


## Toggles fullscreen. Handled in _input so it works even while paused.
func _input(event) -> void:
	if event.is_action_pressed("Fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


## Shows or hides the pause menu and freezes the scene tree accordingly.
## In PvP the new state is broadcast so the opponent freezes as well.
func trigger_pause_menu():
	if block_pause:
		return
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


## Closes any tutorial screen left open. Called when the pause that allowed it
## to be opened ends, so no menu is left behind once the match resumes.
func force_close_tutorials():
	block_pause = false
	if tutorial and tutorial.visible:
		tutorial.visible = false
	if tutorial_opp and tutorial_opp.visible:
		tutorial_opp.visible = false


## Received when the other player pauses or unpauses. Freezes this instance and
## shows the opponent pause menu, which explains why the match stopped.
@rpc("any_peer")
func notify_opponent_pause(is_paused):
	opponent_paused = is_paused
	if not pause_menu_opp:
		return
	if is_paused:
		get_tree().paused = true
		pause_menu_opp.show()
	else:
		force_close_tutorials()
		pause_menu_opp.hide()
		get_tree().paused = false


## Clears any pause state when the connection drops, otherwise a player could
## be left frozen by an opponent that is no longer there to unpause.
@warning_ignore("unused_parameter")
func _on_peer_disconnected(peer_id) -> void:
	opponent_paused = false
	force_close_tutorials()
	if pause_menu_opp:
		get_tree().paused = false
		pause_menu_opp.hide()
	if paused:
		if pause_menu:
			pause_menu.hide()
		get_tree().paused = false
		paused = false
