@tool
extends Control

# Path to the Neon Aeon project JSON file
@export_file("*.json") var project_file: String = ""

# Auto-start playback when ready
@export var auto_start: bool = true

# Starting act ID (leave empty for first act)
@export var starting_act: String = ""

# Starting scene ID (leave empty for first scene)
@export var starting_scene: String = ""

# Starting node ID (leave empty for first node)
@export var starting_node: String = ""

# Internal data
var project_data: Dictionary = {}
var current_act: Dictionary = {}
var current_scene: Dictionary = {}
var current_node: Dictionary = {}

# Child nodes
var video_player: VideoStreamPlayer
var image_display: TextureRect
var dialogue_label: Label
var choice_ui: Control
var audio_players: Dictionary = {}
var dialogue_container: Control
var scene_audio_player: AudioStreamPlayer
var bgm_player: AudioStreamPlayer  
var dialogue_player: AudioStreamPlayer  
var current_bgm_track: String = ""  

func play_scene_audio(scene: Dictionary):
	# Play background audio for a scene
	if not scene.has("audioTracks") or scene.audioTracks.size() == 0:
		print("No audio tracks in this scene")
		return
	
	print("Audio tracks found: ", scene.audioTracks.size())
	
	# Process each audio track
	for i in range(scene.audioTracks.size()):
		var audio_track = scene.audioTracks[i]
	
		var label = audio_track.get("label", "").to_lower()
		var audio_path = audio_track.get("path", "")
	
		if audio_path == "" or not FileAccess.file_exists(audio_path):
			print("Scene audio file not found: ", audio_path)
			continue
	
		var audio_stream = load(audio_path)
		if not audio_stream:
			continue
		
		# Handle different types of audio
		if label == "bgm":
		# Only start BGM if it's different from what's playing
			if current_bgm_track != audio_path:
				current_bgm_track = audio_path
				bgm_player.stream = audio_stream
				bgm_player.play()
			else:
				print("BGM already playing: ", audio_path)
			
		elif label == "dialogue":
			# Stop any previous dialogue and play new one
			dialogue_player.stop()
			dialogue_player.stream = audio_stream
			dialogue_player.play()
		else:
			print("  -> Unknown audio type, skipping: '", label, "'")
		

func stop_bgm():
	# Stop background music
	bgm_player.stop()
	current_bgm_track = ""

func _ready():
	if Engine.is_editor_hint():
		return  # Don't run in editor
	
	# Set up the UI structure
	setup_ui()
	
	# Load the project
	if project_file != "":
		load_project(project_file)
		
		if auto_start:
			start_playback()

func setup_ui():
	# Create the UI structure for displaying content
	anchor_right = 1.0
	anchor_bottom = 1.0
	
	# Video player (hidden by default)
	video_player = VideoStreamPlayer.new()
	video_player.name = "VideoPlayer"
	video_player.expand = true
	video_player.anchor_right = 1.0
	video_player.anchor_bottom = 1.0
	video_player.offset_left = 0
	video_player.offset_top = 0
	video_player.offset_right = 0
	video_player.offset_bottom = 0
	video_player.size = get_viewport().get_visible_rect().size
	video_player.finished.connect(_on_video_finished)
	add_child(video_player)
	
	# Audio system
	scene_audio_player = AudioStreamPlayer.new()
	scene_audio_player.name = "SceneAudioPlayer"
	add_child(scene_audio_player)
	
	bgm_player = AudioStreamPlayer.new()
	bgm_player.name = "BGMPlayer"
	bgm_player.bus = "BGM"
	bgm_player.volume_db = -6.0
	add_child(bgm_player)

	dialogue_player = AudioStreamPlayer.new()
	dialogue_player.name = "DialoguePlayer"
	dialogue_player.bus = "Dialogue"
	dialogue_player.volume_db = 0.0
	add_child(dialogue_player)
	
	# Image display
	image_display = TextureRect.new()
	image_display.name = "ImageDisplay"
	image_display.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	image_display.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image_display.position = Vector2.ZERO
	image_display.size = get_viewport().get_visible_rect().size
	image_display.visible = false  # Hide initially as expected
	add_child(image_display)
	
	# Create dialogue container with background
	dialogue_container = Control.new()
	dialogue_container.name = "DialogueContainer"
	var screen_size = get_viewport().get_visible_rect().size
	dialogue_container.position = Vector2(screen_size.x * 0.1, screen_size.y * 0.65)
	dialogue_container.size = Vector2(screen_size.x * 0.8, screen_size.y * 0.3)
	
	# Add background to the container
	var dialogue_bg = Panel.new()
	dialogue_bg.name = "DialogueBackground"
	dialogue_bg.position = Vector2.ZERO
	dialogue_bg.size = dialogue_container.size
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.5, 0.5, 0.5, 0.7) 
	style_box.corner_radius_top_left = 15
	style_box.corner_radius_top_right = 15
	style_box.corner_radius_bottom_left = 15
	style_box.corner_radius_bottom_right = 15
	dialogue_bg.add_theme_stylebox_override("panel", style_box)
	dialogue_container.add_child(dialogue_bg)
	dialogue_container.visible = false  # Hide initially
	
	# Dialogue label
	dialogue_label = Label.new()
	dialogue_label.name = "DialogueLabel"
	dialogue_label.position = Vector2(dialogue_container.size.x * 0.05, dialogue_container.size.y * 0.05)
	dialogue_label.size = Vector2(dialogue_container.size.x * 0.9, dialogue_container.size.y * 0.45)
	dialogue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.visible = false  # Hide initially 

	# Style the label
	var label_settings = LabelSettings.new()
	label_settings.font_size = 32
	label_settings.font_color = Color.WHITE
	label_settings.outline_color = Color.BLACK
	label_settings.outline_size = 3
	dialogue_label.label_settings = label_settings
	
	dialogue_container.add_child(dialogue_label)
	add_child(dialogue_container)
	
	# Choice UI - Position in bottom half of dialogue container
	choice_ui = preload("res://addons/neon_aeon/scripts/ChoiceUI.gd").new()
	choice_ui.name = "ChoiceUI"
	choice_ui.position = Vector2(dialogue_container.size.x * 0.05, dialogue_container.size.y * 0.55)
	choice_ui.size = Vector2(dialogue_container.size.x * 0.9, dialogue_container.size.y * 0.4)
	choice_ui.choice_selected.connect(_on_choice_selected)
	dialogue_container.add_child(choice_ui)
	
	print("Neon Aeon Player: UI setup complete")

