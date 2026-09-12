extends Control

## Main menu shown when the game starts.
##
## Entry point for both game modes: AI mode jumps straight into a match, while
## PvP opens a submenu where the player chooses between hosting and joining.

const SOUND_ON = preload("res://Assets/Icons/kenney_game-icons/audioOn.png")
const SOUND_OFF = preload("res://Assets/Icons/kenney_game-icons/audioOff.png")

func _ready() -> void:
	AudioController.play_menu_music()
	$AnimationPlayer.play("Boot")
	# The mute state is global, so the button has to reflect whatever it was
	# set to in a previous screen.
	$Panel/SoundButton.button_pressed = AudioController.mute
	$Panel/SoundButton.icon = SOUND_OFF if AudioController.mute else SOUND_ON


## Starts a match against the AI. No extra setup is needed, so the game mode is
## registered and the duel scene is loaded right away.
func _on_ai_button_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_menu_music()
	AudioController.play_battle_music()
	GameState.set_ai_mode(GameState.AIType.ATTACK)
	get_tree().change_scene_to_file("res://Game/Duel.tscn")


## Opens the host/join submenu. PvP needs a connection before the match can
## start, so the scene change happens there instead.
func _on_pvp_button_pressed() -> void:
	AudioController.play_menu_click()
	$PvpModeSelection.visible = true


func _on_exit_button_pressed() -> void:
	get_tree().quit()


func _on_sound_button_toggled(toggled_on) -> void:
	AudioController.set_audio(toggled_on)
	$Panel/SoundButton.icon = SOUND_OFF if toggled_on else SOUND_ON


func _on_tutorial_button_pressed() -> void:
	AudioController.play_menu_click()
	$Tutorial.visible = true


## Opens the credits and attributions screen.
func _on_info_button_pressed() -> void:
	AudioController.play_menu_click()
	$InfoScreen.visible = true
