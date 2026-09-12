extends Node2D

## A single slot on the field where one card can be placed.
##
## Each side of the board has four entity slots, one per color group, plus a
## skill slot. A slot only accepts cards matching its own type and color, which
## is what caps the field at four entities per player.
##
## The exported values below are set per instance in the editor, and the icon
## and color shown on the slot are derived from them at runtime.

@export_enum("player", "opponent") var card_placement_owner: String = GameState.OWNER_PLAYER
## "entity" or "skill".
@export var card_placement_type: String
## Color group this slot accepts. Unused for skill slots.
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

## Whether the slot is currently taken. Checked by FieldManager when looking for
## somewhere to place a card, and cleared when the occupying card is destroyed.
var card_placed_in = false

func _ready() -> void:
	apply_placement_color()
	apply_placement_texture()


## Tints the slot icon with the color group it accepts, so the player can tell
## at a glance which cards fit where.
func apply_placement_color():
	$Art/Type.modulate = COLOR_MAP.get(card_placement_color)


## Swaps the icon according to the slot type: a sword for entities, a book for
## skills.
func apply_placement_texture():
	if ICON_TEXTURE.has(card_placement_type):
		$Art/Type.texture = ICON_TEXTURE[card_placement_type]
