extends Node2D

# The icon to show (who's talking).
enum { CAT_NEUTRAL, CAT_FACEPAW, CAT_SHOW_TEETH, CAT_SWEAT }

# Nodes to keep track of.
onready var paw_node = get_node("MessageBox/BoxSprite/Label/PawSprite")
onready var cat_node = get_node("MessageBox/CatSprite")
onready var box_node = get_node("MessageBox/BoxSprite")
onready var label_node = get_node("MessageBox/BoxSprite/Label")
onready var animation_player = get_node("MessageBox/AnimationPlayer")

export(Texture) var cat_neutral_texture
export(Texture) var cat_facepaw_texture
export(Texture) var cat_show_teeth_texture
export(Texture) var cat_sweat_texture

# Message information.
class Message:
	var icon
	var message

var messages = []
var current_message = 0

var callback_object = null
var callback_method = ""

# State machine.
enum { BEGIN, ENTER, SCROLL_MESSAGE, DISPLAY_MESSAGE, LEAVE }
var state = BEGIN

# Timer used to flash paw and scroll characters.
var timer = 0

# How long paw should be visible.
var paw_time = 0.3

# Which character we are currently at.
var character = 0
var time_per_character = 0.025

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if state == ENTER:
		if timer > 0.1:
			visible = true
		timer += delta
	elif state == SCROLL_MESSAGE:
		timer += delta
		while timer > time_per_character and character < messages[current_message].message.length():
			timer -= time_per_character
			character += 1
		
		label_node.set_text(messages[current_message].message.substr(0, character))
		
		if character == messages[current_message].message.length():
			state = DISPLAY_MESSAGE
			timer = 0
		
	elif state == DISPLAY_MESSAGE:
		# Flash paw.
		timer += delta
		if timer > paw_time:
			paw_node.visible = !paw_node.visible
			timer -= paw_time
		
		# Handle user input.
		if Input.is_action_just_pressed("ui_accept"):
			# Show next message.
			current_message += 1
			if current_message < messages.size():
				show_current_message()
			else:
				state = LEAVE
				animation_player.play_backwards("Enter")

# Add a new message to the queue.
func add_message(icon, message):
	var mes = Message.new()
	mes.icon = icon
	mes.message = message
	messages.append(mes)

# Show the current message.
func show_current_message():
	var mes = messages[current_message]
	set_icon(mes.icon)
	label_node.set_text("")
	timer = 0
	character = 0
	state = SCROLL_MESSAGE
	get_node("AudioStreamPlayer").pitch_scale = 0.7 + randf() * 0.6
	get_node("AudioStreamPlayer").play()

# Set the talker icon.
func set_icon(icon):
	if icon == CAT_NEUTRAL:
		cat_node.texture = cat_neutral_texture
	elif icon == CAT_FACEPAW:
		cat_node.texture = cat_facepaw_texture
	elif icon == CAT_SHOW_TEETH:
		cat_node.texture = cat_show_teeth_texture
	elif icon == CAT_SWEAT:
		cat_node.texture = cat_sweat_texture

# Show the queue of messages.
func show_messages(call_object, call_method):
	if messages.size() == 0:
		push_warning("Tried to show empty message queue! Queue messages first!")
	
	callback_object = call_object
	callback_method = call_method
	set_icon(messages[0].icon)
	
	animation_player.connect("animation_finished", self, "animation_finished")
	animation_player.play("Enter")
	current_message = 0
	label_node.set_text("")
	paw_node.visible = false
	state = ENTER

# Handle the finished animation.
func animation_finished(e):
	if state == ENTER:
		show_current_message()
	elif state == LEAVE :
		visible = false
		messages.clear()
		state = BEGIN
		callback_object.call(callback_method)

func test_callback():
	print("It worked")