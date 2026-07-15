extends Node

const CARD_SCENE = preload("res://Game/Card.tscn")

func create_card(card_name, owner_id) -> Node2D:
	var card_data = CardDatabase.CARDS[card_name]
	var new_card = CARD_SCENE.instantiate()
	new_card.card_owner = owner_id

	var sprite = new_card.get_node("Art/Image")
	sprite.texture = load("res://Assets/Characters/%s.png" % card_name)
	sprite.region_enabled = true
	sprite.region_rect = card_data["char_region"]
	sprite.scale = card_data["scale"]

	var bg_color = new_card.get_node("Art/Color")
	bg_color.texture = load("res://Assets/Cards/pixelCardAssest_V01.png")
	bg_color.region_enabled = true
	bg_color.region_rect = card_data["bg_region"]

	new_card.card_type = card_data["type"]
	new_card.card_color = card_data["color"]

	if new_card.card_type == "entity":
		new_card.get_node("Skill").visible = false
		new_card.attack = card_data["attack"]
		new_card.get_node("AttackL").text = str(new_card.attack)
		new_card.health = card_data["health"]
		new_card.get_node("HpL").text = str(new_card.health)
	else:
		new_card.get_node("Art/Attack").visible = false
		new_card.get_node("AttackL").visible = false
		new_card.get_node("Art/Hp").visible = false
		new_card.get_node("HpL").visible = false
		new_card.skill = card_data["skill"]
		new_card.get_node("Skill").text = new_card.skill
		var skill_path = card_data["skill_script"]
		if skill_path:
			new_card.skill_script = load(skill_path).new()

	return new_card
