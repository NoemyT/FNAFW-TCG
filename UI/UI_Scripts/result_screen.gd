extends Control

## End of match screen, showing victory, defeat or draw.
##
## The duel managers decide the outcome and play the matching animation on this
## node, so this script only handles what happens after the player acknowledges
## the result.

func hide_menu():
	$".".visible = false


## Returns to the title screen, clearing the state left behind by the match.
## Both managers are reset here so a finished match never leaks into the next
## one, and the peer connection is dropped along with MultiplayerManager.
func _on_menu_button_pressed() -> void:
	AudioController.play_menu_click()
	AudioController.stop_result_music()
	MultiplayerManager.reset()
	GameState.reset()
	hide_menu()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_pressed() -> void:
	get_tree().quit()
