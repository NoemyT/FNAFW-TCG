extends Control

func hide_menu():
	$".".visible = false


func _on_menu_button_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_result_music()
	hide_menu()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
