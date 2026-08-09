extends Control

signal flip_finished

@onready var coin_sprite: AnimatedSprite2D = $Panel/AnimatedSprite2D
@onready var result_label: Label = $Panel/Label

const SPIN_DURATION = 2.0
const RESULT_DISPLAY_TIME = 1.5

var flip_animation := "Flip"
var heads_animation := "Heads"
var tails_animation := "Tails"

func _ready() -> void:
	visible = false


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
