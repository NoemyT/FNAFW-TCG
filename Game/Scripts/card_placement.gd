extends Node2D

const COLOR_MAP = {
	"red": Color8(255, 0, 0, 255),
	"blue": Color8(0, 0, 255, 255),
	"yellow": Color8(255, 255, 0, 255),
	"green": Color8(0, 255, 0, 255),
}

const ICON_TEXTURE = {
	"entity": preload("res://Assets/Icons/kenney_board-game-icons/sword.png"),
	"skill": preload("res://Assets/Icons/kenney_board-game-icons/book_open.png")
}

@export var card_placement_type: String
@export var card_placement_color: String
@export var card_placement_owner: String

var card_placed_in = false

func _ready() -> void:
	apply_placement_color()
	apply_placement_texture()


func apply_placement_color() -> void:
	$Node2D/Type.modulate = COLOR_MAP.get(card_placement_color, Color8(255, 176, 251, 255))


func apply_placement_texture() -> void:
	if ICON_TEXTURE.has(card_placement_type):
		$Node2D/Type.texture = ICON_TEXTURE[card_placement_type]
	else:
		push_warning("No texture found for type: " + card_placement_type)
