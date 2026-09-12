extends Control

## Tutorial screen explaining how to play, split into a quick guide and more
## detailed tabs.
##
## Reachable from the title screen and from both pause menus, which is why
## closing it goes through PlayerInputs: the tutorial blocks pausing while open,
## and that block has to be lifted from a single place.

func _on_close_pressed() -> void:
	AudioController.play_menu_click()
	PlayerInputs.force_close_tutorials()
	$".".visible = false


## Opens external links in the system browser.
func _on_right_meta_clicked(meta) -> void:
	OS.shell_open(str(meta))


func _on_tab_container_tab_clicked(_tab) -> void:
	AudioController.play_menu_click()
