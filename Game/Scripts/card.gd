extends Node2D

signal hovered
signal hovered_off

var card_owner
var hand_position
var card_placement
var card_type
var card_color
var health
var attack
var defeated = false
var skill
var skill_script


func _ready() -> void:
	get_parent().connect_card_signals(self)


func _on_area_2d_mouse_entered() -> void:
	emit_signal("hovered", self)


func _on_area_2d_mouse_exited() -> void:
	emit_signal("hovered_off", self)
