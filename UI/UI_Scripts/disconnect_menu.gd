extends Control

## Shown in PvP when the connection drops mid match, either because the network
## failed or because the opponent left.
##
## Displayed by MultiplayerManager, which detects the disconnection. The match
## cannot continue at this point, so the only options are leaving or quitting.

func hide_disc_menu():
	$".".visible = false
	$Panel/MenuButton.disabled = true
	$Panel/ExitButton.disabled = true


## Returns to the title screen, clearing the state left behind by the match.
## Both managers are reset here so a finished match never leaks into the next
## one, and the peer connection is dropped along with MultiplayerManager.
func _on_menu_button_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_battle_music()
	MultiplayerManager.reset()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")
	hide_disc_menu()


func _on_exit_button_pressed() -> void:
	MultiplayerManager.reset()
	get_tree().quit()