# Dialogue show/hide functions
func show_dialogue_ui():
	if dialogue_container:
		dialogue_container.visible = true

func hide_dialogue_ui():
	if dialogue_container:
		dialogue_container.visible = false

func set_dialogue_text(text: String):
	if dialogue_label:
		dialogue_label.text = text
		dialogue_label.visible = !text.is_empty()
	if !text.is_empty():
		show_dialogue_ui()
	else:
		hide_dialogue_ui()

func load_project(file_path: String):
	# Load and parse the Neon Aeon JSON file
	if not FileAccess.file_exists(file_path):
		push_error("Neon Aeon: Project file not found: " + file_path)
		return
	
	var file = FileAccess.open(file_path, FileAccess.READ)
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(json_string)
	
	if error != OK:
		push_error("Neon Aeon: JSON parse error at line " + str(json.get_error_line()) + ": " + json.get_error_message())
		return
	
	project_data = json.data
	print("Neon Aeon Player: Project loaded - " + project_data.get("name", "Untitled"))

func start_playback():
	# Start playing from the specified act/scene/node
	if project_data.is_empty():
		push_error("Neon Aeon: No project loaded")
		return
	
	# Find starting point
	var act_id = starting_act if starting_act != "" else project_data.acts[0].id
	var scene_id = starting_scene
	var node_id = starting_node
	
	# Find the act
	for act in project_data.acts:
		if act.id == act_id:
			current_act = act
			break
	
	if current_act.is_empty():
		push_error("Neon Aeon: Starting act not found")
		return
	
	# Find the scene (or use first scene)
	if scene_id == "":
		current_scene = current_act.scenes[0]
	else:
		for scene in current_act.scenes:
			if scene.id == scene_id:
				current_scene = scene
				break
	
	if current_scene.is_empty():
		push_error("Neon Aeon: Starting scene not found")
		return
	
	# Find the node (or use first node)
	if node_id == "":
		current_node = current_scene.nodes[0]
	else:
		for node in current_scene.nodes:
			if node.id == node_id:
				current_node = node
				break
	
	if current_node.is_empty():
		push_error("Neon Aeon: Starting node not found")
		return
	
	print("Neon Aeon Player: Starting playback")
	play_node(current_node)

func play_node(node: Dictionary):
	current_node = node
	
	# Clear previous content
	video_player.visible = false
	image_display.visible = false
	dialogue_label.visible = false
	
	# Stop dialogue audio when changing nodes (but keep BGM)
	dialogue_player.stop()
	
	print("Neon Aeon Player: Playing node - " + node.name)
	
	if node.type == "video":
		play_video_node(node)
	elif node.type == "dialogue":
		play_image_node(node)

func play_video_node(node: Dictionary):
	var video_path = node.get("videoPath", "")

	if video_path == "" or not FileAccess.file_exists(video_path):
		push_error("Neon Aeon: Video file not found: " + video_path)
		_on_node_finished()
		return
	
	# Use the new audio system
	play_scene_audio(current_scene)
	
	# Load and play video
	var video_stream = load(video_path)
	video_player.stream = video_stream
	video_player.visible = true
	video_player.play()
	
	# Show dialogue text if present
	var dialogue_text = node.get("dialogueText", "")
	set_dialogue_text(dialogue_text)
	
