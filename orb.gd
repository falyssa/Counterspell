extends Area2D
@onready var anim = get_node("AnimationPlayer")

func _on_body_entered(body):
	print ("A part of your soul...")
	anim.play("grab")
	queue_free()																		
