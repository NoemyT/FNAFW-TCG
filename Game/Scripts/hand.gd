extends Node2D

## Holds and lays out the cards a player is currently holding.
##
## Cards are arranged in a fan, imitating how a person would hold physical
## cards: they spread horizontally, curve along a parabola and tilt following a
## curve set in the editor. The layout is recalculated from scratch whenever a
## card enters or leaves, so the fan always stays centered and evenly spaced.
##
## The same script serves both sides, with is_opp flipping the curve upwards and
## reversing the order new cards are inserted in.

## Vertical anchor of the fan, set per instance since each side sits on a
## different half of the screen.
@export var hand_y_pos = 1000
@export var is_opp: bool
## Drives how much each card is tilted according to its place in the fan.
@export var rot_curve: Curve
## How far the outermost cards sit from the vertical anchor.
@export var max_height_offset = 30.0

const CARD_WIDTH = 130
const BASE_WIDTH = 1920
const DEFAULT_CARD_MOVE_SPEED = 0.1
const DEFAULT_CARD_SCALE = 1

var hand = []

## Adds a card to the hand and reflows the fan. If the card is already held,
## it is simply animated back to its place, which is what returns a card that
## could not be played.
func add_card_to_hand(card, speed):
	if card not in hand:
		# New cards enter from the side the deck sits on, which differs
		# between the two halves of the board.
		if is_opp:
			hand.insert(0, card)
		else:
			hand.append(card)
		update_hand_pos(speed)
	else:
		var index = hand.find(card)
		var rot_from_curve = get_rotation_for_index(index)
		animate_card_to_pos(card, card.hand_position, DEFAULT_CARD_MOVE_SPEED, rot_from_curve)


## Recalculates and animates every card to its place in the fan. Called on any
## change to the hand, since a single card entering or leaving shifts them all.
func update_hand_pos(speed):
	for i in range(hand.size()):
		var new_pos = Vector2(calculate_card_pos(i), calculate_card_y(i))
		var card = hand[i]
		card.hand_position = new_pos
		var rot_from_curve = get_rotation_for_index(i)
		animate_card_to_pos(card, new_pos, speed, rot_from_curve)


## Samples the rotation curve for a card's place in the fan, mapping its index
## to a 0..1 range. A lone card samples the middle of the curve, so it sits
## straight instead of tilted.
func get_rotation_for_index(index):
	if hand.size() <= 1:
		return rot_curve.sample(0.5)
	var t = float(index) / float(hand.size() - 1)
	return rot_curve.sample(t)


## Vertical position of a card in the fan. A parabola over the card's relative
## place pushes the outer cards away from the center, and the direction is
## flipped for the opponent so their fan curves the other way.
func calculate_card_y(index):
	if hand.size() <= 1:
		return hand_y_pos
	var t = float(index) / float(hand.size() - 1)
	var parabola = pow((t - 0.5) * 2.0, 2)
	var direction = -1.0 if is_opp else 1.0
	return hand_y_pos + parabola * max_height_offset * direction


## Horizontal position of a card, spacing them evenly while keeping the whole
## fan centered on screen regardless of how many cards are held.
func calculate_card_pos(index):
	var total_width = (hand.size() - 1) * CARD_WIDTH
	@warning_ignore("integer_division")
	var x_offset = (BASE_WIDTH / 2) + index * CARD_WIDTH - total_width / 2
	return x_offset


## Animates a card to its place, moving, scaling and rotating at once.
##
## Collision is disabled for the duration: without it, clicking a card still in
## flight would start a second tween competing with this one over the same
## position, leaving the card visually stuck.
func animate_card_to_pos(card, pos, speed, rot):
	card.get_node("Area2D/CollisionShape2D").disabled = true

	var tween = get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(card, "position", pos, speed)
	tween.tween_property(card, "scale", Vector2(DEFAULT_CARD_SCALE, DEFAULT_CARD_SCALE), speed)
	tween.tween_property(card, "rotation", rot, speed)
	# chain() waits for the three parallel tweens above to finish before
	# restoring collision. The card is checked again because it may have been
	# played in the meantime, in which case it should stay unclickable in hand.
	tween.chain().tween_callback(func():
		if is_instance_valid(card) and not card.card_placement:
			card.get_node("Area2D/CollisionShape2D").disabled = false
	)


## Removes a card from the hand and reflows the remaining ones.
func remove_card_from_hand(card):
	if card in hand:
		hand.erase(card)
		update_hand_pos(DEFAULT_CARD_MOVE_SPEED)
