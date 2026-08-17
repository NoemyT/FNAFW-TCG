extends Control

func _on_close_pressed() -> void:
	AudioController.play_menu_click()
	PlayerInputs.force_close_tutorials()
	$".".visible = false


func _on_right_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))


func _on_tab_container_tab_clicked(_tab) -> void:
	AudioController.play_menu_click()
