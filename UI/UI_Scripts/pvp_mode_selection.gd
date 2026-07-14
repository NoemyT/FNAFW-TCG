extends Control

func hide_menu():
	$".".visible = false


func _on_host_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_menu_music()
	GameState.set_pvp_mode(GameState.PVPType.HOST)


func _on_join_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_menu_music()
	GameState.set_pvp_mode(GameState.PVPType.CLIENT)


func _on_back_pressed() -> void:
	AudioController.play_menu_click()
	hide_menu()
