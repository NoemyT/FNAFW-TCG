extends Control

func _on_return_pressed() -> void:
	AudioController.play_menu_click()
	$".".visible = false
