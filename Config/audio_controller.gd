extends Node

## Autoload (Singleton) that centralizes all music and sound effect playback.
##
## Each sound is an AudioStreamPlayer child of this node, so playback survives
## scene changes. Other scripts never touch the players directly, calling the
## named methods below instead.

var mute = false

## Mutes or unmutes every sound in the game at once, through the Master bus.
func set_audio(value):
	mute = value

	var master_bus_index = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(master_bus_index, mute)


# --- Music ---

## Menu theme and battle theme, played depending on which scene the player is
## currently in, and stopped when the player moves to another one. 
func play_menu_music():
	$Menu.play()


func stop_menu_music():
	$Menu.stop()


func play_battle_music():
	$Battle.play()


func stop_battle_music():
	$Battle.stop()


## Victory, defeat and draw each layer two tracks: a short stinger and
## the theme that follows it.
func play_victory_music():
	$Cheer.play()
	$Victory.play()


func play_defeat_music():
	$Death.play()
	$Defeat.play()


func play_draw():
	$Noise.play()
	$Draw.play()


## Stops every result track at once. Since only one outcome plays per match,
## this avoids having to check which one was triggered.
func stop_result_music():
	$Cheer.stop()
	$Victory.stop()
	$Death.stop()
	$Defeat.stop()
	$Noise.stop()
	$Draw.stop()


# --- Sound effects ---

## Plays during the trigger of the skill 4th Wall.
func play_4th_wall():
	$"4thWall".play()


## Plays during the trigger of the skill Mega Bite.
func play_mega_bite():
	$MegaBite.play()


## Plays only when the Slasher skill succeeds its 10% roll.
func play_stab():
	$Stab.play()


## Plays when two cards of the same color clash.
func play_clash_attack():
	$Clash.play()


## Plays when a card attacks the opponent's life points directly.
func play_direct_attack():
	$Direct.play()


## Plays whenever the player clicks on a menu button.
func play_menu_click():
	$Clicking.play()


## Plays during the coin flip that decides turn order.
func play_coin():
	$Coin.play()
