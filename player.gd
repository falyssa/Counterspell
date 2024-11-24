extends CharacterBody2D

# Movement constants - Tuned for fast-paced Metroidvania feel
const SPEED = 1000.0
const ACCELERATION = 7000.0
const DECELERATION = 7000.0
const AIR_ACCELERATION = 5000.0
const AIR_DECELERATION = 2000.0
const JUMP_VELOCITY = -1100.0
const JUMP_CUT_HEIGHT = 0.45
const GRAVITY_MULTIPLIER = 1.8
const FAST_FALL_GRAVITY = 3
const MAX_FALL_SPEED = 1000.0
const COYOTE_TIME = 0.12
const JUMP_BUFFER = 0.1
const DOUBLE_JUMP_VELOCITY = -1200.0
const TURN_MULTIPLIER = 1.5

# Position recording variables
var position_record: Array = []
var record_timer: float = 0.0
const RECORD_INTERVAL: float = 1.0

# Dash constants
const DASH_SPEED_GROUND = 2000.0
const DASH_DURATION_GROUND = 0.05
const DASH_SPEED_AIR = 1500.0
const DASH_DURATION_AIR = 0.05
const DASH_COOLDOWN = 0.5
const DOUBLE_TAP_TIME = 0.3
const DASH_ANIMATION_DURATION = 0.2

# Attack constants
const ATTACK_DURATION = 0.6

# Animation states
enum AnimationState {
	IDLE,
	RUN,
	JUMP,
	FALL,
	DASH,
	ATTACK
}

# Jump timing variables
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var has_double_jump: bool = true
var facing_direction: float = 1.0

# Dash variables
var last_left_tap_time: float = -DOUBLE_TAP_TIME
var last_right_tap_time: float = -DOUBLE_TAP_TIME
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_speed: float = 0.0
var dash_animation_timer: float = 0.0

# Attack variables
var is_attacking: bool = false
var attack_timer: float = 0.0

# Health and damage variables
var max_health: int = 100
var health: int = max_health
var is_invincible: bool = false
var invincibility_duration: float = 2.0  # Increased duration for testing
var invincibility_timer: float = 0.0
var damage_flash_duration: float = 0.1
var damage_flash_timer: float = 0.0

# Animation variables
@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var sword_hitbox: CollisionShape2D = $swordhitbox/CollisionShape2D
@onready var hurtbox: Area2D = $Hurtbox
var current_animation_state: AnimationState = AnimationState.IDLE

# Get the gravity from the project settings
var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	if not sprite:
		push_error("AnimatedSprite2D node not found! Make sure it's a child node named 'AnimatedSprite2D'")
		return
	
	if sword_hitbox:
		sword_hitbox.disabled = true
	else:
		push_error("Sword hitbox not found! Make sure the path to CollisionShape2D is correct")
	
	# Setup hurtbox connections - ensure we only connect once
	if hurtbox:
		# Disconnect any existing connections to prevent duplicates
		if hurtbox.area_entered.is_connected(_on_hurtbox_area_entered):
			hurtbox.area_entered.disconnect(_on_hurtbox_area_entered)
		if hurtbox.body_entered.is_connected(_on_Hurtbox_body_entered):
			hurtbox.body_entered.disconnect(_on_Hurtbox_body_entered)
		
		# Connect our area detection
		hurtbox.area_entered.connect(_on_hurtbox_area_entered)
	else:
		push_error("Hurtbox not found! Make sure it's a child node named 'Hurtbox'")
	
	update_animation(AnimationState.IDLE)

func record_position() -> void:
	# Create a dictionary with position and timestamp
	var position_data = {
		"position": position,
		"timestamp": Time.get_unix_time_from_system()
	}
	position_record.append(position_data)
	print("Position recorded: ", position_data)  # Debug print

func update_animation(new_state: AnimationState) -> void:
	if not sprite or current_animation_state == new_state:
		return
		
	current_animation_state = new_state
	
	match new_state:
		AnimationState.IDLE:
			sprite.play("idle")
		AnimationState.RUN:
			sprite.play("run")
		AnimationState.JUMP:
			sprite.play("jump")
		AnimationState.FALL:
			sprite.play("fall")
		AnimationState.DASH:
			sprite.play("dash")
		AnimationState.ATTACK:
			sprite.play("attack")
	
	# Update sword hitbox position based on facing direction
	if sword_hitbox:
		var hitbox_position = sword_hitbox.position
		hitbox_position.x = abs(hitbox_position.x) * facing_direction
		sword_hitbox.position = hitbox_position

func update_facing_direction() -> void:
	if Input.is_action_pressed("ui_right"):
		facing_direction = 1.0
		sprite.flip_h = false
	elif Input.is_action_pressed("ui_left"):
		facing_direction = -1.0
		sprite.flip_h = true

func determine_animation_state() -> AnimationState:
	if is_attacking:
		return AnimationState.ATTACK
	elif is_dashing:
		return AnimationState.DASH
	elif not is_on_floor():
		return AnimationState.FALL if velocity.y > 0 else AnimationState.JUMP
	elif abs(velocity.x) > 10.0:
		return AnimationState.RUN
	else:
		return AnimationState.IDLE

func initiate_dash(direction: float) -> void:
	is_dashing = true
	dash_direction = direction
	dash_cooldown_timer = DASH_COOLDOWN
	dash_animation_timer = DASH_ANIMATION_DURATION
	velocity.y = 0.0
	
	if is_on_floor():
		dash_speed = DASH_SPEED_GROUND
		dash_timer = DASH_DURATION_GROUND
	else:
		dash_speed = DASH_SPEED_AIR
		dash_timer = DASH_DURATION_AIR

