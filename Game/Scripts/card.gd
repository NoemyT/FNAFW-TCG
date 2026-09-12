extends Node2D

## A single card instance, in hand, on the field or in the graveyard.
##
## Acts as a template: the scene defines the layout and this script holds the
## attributes, which are filled in by CardFactory from the CardDatabase entry.
## That way every card in the game is the same scene with different values.

signal hovered
signal hovered_off
## Carries randomized skill results across the network in PvP, so both players
## see the same target and damage values. Emitted by FieldManager when the
## relaying RPC arrives.
@warning_ignore("unused_signal")
signal skill_result_received(data)

## Which side the card belongs to, from the local player's perspective.
## One of GameState.OWNER_PLAYER or GameState.OWNER_OPPONENT.
var card_owner
var hand_position
## The CardPlacement slot this card occupies, or null while it is still in hand.
var card_placement
var card_name
## "entity" or "skill".
var card_type
## Color group, which decides both where the card can be placed and which
## enemy cards it can clash with.
var card_color
var health
var attack
## Set when the card is destroyed. Checked during combat so a card that died
## mid turn does not keep attacking.
var defeated = false
## Skill description shown on the card face.
var skill
## Instance of the skill's script, only set for skill cards.
var skill_script


func _ready() -> void:
	# Cards are always created as children of a FieldManager, which handles the
	# hover highlighting and needs to listen to the signals below.
	get_parent().connect_card_signals(self)


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
