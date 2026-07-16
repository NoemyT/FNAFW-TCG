extends Label

const DOT_INTERVAL = 0.4

var dot_count := 0
var timer: Timer

func _ready() -> void:
	visible = false
	timer = Timer.new()
	timer.wait_time = DOT_INTERVAL
	timer.timeout.connect(_on_tick)
	add_child(timer)


func start() -> void:
	dot_count = 0
	text = ""
	visible = true
	timer.start()


func stop() -> void:
	visible = false
	timer.stop()


func _on_tick() -> void:
	dot_count = (dot_count % 3) + 1
	text = ".".repeat(dot_count)
