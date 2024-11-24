How to play our game:
There are three levels you must beat in this part. The first two represent one of the Seven Deadly Sins. You must defeat your own sin in order to pass the level. In the first level, you must jump on top of the frogs but not run into them. In the second level, you must defeat the monster's wrath by using the arrow keys and the 'x' key to attack. In the last level, after having defeated your own sins, you have the chance to collect the orbs of your soul in order to discover your true self and your conscience. 










extends KinematicBody2D

var speed = 200  # Movement speed

func _process(delta):
	var direction = Vector2(
		Input.get_action_strength("ui_right") - Input.get_action_strength("ui_left"),
		Input.get_action_strength("ui_down") - Input.get_action_strength("ui_up")
	)
	move_and_slide(direction.normalized() * speed)
