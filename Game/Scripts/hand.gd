extends Node2D

@export var hand_y_pos = 1000
@export var is_opp: bool
@export var rot_curve: Curve
@export var max_height_offset = 30.0

const CARD_WIDTH = 130
const BASE_WIDTH = 1920
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1

var hand = []

func add_card_to_hand(card, speed):
	if card not in hand:
		if is_opp:
			hand.insert(0, card)
		else:
			hand.append(card)
		update_hand_pos(speed)
	else:
		var index = hand.find(card)
		var rot_from_curve = get_rotation_for_index(index)
		animate_card_to_pos(card, card.hand_position, DEFAULT_CARD_MOVE_SPEED, rot_from_curve)


func update_hand_pos(speed):
	for i in range(hand.size()):
		var new_pos = Vector2(calculate_card_pos(i), calculate_card_y(i))
		var card = hand[i]
		card.hand_position = new_pos
		var rot_from_curve = get_rotation_for_index(i)
		animate_card_to_pos(card, new_pos, speed, rot_from_curve)


func get_rotation_for_index(index):
	if hand.size() <= 1:
		return rot_curve.sample(0.5)
	var t = float(index) / float(hand.size() - 1)
	return rot_curve.sample(t)


func calculate_card_y(index):
	if hand.size() <= 1:
		return hand_y_pos
	var t = float(index) / float(hand.size() - 1)
	var parabola = pow((t - 0.5) * 2.0, 2)
	var direction = -1.0 if is_opp else 1.0
	return hand_y_pos + parabola * max_height_offset * direction


func calculate_card_pos(index):
	var total_width = (hand.size() - 1) * CARD_WIDTH
	@warning_ignore("integer_division")
	var x_offset = (BASE_WIDTH / 2) + index * CARD_WIDTH - total_width / 2
	return x_offset


func animate_card_to_pos(card, pos, speed, rot):
	card.get_node("Area2D/CollisionShape2D").disabled = true

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", pos, speed)
	tween.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE), speed)
	tween.tween_property(card, "rotation", rot, speed)
	tween.chain().tween_callback(func():
		if is_instance_valid(card) and not card.card_placement:
			card.get_node("Area2D/CollisionShape2D").disabled = false
	)


func remove_card_from_hand(card):
	if card in hand:
		hand.erase(card)
		update_hand_pos(DEFAULT_CARD_MOVE_SPEED)
