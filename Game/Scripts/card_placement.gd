extends Node2D

@export_enum("player", "opponent") var card_placement_owner: String = GameState.OWNER_PLAYER
@export var card_placement_type: String
@export var card_placement_color: String

const ICON_TEXTURE = {
	"entity": preload("res://Assets/Icons/kenney_board-game-icons/sword.png"),
	"skill": preload("res://Assets/Icons/kenney_board-game-icons/book_open.png")
}

var COLOR_MAP = {
	"red": Color.from_rgba8(255, 0, 0, 255),
	"blue": Color.from_rgba8(0, 0, 255, 255),
	"yellow": Color.from_rgba8(255, 255, 0, 255),
	"green": Color.from_rgba8(0, 255, 0, 255),
	"purple": Color.from_rgba8(128, 56, 149, 255),
}
var card_placed_in = false

func _ready() -> void:
	apply_placement_color()
	apply_placement_texture()


func apply_placement_color():
	$Art/Type.modulate = COLOR_MAP.get(card_placement_color)


func apply_placement_texture():
	if ICON_TEXTURE.has(card_placement_type):
		$Art/Type.texture = ICON_TEXTURE[card_placement_type]
