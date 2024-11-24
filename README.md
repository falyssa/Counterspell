extends KinematicBody2D

var speed = 200  # Movement speed

func _process(delta):
	var direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	move_and_slide(direction.normalized() * speed)
