extends Control

func hide_menu():
	$".".visible = false


func _on_attack_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_menu_music()
	GameState.set_ai_mode(GameState.AIType.ATTACK)


func _on_survivability_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_menu_music()
	GameState.set_ai_mode(GameState.AIType.SURVIVAL)


func _on_back_pressed() -> void:
	AudioController.play_menu_click()
	hide_menu()
