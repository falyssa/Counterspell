extends CharacterBody2D

# Movement settings
const GRAVITY = 980
const SPEED = 600
const ATTACK_DURATION = 1.0  # Duration of attack animation in seconds

# Direction control
var current_direction = -1  # Start moving left
var gravity_enabled = true

# Screen boundaries
var screen_size
var sprite_half_width = 48  # Adjust based on your sprite size

# State management
enum State { WALKING, ATTACKING }
var current_state = State.WALKING

# Health settings
var max_health = 100
var current_health = max_health

# Node references
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var attack_timer: Timer = $AttackTimer

func _ready():
	# Get the viewport size for screen boundaries
	screen_size = get_viewport_rect().size
	
	# Get the hurtbox node and connect hit detection
	var hurtbox = $Hurtbox
	hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	
	# Setup attack timer
	attack_timer = Timer.new()
	attack_timer.wait_time = ATTACK_DURATION
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_finished)
	add_child(attack_timer)
	
	# Start walking
	_update_animation()

func _physics_process(delta):
	# Apply gravity
	if gravity_enabled and not is_on_floor():
		velocity.y += GRAVITY * delta
	
	match current_state:
		State.WALKING:
			_handle_walking()
		State.ATTACKING:
			_handle_attacking()
	
	# Move based on current velocity
	move_and_slide()
	
	# Check for wall collisions or screen boundaries
	if is_on_wall() or _is_at_screen_edge():
		_handle_wall_collision()

func _is_at_screen_edge() -> bool:
	var next_position = global_position + Vector2(velocity.x * get_physics_process_delta_time(), 0)
	return (next_position.x - sprite_half_width <= 0 and current_direction < 0) or \
		   (next_position.x + sprite_half_width >= screen_size.x and current_direction > 0)

func _handle_walking():
	velocity.x = current_direction * SPEED
	sprite.flip_h = current_direction > 0
	
	# Clamp position to screen boundaries
	global_position.x = clamp(global_position.x, sprite_half_width, screen_size.x - sprite_half_width)
	
func _handle_attacking():
	velocity.x = 0  # Stop moving while attacking

func _handle_wall_collision():
	if current_state == State.WALKING:
		# Change direction and start attack
		current_direction *= -1
		_start_attack()

func _start_attack():
	current_state = State.ATTACKING
	sprite.play("attack")  # Play attack animation
	attack_timer.start()

func _on_attack_finished():
	current_state = State.WALKING
	_update_animation()

func _update_animation():
	if current_state == State.WALKING:
		sprite.play("walk")
	# Attack animation is handled in _start_attack()

func _on_hurtbox_area_entered(area):
	if area.name == "swordhitbox":
		take_damage(10)  # 10 damage per hit

func take_damage(amount):
	current_health -= amount
	print("Boss hit! Health: ", current_health)
	
	# Visual feedback
	modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	modulate = Color.WHITE
	
	# Check if boss is defeated
	if current_health <= 0:
		die()

func die():
	print("Boss defeated!")
	queue_free()  # Removes the boss from the scene

# Called when viewport size changes
func _on_viewport_size_changed():
	screen_size = get_viewport_rect().size
