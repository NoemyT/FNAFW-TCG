extends Control

## Pause menu shown to the player who paused the match.
##
## Used in both game modes. The pausing itself is handled by PlayerInputs, which
## also mirrors the pause to the opponent in PvP; this script only registers
## itself there and reacts to the buttons.

const SOUND_ON = preload("res://Assets/Icons/kenney_game-icons/audioOn.png")
const SOUND_OFF = preload("res://Assets/Icons/kenney_game-icons/audioOff.png")

func _ready() -> void:
	# PlayerInputs is an autoload and cannot reach into the match scene on its
	# own, so the menus register themselves as they enter the tree.
	PlayerInputs.pause_menu = self 
	PlayerInputs.tutorial = $Tutorial
	hide()
	$Panel/SoundButton.button_pressed = AudioController.mute
	$Panel/SoundButton.icon = SOUND_OFF if AudioController.mute else SOUND_ON


func _on_resume_pressed() -> void:
	AudioController.play_menu_click()
	PlayerInputs.trigger_pause_menu()


## Leaves the match and returns to the title screen. The pause is lifted first,
## otherwise the tree would stay frozen after the scene change.
func _on_menu_pressed() -> void:
	AudioController.play_menu_click()
	PlayerInputs.trigger_pause_menu()
	AudioController.stop_battle_music()
	MultiplayerManager.reset()
	GameState.reset()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


## Quits the game. MultiplayerManager is reset so the opponent is notified of
## the disconnection instead of being left waiting.
func _on_exit_pressed() -> void:
	PlayerInputs.trigger_pause_menu()
	MultiplayerManager.reset()
	get_tree().quit()


func _on_audio_toggled(toggled_on) -> void:
	AudioController.set_audio(toggled_on)
	$Panel/SoundButton.icon = SOUND_OFF if toggled_on else SOUND_ON


## Opens the tutorial during a match. Pausing is blocked while it is open, so
## the player cannot unpause and leave the tutorial floating over a live match.
func _on_tutorial_button_pressed() -> void:
	PlayerInputs.block_pause = true
	AudioController.play_menu_click()
	$Tutorial.visible = true
