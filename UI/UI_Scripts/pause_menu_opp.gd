extends Control

@onready var countdown_label: Label = $Panel/Timer
@onready var menu_button: Button = $Panel/MenuButton
@onready var exit_button: Button = $Panel/ExitButton

const HOSTAGE_TIMEOUT: float = 20.0
var time_left: float = HOSTAGE_TIMEOUT

func _ready() -> void:
	hide() 
	visibility_changed.connect(_on_visibility_changed)


func _process(delta: float) -> void:
	if not visible:
		return
	time_left -= delta
	if time_left <= 0.0:
		time_left = 0.0
		update_label()
		enable_buttons()
		set_process(false)
	else:
		update_label()


func _on_visibility_changed():
	if visible:
		start_countdown()
	else:
		stop_countdown()


func start_countdown():
	time_left = HOSTAGE_TIMEOUT
	menu_button.disabled = true
	exit_button.disabled = true
	set_process(true)
	update_label()


func stop_countdown():
	set_process(false)


func enable_buttons():
	menu_button.visible = true
	menu_button.disabled = false
	exit_button.visible = true
	exit_button.disabled = false


func update_label():
	countdown_label.text = str(ceil(time_left))


func leave_match():
	get_tree().paused = false
	hide()


func _on_menu_button_pressed() -> void:
	leave_match()
	get_tree().change_scene_to_file("res://UI/TitleScreen.tscn")


func _on_exit_button_pressed() -> void:
	leave_match()
	get_tree().quit()
