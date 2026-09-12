extends Control

## Pause menu shown to the player who did NOT pause, in PvP matches.
##
## Since only the player who paused can unpause, this menu exists to explain the
## interruption and to keep the other player from being held hostage: after a
## countdown, they are allowed to leave the match on their own.

@onready var countdown_label = $Panel/Timer
@onready var menu_button = $Panel/MenuButton
@onready var exit_button = $Panel/ExitButton

## How long the player has to wait before being allowed to leave the match.
const HOSTAGE_TIMEOUT = 20.0
const SOUND_ON = preload("res://Assets/Icons/kenney_game-icons/audioOn.png")
const SOUND_OFF = preload("res://Assets/Icons/kenney_game-icons/audioOff.png")

var time_left = HOSTAGE_TIMEOUT

func _ready() -> void:
	hide()
	# Registers itself with PlayerInputs, which shows this menu when the RPC
	# announcing the opponent's pause arrives. 
	PlayerInputs.pause_menu_opp = self
	PlayerInputs.tutorial_opp = $Tutorial
	visibility_changed.connect(_on_visibility_changed)
	$Panel/SoundButton.button_pressed = AudioController.mute
	$Panel/SoundButton.icon = SOUND_OFF if AudioController.mute else SOUND_ON


## Counts down while the menu is visible, releasing the buttons once it ends.
func _process(delta) -> void:
	if not visible:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		update_label()
		enable_buttons()
		set_process(false)
	else:
		update_label()


## Ties the countdown to the menu's visibility, so it restarts on every pause
## instead of carrying over the remaining time from a previous one.
func _on_visibility_changed() -> void:
	if visible:
		start_countdown()
	else:
		stop_countdown()


func start_countdown():
	time_left = HOSTAGE_TIMEOUT
	menu_button.disabled = true
	exit_button.disabled = true
	set_process(true)
	update_label()


func stop_countdown():
	set_process(false)


## Releases the leave buttons once the countdown reaches zero.
func enable_buttons():
	menu_button.visible = true
	menu_button.disabled = false
	exit_button.visible = true
	exit_button.disabled = false


func update_label():
	countdown_label.text = str(ceil(time_left))


## Unfreezes the tree before leaving, otherwise the next scene would load
## already paused.
func leave_match():
	get_tree().paused = false
	hide()


func _on_menu_button_pressed() -> void:
	AudioController.play_menu_click()
	leave_match()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_button_pressed() -> void:
	leave_match()
	get_tree().quit()


func _on_sound_button_toggled(toggled_on) -> void:
	AudioController.set_audio(toggled_on)
	$Panel/SoundButton.icon = SOUND_OFF if toggled_on else SOUND_ON


func _on_tutorial_button_pressed() -> void:
	AudioController.play_menu_click()
	$Tutorial.visible = true
