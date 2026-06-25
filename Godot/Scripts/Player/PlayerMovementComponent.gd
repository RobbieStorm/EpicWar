extends CharacterBody2D

const SPEED: float = 300.0
const JUMP_VELOCITY: float = 400.0

func _physics_process(delta: float) -> void:
	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle jump.
	if Input.is_action_just_pressed("Space") and is_on_floor():
		velocity += Vector2(0.0, -JUMP_VELOCITY)


	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("Left", "Right")
	
	velocity.x = move_toward(velocity.x, direction * SPEED, delta*2000)
	
	print(velocity)
	
	move_and_slide()

