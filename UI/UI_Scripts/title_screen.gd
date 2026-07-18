extends Control

const SOUND_ON = preload("res://Assets/Icons/kenney_game-icons/audioOn.png")
const SOUND_OFF = preload("res://Assets/Icons/kenney_game-icons/audioOff.png")

func _ready() -> void:
	AudioController.play_menu_music()
	$AnimationPlayer.play("Boot")
	$Panel/SoundButton.button_pressed = AudioController.mute
	$Panel/SoundButton.icon = SOUND_OFF if AudioController.mute else SOUND_ON


func hide_menu():
	$".".mouse_filter = MOUSE_FILTER_IGNORE
	$Art.visible = false
	$Panel.visible = false
	$Panel/AiButton.disabled = true
	$Panel/PvpButton.disabled = true
	$Panel/ExitButton.disabled = true


func _on_ai_button_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_menu_music()
	AudioController.play_battle_music()
	GameState.set_ai_mode(GameState.AIType.ATTACK)
	get_tree().change_scene_to_file("res://Game/Duel.tscn")


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


func _on_info_button_pressed() -> void:
	AudioController.play_menu_click()
	$InfoScreen.visible = true
