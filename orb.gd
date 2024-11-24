extends Area2D
@onready var anim = get_node("AnimationPlayer")
@onready var game_manager = %GameManager
func _on_body_entered(body):
	game_manager.add_point()
	
	anim.play("grab")
	queue_free()																		
