extends Node2D

@export var hand_y_pos = 1000
@export var is_opp: bool

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
		animate_card_to_pos(card, card.hand_position, DEFAULT_CARD_MOVE_SPEED)


func update_hand_pos(speed):
	for i in range(hand.size()):
		var new_pos = Vector2(calculate_card_pos(i), hand_y_pos)
		var card = hand[i]
		card.hand_position = new_pos
		animate_card_to_pos(card, new_pos, speed)


func calculate_card_pos(index):
	var total_width = (hand.size() - 1) * CARD_WIDTH
	@warning_ignore("integer_division")
	var x_offset = (BASE_WIDTH / 2) + index * CARD_WIDTH - total_width / 2
	return x_offset


func animate_card_to_pos(card, pos, speed):
	card.get_node("Area2D/CollisionShape2D").disabled = true

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", pos, speed)
	tween.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE), speed)
	tween.chain().tween_callback(func():
		if is_instance_valid(card) and not card.card_placement:
			card.get_node("Area2D/CollisionShape2D").disabled = false
	)


func remove_card_from_hand(card):
	if card in hand:
		hand.erase(card)
		update_hand_pos(DEFAULT_CARD_MOVE_SPEED)
