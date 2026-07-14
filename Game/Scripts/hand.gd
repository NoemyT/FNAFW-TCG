extends Node2D

const CARD_WIDTH = 190
const BASE_WIDTH = 1920
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1.2

@export var hand_y_pos = 1060
@export var is_opp: bool

var hand = []

func add_card_to_hand(card, speed):
	if card not in hand:
		hand.insert(0, card)
		update_hand_pos(speed)
	else:
		animate_card_to_pos(card, card.hand_pos, DEFAULT_CARD_MOVE_SPEED)

func update_hand_pos(speed):
	for i in range(hand.size()):
		var new_pos = Vector2(calculate_card_pos(i), hand_y_pos)
		var card = hand[i]
		card.hand_pos = new_pos
		animate_card_to_pos(card, new_pos, speed)


func calculate_card_pos(index):
	var total_width = (hand.size() - 1) * CARD_WIDTH
	var x_offset = (BASE_WIDTH / 2) + index * CARD_WIDTH - total_width / 2
	return x_offset


func animate_card_to_pos(card, pos, speed):
	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", pos, speed)
	tween.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE), speed)


func remove_card_from_hand(card):
	if card in hand:
		hand.erase(card)
		update_hand_pos(DEFAULT_CARD_MOVE_SPEED)
