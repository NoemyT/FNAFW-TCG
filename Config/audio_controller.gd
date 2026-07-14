extends Node

var mute = false

func set_audio(value):
	mute = value

	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, mute)

func play_menu_music():
	$Menu.play()


func stop_menu_music():
	$Menu.stop()


func play_battle_music():
	$Battle.play()


func stop_battle_music():
	$Battle.stop()


func play_victory_music():
	$Cheer.play()
	$Victory.play()


func stop_victory_music():
	$Victory.stop()


func play_defeat_music():
	$Death.play()
	$Defeat.play()


func stop_defeat_music():
	$Defeat.stop()


func play_4th_wall():
	$"4thWall".play()


func play_mega_bite():
	$MegaBite.play()


func play_clash_attack():
	$Clash.play()


func play_direct_attack():
	$Direct.play()


func play_menu_click():
	$Clicking.play()
