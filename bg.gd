extends ParallaxBackground

var scrolling_speed = 80

func _process(delta):
	scroll_offset.x -= scrolling_speed * delta
	


# Called when the node enters the scene tree for the first time.



# Called every frame. 'delta' is the elapsed time since the previous frame.
