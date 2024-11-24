extends CharacterBody2D

# Movement constants - Tuned for fast-paced Metroidvania feel
const SPEED = 1000.0  # Much faster base speed (up from 360)
const ACCELERATION = 7000.0  # Extremely snappy ground acceleration (up from 3200)
const DECELERATION = 7000.0  # Matching quick stop
const AIR_ACCELERATION = 5000.0  # Much stronger air control (up from 2000)
const AIR_DECELERATION = 2000.0  # Increased air friction for better control
const JUMP_VELOCITY = -1100.0  # High jump
const JUMP_CUT_HEIGHT = 0.45  # Jump height control
const GRAVITY_MULTIPLIER = 1.8  # Balanced gravity for high jumps
const FAST_FALL_GRAVITY = 3  # Fast falling
const MAX_FALL_SPEED = 1000.0  # Max fall speed
const COYOTE_TIME = 0.12  # Allows jumping slightly after leaving platform
const JUMP_BUFFER = 0.1  # Makes jump input more forgiving
const DOUBLE_JUMP_VELOCITY = -1200.0  # Double jump strength
const TURN_MULTIPLIER = 1.5  # Faster acceleration when turning around (new!)

# Dash constants
const DASH_SPEED_GROUND = 2000.0  # Ground dash speed
const DASH_DURATION_GROUND = 0.05  # Ground dash duration
const DASH_SPEED_AIR = 1500.0  # Air dash speed
const DASH_DURATION_AIR = 0.05  # Air dash duration
const DASH_COOLDOWN = 0.5  # 0.5 seconds before dash can be used again
const DOUBLE_TAP_TIME = 0.3  # Max time between taps for double tap

# Jump timing variables
var coyote_timer: float = 0.0
var jump_buffer_timer: float = 0.0
var was_on_floor: bool = false
var has_double_jump: bool = true
var facing_direction: float = 1.0  # Track facing direction for turn boost

# Dash variables
var last_left_tap_time: float = -DOUBLE_TAP_TIME
var last_right_tap_time: float = -DOUBLE_TAP_TIME
var is_dashing: bool = false
var dash_timer: float = 0.0
var dash_direction: float = 0.0
var dash_cooldown_timer: float = 0.0
var dash_speed: float = 0.0  # Current dash speed

# Get the gravity from the project settings
var default_gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

func initiate_dash(direction: float) -> void:
	is_dashing = true
	dash_direction = direction
	dash_cooldown_timer = DASH_COOLDOWN

	# Set vertical velocity to zero to negate gravity during dash
	velocity.y = 0.0

	if is_on_floor():
		dash_speed = DASH_SPEED_GROUND
		dash_timer = DASH_DURATION_GROUND
	else:
		dash_speed = DASH_SPEED_AIR
		dash_timer = DASH_DURATION_AIR

func _physics_process(delta: float) -> void:
	var is_falling: bool = velocity.y > 0

	# Update dash cooldown timer
	if dash_cooldown_timer > 0:
		dash_cooldown_timer -= delta

	var current_time = Time.get_ticks_msec() / 1000.0

	# Double-tap detection for left
	if Input.is_action_just_pressed("ui_left"):
		if current_time - last_left_tap_time < DOUBLE_TAP_TIME and dash_cooldown_timer <= 0:
			initiate_dash(-1.0)
		last_left_tap_time = current_time

	# Double-tap detection for right
	if Input.is_action_just_pressed("ui_right"):
		if current_time - last_right_tap_time < DOUBLE_TAP_TIME and dash_cooldown_timer <= 0:
			initiate_dash(1.0)
		last_right_tap_time = current_time

	# Handle coyote time
	if was_on_floor and not is_on_floor():
		coyote_timer = COYOTE_TIME
	elif is_on_floor():
		coyote_timer = COYOTE_TIME
		has_double_jump = true  # Reset double jump when touching ground
	else:
		coyote_timer -= delta

	# Handle jump buffer
	if Input.is_action_just_pressed("ui_accept"):
		jump_buffer_timer = JUMP_BUFFER
	else:
		jump_buffer_timer -= delta

	# Apply gravity with multiplier for snappier falls, unless dashing
	if not is_on_floor() and not is_dashing:
		# Apply stronger gravity when falling
		var gravity = default_gravity * (FAST_FALL_GRAVITY if is_falling else GRAVITY_MULTIPLIER)
		velocity.y += gravity * delta
		# Clamp fall speed
		velocity.y = min(velocity.y, MAX_FALL_SPEED)

	# Handle dashing
	if is_dashing:
		# During dash, override horizontal movement
		velocity.x = dash_direction * dash_speed

		# Maintain zero vertical velocity during dash
		velocity.y = 0.0

		# Reduce dash timer
		dash_timer -= delta
		if dash_timer <= 0:
			is_dashing = false
	else:
		# Handle primary jump with buffer and coyote time
		if jump_buffer_timer > 0 and coyote_timer > 0:
			velocity.y = JUMP_VELOCITY
			jump_buffer_timer = 0
			coyote_timer = 0
		# Handle double jump
		elif Input.is_action_just_pressed("ui_accept") and has_double_jump and not is_on_floor():
			velocity.y = DOUBLE_JUMP_VELOCITY
			has_double_jump = false
		# Cut jump height if button is released early
		elif Input.is_action_just_released("ui_accept") and velocity.y < 0:
			velocity.y *= JUMP_CUT_HEIGHT

		# Get the input direction
		var direction := Input.get_axis("ui_left", "ui_right")

		# Handle horizontal movement with enhanced acceleration
		if direction:
			# Check if turning around for turn boost
			var is_turning = sign(direction) != sign(velocity.x) and abs(velocity.x) > SPEED * 0.5
			var turn_boost = TURN_MULTIPLIER if is_turning else 1.0

			# Use different acceleration rates for ground and air
			var current_acceleration = (ACCELERATION if is_on_floor() else AIR_ACCELERATION) * turn_boost
			velocity.x = move_toward(velocity.x, direction * SPEED, current_acceleration * delta)

			# Update facing direction
			facing_direction = direction
		else:
			# Different deceleration rates for ground and air
			var current_deceleration = DECELERATION if is_on_floor() else AIR_DECELERATION
			velocity.x = move_toward(velocity.x, 0, current_deceleration * delta)

	# Store floor state for next frame
	was_on_floor = is_on_floor()

	move_and_slide()
