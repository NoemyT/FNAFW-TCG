extends Control

const SOUND_ON = preload("res://Assets/Icons/kenney_game-icons/audioOn.png")
const SOUND_OFF = preload("res://Assets/Icons/kenney_game-icons/audioOff.png")

func _ready() -> void:
	PlayerInputs.pause_menu = self 
	hide()
	$Panel/SoundButton.button_pressed = AudioController.mute
	$Panel/SoundButton.icon = SOUND_OFF if AudioController.mute else SOUND_ON


func _on_resume_pressed() -> void:
	AudioController.play_menu_click()
	PlayerInputs.trigger_pause_menu()


func _on_menu_pressed() -> void:
	AudioController.play_menu_click()
	PlayerInputs.trigger_pause_menu()
	AudioController.stop_battle_music()
	GameState.reset()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_pressed() -> void:
	PlayerInputs.trigger_pause_menu()
	get_tree().quit()


func _on_audio_toggled(toggled_on: bool) -> void:
	AudioController.set_audio(toggled_on)
	$Panel/SoundButton.icon = SOUND_OFF if toggled_on else SOUND_ON
