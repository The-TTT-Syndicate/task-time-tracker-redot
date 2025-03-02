extends Control

@onready var task_list_container = $VBoxContainer/ScrollContainer/VBoxContainer
@onready var add_task_button = $VBoxContainer/MarginContainer2/HBoxContainer2/ButtonAddTask
@onready var reset_all_button = $VBoxContainer/MarginContainer2/HBoxContainer2/ButtonResetAll
@onready var total_time_label = $VBoxContainer/MarginContainer2/HBoxContainer2/LabelTotalTime
@onready var title_label = $VBoxContainer/MarginContainer/HBoxContainer/LabelHackingTime

var tasks = []
var active_task = null
var timer = null

class Task:
	var name: String
	var elapsed_time: float
	var is_running: bool
	
	func _init(task_name: String):
		name = task_name
		elapsed_time = 0.0
		is_running = false
		
	func format_time() -> String:
		var hours = floor(elapsed_time / 3600)
		var minutes = floor((elapsed_time - hours * 3600) / 60)
		var seconds = floor(elapsed_time - hours * 3600 - minutes * 60)
		return "%02d:%02d:%02d" % [hours, minutes, seconds]

func save_tasks():
	var tasks_data = []
	for task in tasks:
		tasks_data.append({
			"name": task.name,
			"elapsed_time": task.elapsed_time
		})
	
	var dir = DirAccess.open("user://")
	if not dir:
		DirAccess.make_dir_absolute("user://")
	
	var json_string = JSON.stringify(tasks_data)
	var save_path = "user://TaskTimeTracker.json"
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	file.store_string(json_string)
	file.close()

func load_tasks():
	var save_path = "user://TaskTimeTracker.json"
	if FileAccess.file_exists(save_path):
		var file = FileAccess.open(save_path, FileAccess.READ)
		var json_string = file.get_as_text()
		file.close()
		
		var json = JSON.parse_string(json_string)
		if json:
			for task_data in json:
				var task = Task.new(task_data["name"])
				task.elapsed_time = task_data["elapsed_time"]
				tasks.append(task)
				add_task_ui(task)

func _ready():
	var style = StyleBoxEmpty.new()
	add_theme_stylebox_override("focus", style)
	theme = Theme.new()
	theme.set_stylebox("focus", "Button", style)
	theme.set_stylebox("focus", "LineEdit", style)

	var scroll = task_list_container.get_parent()
	scroll.get_v_scroll_bar().modulate = Color("#F50078")
	
	add_task_button.connect("pressed", Callable(self, "_on_add_task_pressed"))
	reset_all_button.connect("pressed", Callable(self, "_on_reset_all_pressed"))
	
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	add_child(timer)
	
	# Auto-save timer
	var autosave_timer = Timer.new()
	autosave_timer.wait_time = 60.0
	autosave_timer.connect("timeout", Callable(self, "save_tasks"))
	add_child(autosave_timer)
	autosave_timer.start()
	
	load_tasks()

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_tasks()
		get_tree().quit()

func _find_task_button(_task: Task) -> Button:
	for grid in task_list_container.get_children():
		if grid is GridContainer:
			var play_button = grid.get_child(3)
			if play_button is Button:
				return play_button
	return null

func _on_add_task_pressed():
	var task = Task.new("New Task")
	tasks.append(task)
	add_task_ui(task)

func _on_reset_all_pressed():
	for task in tasks:
			task.elapsed_time = 0
			task.is_running = false
			
	if timer.is_stopped() == false:
		timer.stop()
	
	active_task = null
	
	reset_title_label()

	for grid in task_list_container.get_children():
		if grid is GridContainer:
			var play_button = grid.get_child(3) if grid.get_child_count() > 3 else null
			var time_label = grid.get_child(4) if grid.get_child_count() > 4 else null

			if play_button and play_button is Button:
				var play_btn_texture = preload("res://play.svg")
				play_button.icon = play_btn_texture

			if time_label and time_label is Label:
				time_label.add_theme_color_override("font_color", Color(1, 1, 1))

	update_time_displays()
	update_total_time()		
			
func _on_name_focus_entered(line_edit: LineEdit):
	if line_edit.text == "New Task":
		line_edit.text = ""

func _on_name_focus_exited(line_edit: LineEdit):
	if line_edit.text == "":
		line_edit.text = "New Task"