func play_image_node(node: Dictionary):
	var image_path = node.get("imagePath", "")
	
	if image_path == "" or not FileAccess.file_exists(image_path):
		push_error("Neon Aeon: Image file not found: " + image_path)
		_on_node_finished()
		return
	
	play_scene_audio(current_scene)
	
	# Load and display image
	var texture = load(image_path)
	image_display.texture = texture
	image_display.visible = true
	
	# Show dialogue text
	var dialogue_text = node.get("dialogueText", "")
	set_dialogue_text(dialogue_text)
	
	# Play dialogue audio if present (this is the old per-node audio)
	var audio_path = node.get("dialogueAudio", "")
	if audio_path != "" and FileAccess.file_exists(audio_path):
		var audio_player = AudioStreamPlayer.new()
		audio_player.stream = load(audio_path)
		add_child(audio_player)
		audio_player.finished.connect(func(): 
			audio_player.queue_free()
			_on_node_finished()
		)
		audio_player.play()
	else:
		call_deferred("_on_node_finished")

func _on_video_finished():
	_on_node_finished()

func _on_node_finished():
	# Check if this node has choices
	if current_node.has("choices") and current_node.choices.size() > 0:
		show_choices(current_node.choices)
	else:
		# No choices, advance to next node
		advance_to_next_node()

func show_choices(choices: Array):
	# Display choice UI
	var question = current_node.get("dialogueText", "")
	choice_ui.show_choices(choices, question)

func _on_choice_selected(choice: Dictionary):
	var target_node_id = choice.get("targetNodeId", "")
	
	if target_node_id == "":
		push_error("Neon Aeon: Choice has no target node")
		return
	
	jump_to_node(target_node_id)

func jump_to_node(node_id: String):
	# Jump to a specific node by ID (can be cross-scene/cross-act)
	print("Neon Aeon Player: Jumping to node " + node_id)
	
	# Parse the node ID (format: act_X_scene_Y_node_Z)
	var parts = node_id.split("_")
	if parts.size() < 6:
		push_error("Neon Aeon: Invalid node ID format: " + node_id)
		return
	
	var target_act_id = parts[0] + "_" + parts[1]
	var target_scene_id = parts[0] + "_" + parts[1] + "_" + parts[2] + "_" + parts[3]
	var target_node_id = node_id
	
	# Find and play the target node
	for act in project_data.acts:
		if act.id == target_act_id:
			for scene in act.scenes:
				if scene.id == target_scene_id:
					for node in scene.nodes:
						if node.id == target_node_id:
							current_act = act
							current_scene = scene
							play_node(node)
							return
	
	push_error("Neon Aeon: Target node not found: " + node_id)

func advance_to_next_node():
	# Advance to the next node in sequence, or next scene, or next act
	var nodes = current_scene.nodes
	var current_index = -1
	
	# Find current node index
	for i in range(nodes.size()):
		if nodes[i].id == current_node.id:
			current_index = i
			break
	
	# Try next node in current scene
	if current_index >= 0 and current_index < nodes.size() - 1:
		play_node(nodes[current_index + 1])
		return
	
	# No more nodes in scene - try next scene
	print("Neon Aeon Player: End of scene, advancing to next scene")
	advance_to_next_scene()

func advance_to_next_scene():
	# Advance to the next scene in the current act
	var scenes = current_act.scenes
	var current_scene_index = -1
	
	# Find current scene index
	for i in range(scenes.size()):
		if scenes[i].id == current_scene.id:
			current_scene_index = i
			break
	
	# Try next scene in current act
	if current_scene_index >= 0 and current_scene_index < scenes.size() - 1:
		current_scene = scenes[current_scene_index + 1]
		print("Neon Aeon Player: Starting scene - " + current_scene.name)
		
		# Play first node of new scene
		if current_scene.nodes.size() > 0:
			play_node(current_scene.nodes[0])
		return
	
	# No more scenes in act - try next act
	print("Neon Aeon Player: End of act, advancing to next act")
	advance_to_next_act()

func advance_to_next_act():
	# Advance to the next act
	var acts = project_data.acts
	var current_act_index = -1
	
	# Find current act index
	for i in range(acts.size()):
		if acts[i].id == current_act.id:
			current_act_index = i
			break
	
	# Try next act
	if current_act_index >= 0 and current_act_index < acts.size() - 1:
		current_act = acts[current_act_index + 1]
		print("Neon Aeon Player: Starting act - " + current_act.name)
		
		# Start first scene of new act
		if current_act.scenes.size() > 0:
			current_scene = current_act.scenes[0]
			
			# Play first node of first scene
			if current_scene.nodes.size() > 0:
				play_node(current_scene.nodes[0])
		return
	
	# Truly the end - no more acts
	print("Neon Aeon Player: End of all content")
