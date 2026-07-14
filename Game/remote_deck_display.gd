extends Node2D

@export var hand_path: NodePath
@export var cards_manager_path: NodePath = ^"../CardsManager"

const CARD_DRAW_SPEED = 0.4

var deck_size := CardDatabase.get_total_deck_size()

func receive_card(card_name):
	deck_size -= 1

	var new_card = CardFactory.create_card(card_name, GameState.OWNER_OPPONENT)
	new_card.position = self.position
	get_node(cards_manager_path).add_child(new_card)
	new_card.name = "Card"
	get_node(hand_path).add_card_to_hand(new_card, CARD_DRAW_SPEED)
	new_card.get_node("AnimationPlayer").play("card_flip")

	if deck_size <= 0:
		visible = false