func add_task_ui(task: Task):
	var grid = GridContainer.new()
	grid.columns = 5
	
	var spacer = Label.new()
	spacer.text = ""
	
	var delete_btn = Button.new()
	var delete_btn_texture = preload("res://delete.svg")
	delete_btn.icon = delete_btn_texture
	delete_btn.connect("pressed", Callable(self, "_on_delete_task").bind(task, grid))
	delete_btn.add_theme_constant_override("margin_left", 5)

	var name_edit = LineEdit.new()
	name_edit.text = task.name
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.connect("text_changed", Callable(self, "_on_task_renamed").bind(task))
	name_edit.connect("focus_entered", Callable(self, "_on_name_focus_entered").bind(name_edit))
	name_edit.connect("focus_exited", Callable(self, "_on_name_focus_exited").bind(name_edit))
	
	var play_btn = Button.new()
	var play_btn_texture = preload("res://play.svg")
	play_btn.icon = play_btn_texture
	
	play_btn.connect("pressed", Callable(self, "_on_play_pause").bind(task, play_btn))
	name_edit.connect("gui_input", Callable(self, "_on_name_input").bind(task, play_btn))
	
	var time_label = Label.new()
	time_label.text = task.format_time()
	time_label.add_to_group("time_labels")
	time_label.mouse_filter = Control.MOUSE_FILTER_PASS
	time_label.gui_input.connect(func(event: InputEvent):
		if event is InputEventMouseButton:
			if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_play_pause(task, play_btn)
	)
	grid.add_child(spacer)
	grid.add_child(delete_btn)
	grid.add_child(name_edit)
	grid.add_child(play_btn)
	grid.add_child(time_label)
	
	task_list_container.add_child(grid)

func reset_title_label():
	title_label.text = "It's time to hack time!"
	title_label.remove_theme_color_override("font_color")
	title_label.remove_theme_stylebox_override("normal")

func _on_timer_timeout():
	if active_task:
		active_task.elapsed_time += 1.0
		update_time_displays()

func _on_play_pause(task: Task, button: Button):
	if active_task == task:
		active_task = null
		task.is_running = false
		var play_btn_texture = preload("res://play.svg")
		button.icon = play_btn_texture
		timer.stop()
		
		reset_title_label()

		for grid in task_list_container.get_children():
			var time_label = grid.get_child(4) if grid.get_child_count() > 4 else null
			if time_label and time_label is Label:
				time_label.add_theme_color_override("font_color", Color(1, 1, 1))
		
	else:
		if active_task:
			active_task.is_running = false

		for grid in task_list_container.get_children():
			if grid is GridContainer:
				var play_button = grid.get_child(3)
				var play_btn_texture = preload("res://play.svg")
				play_button.icon = play_btn_texture
				
				var time_label = grid.get_child(4) if grid.get_child_count() > 4 else null
				if time_label and time_label is Label:
					time_label.add_theme_color_override("font_color", Color(1, 1, 1))
		
		active_task = task
		task.is_running = true
		var pause_btn_texture = preload("res://pause.svg")
		button.icon = pause_btn_texture
		timer.start()

		title_label.text = "Hacking time!"
		title_label.add_theme_color_override("font_color", Color(0, 1, 0))

		for grid in task_list_container.get_children():
			var time_label = grid.get_child(4) if grid.get_child_count() > 4 else null
			if time_label and time_label is Label and tasks[task_list_container.get_children().find(grid)] == task:
				time_label.add_theme_color_override("font_color", Color(0, 1, 0))

func _on_name_input(event: InputEvent, task: Task, play_btn: Button):
	if event is InputEventKey:
		var key_event = event as InputEventKey
		if key_event.pressed and (key_event.keycode == KEY_ENTER or key_event.keycode == KEY_KP_ENTER):
			_on_play_pause(task, play_btn)

func _on_delete_task(task: Task, grid: GridContainer):
	var task_index = tasks.find(task)
	if task_index != -1:
		tasks.remove_at(task_index)
	if task == active_task:
		active_task = null
		timer.stop()
		reset_title_label()	
	grid.queue_free()
	update_total_time()
	
func _on_task_renamed(new_text: String, task: Task):
	task.name = new_text

func update_time_displays():
	for grid in task_list_container.get_children():
		if grid is GridContainer:
			var time_label = grid.get_child(4)
			var play_button = grid.get_child(3)
			
			var play_btn_texture = preload("res://play.svg")
			play_button.icon = play_btn_texture
			
			if active_task and tasks[task_list_container.get_children().find(grid)] == active_task:
				var pause_btn_texture = preload("res://pause.svg")
				play_button.icon = pause_btn_texture
		
			if time_label is Label:
				var task_index = task_list_container.get_children().find(grid)
				if task_index < tasks.size():
					time_label.text = tasks[task_index].format_time()
	update_total_time()

func update_total_time():
	var total = 0.0
	for task in tasks:
		total += task.elapsed_time
	if total_time_label:
		var hours = floor(total / 3600)
		var minutes = floor((total - hours * 3600) / 60)
		var seconds = floor(total - hours * 3600 - minutes * 60)
		total_time_label.text = "%02d:%02d:%02d" % [hours, minutes, seconds]
