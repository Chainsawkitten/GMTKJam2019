extends Node2D

# Array of positions to follow.
var positions = []

# Which position in the position list is the current one.
var current_position = 0

# The state the bullet is currently in.
enum {NEUTRAL, FORESIGHT, FIRED, STOPPED, RETURN}
var state = NEUTRAL

# The speed of the bullet in pixels / second.
const speed = 2400.0

# The orb.
var orb_node = null

# The line node the shows the foresight.
var foresight_line_node = null

# The line node that shows the orb's trail.
var trail_line_node = null

# Information about trails.
var trails = []

# Information about a trail.
class TrailNode:
	# How many points this frame contains.
	var num_points

	# How long (in seconds) this frame was.
	var time

# How long a trail should stay on the screen (in seconds).
const trail_time = 0.1

# How long we've been in foresight.
var foresight_timer = 0.0

# How long foresight lasts.
# Should decrease as the fight gets more difficult
var foresight_time = 2.0

# Called when the node enters the scene tree for the first time.
func _ready():
	orb_node = get_node("Orb")
	trail_line_node = get_node("TrailLine")
	foresight_line_node = get_node("ForesightLine")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	clear_old_lines()
	
	# Before being fired. Leave some time to show the foresight.
	if state == FORESIGHT:
		foresight_line_node.visible = true
		foresight_timer += delta / foresight_time
		
		if foresight_timer <= 0.5:
			foresight_line_node.default_color.a = foresight_timer * 2.0
		else:
			foresight_line_node.default_color.a = (1.0 - foresight_timer) * 2.0
		
		if foresight_timer > 1.0:
			state = FIRED
			foresight_timer = 0
			foresight_line_node.visible = false
	
	if state == FIRED and positions.size() > 0:
		travel(delta)
	else:
		# Append empty frame so trail will fade out even after orb has stopped.
		var frame = TrailNode.new()
		frame.num_points = 0
		frame.time = delta
		trails.append(frame)

# Travel along the determined path.
#  delta - time since last frame in seconds
func travel(delta):
	# Determine how long to travel this frame.
	var distance_to_travel = speed * delta

	# Add starting point for trailing line.
	trail_line_node.add_point(orb_node.transform.origin)
	var points_added = 1

	# Travel along the nodes as long as there is distance left to travel.
	while distance_to_travel > 0.0:
		# Figure out next node.
		var to_node = positions[current_position] - orb_node.transform.origin
		var distance_to_node = to_node.length()

		# Move toward it.
		to_node = to_node.clamped(min(distance_to_travel, distance_to_node))
		var collision = orb_node.move_and_collide(to_node, true, true, true)
		if collision:
			collision.collider.die()
		
		orb_node.transform.origin += to_node

		# TODO: Check collision with player.

		# If we reached the node, go to the next one.
		if distance_to_travel >= distance_to_node:
			# Add a line point at the node's position.
			trail_line_node.add_point(positions[current_position])

			orb_node.transform.origin = positions[current_position]
			points_added += 1
			current_position += 1

			# Have we reached the final node?
			if current_position >= positions.size():
				state = STOPPED
				break
		else:
			# Add a line point at the current position
			trail_line_node.add_point(orb_node.transform.origin)
			points_added += 1

		distance_to_travel -= distance_to_node

	# Add information to trails.
	var frame = TrailNode.new()
	frame.num_points = points_added
	frame.time = delta
	trails.append(frame)

# Clear old line trails.
func clear_old_lines():
	# Clear out previous trails if they're too old.
	var frame = trails.size() - 1
	var time = 0.0
	while (frame >= 0 and time < trail_time):
		time += trails[frame].time
		frame -= 1

	if time > trail_time:
		frame += 1
		var i = 0
		while i <= frame:
			for point in range(trails[0].num_points):
				trail_line_node.remove_point(0)

			i += 1
			trails.remove(0)

# Fire the bullet!
func fire():
	state = FORESIGHT
	current_position = 0

# Set the orb pattern to travel.
#   pattern - line describing the pattern
func set_pattern(pattern : Line2D):
	# Get this in case this is called before _ready
	foresight_line_node = get_node("ForesightLine")
	
	# Set positions to travel to.
	positions.clear()
	
	for i in range(pattern.get_point_count()):
		positions.append(pattern.get_point_position(i))
	
	# Foresight.
	foresight_line_node.clear_points()
	
	for position in positions:
		foresight_line_node.add_point(position)