func initiate_attack() -> void:
	if not is_attacking:
		is_attacking = true
		attack_timer = ATTACK_DURATION
		if sword_hitbox:
			sword_hitbox.disabled = false

func take_damage(amount: int) -> void:
	if is_invincible:
		return
		
	health -= amount
	print("Player took damage! Health: ", health)
	
	# Activate invincibility
	is_invincible = true
	invincibility_timer = invincibility_duration
	damage_flash_timer = damage_flash_duration
	
	# Visual feedback
	show_damage_effect()
	
	# Add knockback
	var knockback_direction = -facing_direction
	velocity.x = knockback_direction * 500  # Horizontal knockback
	velocity.y = -400  # Vertical knockback
	
	if health <= 0:
		die()

func show_damage_effect() -> void:
	sprite.modulate = Color(1, 0, 0)  # Set to red
	damage_flash_timer = damage_flash_duration

func handle_damage_effects(delta: float) -> void:
	# Handle invincibility
	if is_invincible:
		invincibility_timer -= delta
		if invincibility_timer <= 0:
			is_invincible = false
			sprite.modulate = Color(1, 1, 1)  # Reset to normal
			sprite.self_modulate.a = 1.0  # Ensure full opacity
		else:
			# Blinking effect during invincibility
			sprite.self_modulate.a = 0.5 if fmod(invincibility_timer, 0.2) < 0.1 else 1.0
	
	# Handle damage flash
	if damage_flash_timer > 0:
		damage_flash_timer -= delta
		if damage_flash_timer <= 0:
			if not is_invincible:  # Only reset color if not invincible
				sprite.modulate = Color(1, 1, 1)

func _on_hurtbox_area_entered(area: Area2D) -> void:
	if area.name == "Hitbox" and not is_invincible:  # This matches the boss's hitbox name
		take_damage(20)  # Take same damage as defined in boss script

func _on_Hurtbox_body_entered(body: Node) -> void:
	# This function is kept for backward compatibility
	# but we're using area_entered instead
	pass

func die() -> void:
	print("Player has died!")
	# Disable player input
	set_physics_process(false)
	# Play death animation if available
	if sprite.has_animation("death"):
		sprite.play("death")
	# Wait a moment before restarting
	await get_tree().create_timer(1.0).timeout
	# Reload the current scene
	get_tree().reload_current_scene()

func _physics_process(delta: float) -> void:
	# Handle damage effects (invincibility and flashing)
	handle_damage_effects(delta)
	
	# Update position recording timer
	record_timer += delta
	if record_timer >= RECORD_INTERVAL:
		record_position()
		record_timer = 0.0
	
	# Update facing direction immediately based on input
	update_facing_direction()
	
	var is_falling: bool = velocity.y > 0
	
	if attack_timer > 0:
		attack_timer -= delta
		if attack_timer <= 0:
			is_attacking = false
			if sword_hitbox:
				sword_hitbox.disabled = true

	if dash_animation_timer > 0:
		dash_animation_timer -= delta

	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	var current_time = Time.get_ticks_msec() / 1000.0

	if Input.is_action_just_pressed("attack"):
		initiate_attack()

	if Input.is_action_just_pressed("ui_left"):
		if current_time - last_left_tap_time < DOUBLE_TAP_TIME and dash_cooldown_timer <= 0:
			initiate_dash(-1.0)
		last_left_tap_time = current_time

	if Input.is_action_just_pressed("ui_right"):
		if current_time - last_right_tap_time < DOUBLE_TAP_TIME and dash_cooldown_timer <= 0:
			initiate_dash(1.0)
		last_right_tap_time = current_time

	if was_on_floor and not is_on_floor():
		coyote_timer = COYOTE_TIME
	elif is_on_floor():
		coyote_timer = COYOTE_TIME
		has_double_jump = true
	else:
		coyote_timer -= delta

	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer -= delta

	if not is_on_floor() and not is_dashing:
		var gravity = default_gravity * (FAST_FALL_GRAVITY if is_falling else GRAVITY_MULTIPLIER)
		velocity.y += gravity * delta
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	if is_dashing:
		velocity.x = dash_direction * dash_speed
		velocity.y = 0.0
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	else:
		if jump_buffer_timer > 0 and coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0
			coyote_timer = 0
		elif Input.is_action_just_pressed("ui_accept") and has_double_jump and not is_on_floor():
			velocity.y = DOUBLE_JUMP_VELOCITY
			has_double_jump = false
		elif Input.is_action_just_released("ui_accept") and velocity.y < 0:
			velocity.y *= JUMP_CUT_HEIGHT

		var direction := Input.get_axis("ui_left", "ui_right")

		if direction != 0:
			var is_turning = sign(direction) != sign(velocity.x) and abs(velocity.x) > SPEED * 0.5
			var turn_boost = TURN_MULTIPLIER if is_turning else 1.0
			var current_acceleration = (ACCELERATION if is_on_floor() else AIR_ACCELERATION) * turn_boost
			velocity.x = move_toward(velocity.x, direction * SPEED, current_acceleration * delta)
		else:
			var current_deceleration = DECELERATION if is_on_floor() else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0, current_deceleration * delta)

	was_on_floor = is_on_floor()
	
	update_animation(determine_animation_state())

	move_and_slide()
