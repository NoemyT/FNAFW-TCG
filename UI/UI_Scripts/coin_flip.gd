extends Control

## Coin flip animation that announces who plays first.
##
## Purely presentational: the duel managers decide the turn order and pass the
## result in, then wait for this animation to finish before starting the match.
## Each player sees the side matching their own outcome, so both see heads or
## tails according to whether they are the one starting.

signal flip_finished

@onready var coin_sprite: AnimatedSprite2D = $Panel/AnimatedSprite2D
@onready var result_label: Label = $Panel/Label

const SPIN_DURATION = 1.5
const RESULT_DISPLAY_TIME = 1

var flip_animation := "Flip"
var heads_animation := "Heads"
var tails_animation := "Tails"

func _ready() -> void:
	visible = false


## Plays the full sequence: spin, land on the result, hold it, then hide.
## Awaited by the duel managers, which only unlock the match once it returns.
func flip(local_player_starts):
	AudioController.play_coin()
	visible = true
	result_label.text = ""
	coin_sprite.play(flip_animation)

	await get_tree().create_timer(SPIN_DURATION).timeout

	coin_sprite.play(heads_animation if local_player_starts else tails_animation)
	result_label.text = "YOUR TURN" if local_player_starts else "OPPONENT TURN"

	await get_tree().create_timer(RESULT_DISPLAY_TIME).timeout

	visible = false
	flip_finished.emit()
