extends Control

var id = 0
var ut_map = {}
var voices
var last_copy = DisplayServer.clipboard_get()
enum MODES { INTERRUPT, QUEUE, MANUAL }
var current_mode = MODES.INTERRUPT
var mode_name = "INTERRUPT MODE"
var stylebox_flat = StyleBoxFlat.new()
var size_changed = false
var total_lines = 0
var window_active = false

# TODO
# add logo/icon, see state of embedding pck, add releases to github, try linux primary clipboard extra + web build
# save clipboard in array 1-0 keys history, optionbutton text low resolution, shadowed variables not ignored beta 10
# save total_lines/lang/colorpicker/sliders/mode/title/size/ontop/check all settings for loading
# disable scroll and use scroll to line? sometimes when switching modes, the richtextlabel doesn't resize

# allow changing slider while speaking and stop richtext moving scrollbar or make it follow without stopping
# web build cuts off speech before finishing help text, and following highlight rarely works.
# https://github.com/godotengine/godot-demo-projects/pull/744 can't find non-english voices on windows at least
# https://github.com/godotengine/godot/issues/39144 interrupt voice breaks the yellow highlight + can't scroll at all?
# https://github.com/godotengine/godot/issues/3985 no smart word wrap mode for textedit
# https://github.com/godotengine/godot/issues/56399 font oversampling bug canvas mode (works curr layout)

# Note: On Windows and Linux (X11), utterance text can use SSML markup.
# SSML support is engine and voice dependent. If the engine does not support SSML,
# you should strip out all XML markup before calling tts_speak().

func _ready():
	format_suffix()

	if OS.has_feature("web"):
		$ButtonFolder.queue_free() # see if this one works on web exported
		$ButtonFullscreen.queue_free()
		$ButtonOnTop.queue_free()
		$OptionButton.queue_free()

	$OptionButton.add_item("P: 854x480")
	$OptionButton.add_item("P: 960x540")
	$OptionButton.add_item("P: 1024x576")
	$OptionButton.add_item("P: 1152x648")
	$OptionButton.add_item("P: 1280x720")
	$OptionButton.add_item("P: 1366x768")
	$OptionButton.add_item("P: 1600x900")
	$OptionButton.select(3)

	$ColorPickerButton.color = "4d4d4d"
	stylebox_flat.bg_color = $ColorPickerButton.color
	stylebox_flat.border_width_bottom = 1
	stylebox_flat.border_width_top = 1
	stylebox_flat.border_width_left = 1
	stylebox_flat.border_width_right = 1
	if $ColorPickerButton.color.get_luminance() >= 0.5: # needed here for saving background colour
		stylebox_flat.border_color = Color.BLACK
	else:
		stylebox_flat.border_color = Color.WHITE
	$RichTextLabel.add_theme_stylebox_override("normal", stylebox_flat)

	DisplayServer.window_set_title("Clipboard Narrator - %s" % mode_name)
	voices = DisplayServer.tts_get_voices()
	var root = $Tree.create_item()
	$Tree.set_hide_root(true)
	$Tree.set_column_title(0, "Name")
	$Tree.set_column_title(1, "Language")
	$Tree.set_column_titles_visible(true)
	var child = $Tree.create_item(root)
	child.select(0)
	for v in voices:
		child.set_text(0, v["name"])
		child.set_metadata(0, v["id"])
		child.set_text(1, v["language"])
	if OS.has_feature("web"):
		$Log.text += "\nEnglish voice available\n"
	elif voices.size() == 1:
		$Log.text += "\n%d voice available\n" % [voices.size()]
	elif voices.size() > 1:
		$Log.text += "\n%d voices available\n" % [voices.size()]

	$Log.text += "=======================\n"

	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_utterance_start"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_utterance_end"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, Callable(self, "_on_utterance_error"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_BOUNDARY, Callable(self, "_on_utterance_boundary"))

func _unhandled_input(_event):
	DisplayServer.window_set_title("Clipboard Narrator - %s" % mode_name)
	if Input.is_action_just_pressed("tts_shift_tab") and !$Utterance.has_focus():
		var voice = DisplayServer.tts_get_voices_for_language("en")
		if !voice.is_empty():
			match current_mode:
				0:
					current_mode = MODES.MANUAL
					mode_name = "MANUAL MODE"
					ut_map[id] = "MANUAL MODE"
					DisplayServer.tts_speak("MANUAL MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				1:
					current_mode = MODES.INTERRUPT
					mode_name = "INTERRUPT MODE"
					ut_map[id] = "INTERRUPT MODE"
					DisplayServer.tts_speak("INTERRUPT MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				2:
					current_mode = MODES.QUEUE
					mode_name = "QUEUE MODE"
					ut_map[id] = "QUEUE MODE"
					DisplayServer.tts_speak("QUEUE MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
		id += 1

	elif Input.is_action_just_pressed("tts_tab") and !$Utterance.has_focus():
		var voice = DisplayServer.tts_get_voices_for_language("en")
		if !voice.is_empty():
			match current_mode:
				0:
					current_mode = MODES.QUEUE
					mode_name = "QUEUE MODE"
					ut_map[id] = "QUEUE MODE"
					DisplayServer.tts_speak("QUEUE MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				1:
					current_mode = MODES.MANUAL
					mode_name = "MANUAL MODE"
					ut_map[id] = "MANUAL MODE"
					DisplayServer.tts_speak("MANUAL MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				2:
					current_mode = MODES.INTERRUPT
					mode_name = "INTERRUPT MODE"
					ut_map[id] = "INTERRUPT MODE"
					DisplayServer.tts_speak("INTERRUPT MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
		id += 1

	if Input.is_action_just_pressed("tts_space"):
		window_active = true
		$ButtonToggle.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_escape"):
		if get_parent().gui_get_focus_owner() != null:
			get_parent().gui_release_focus()
			$RichTextLabel.set_focus_mode(Control.FOCUS_NONE)
		else:
			$ButtonStop.emit_signal("pressed")

	if !$Utterance.has_focus():
		if Input.is_action_just_pressed("tts_enter") or Input.is_action_just_pressed("tts_i"):
			$Utterance.grab_focus.call_deferred()

	if Input.is_action_just_pressed("tts_z"):
		$HSliderRate.grab_focus.call_deferred()

	if Input.is_action_just_pressed("tts_x"):
		$HSliderPitch.grab_focus.call_deferred()

	if Input.is_action_just_pressed("tts_c"):
		$HSliderVolume.grab_focus.call_deferred()

	if Input.is_action_just_pressed("tts_n"):
		$LineEditFilterName.grab_focus.call_deferred()

	if Input.is_action_just_pressed("tts_l"):
		$LineEditFilterLang.grab_focus.call_deferred()

	if Input.is_action_just_pressed("tts_u"):
		$RichTextLabel.set_focus_mode(Control.FOCUS_ALL)
		$RichTextLabel.grab_focus.call_deferred()

	if Input.is_action_pressed("tts_shift"):
		$HSliderRate.step = 0.5
		$HSliderPitch.step = 0.5
		$HSliderVolume.step = 10
	else:
		$HSliderRate.step = 0.05
		$HSliderPitch.step = 0.05
		$HSliderVolume.step = 1

	if Input.is_action_just_pressed("tts_h"):
		$ButtonDemo.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_r"):
		$ButtonIntSpeak.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_s"):
		$ButtonStop.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_f"):
		$ButtonFullscreen.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_t"):
		$ButtonOnTop.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_o"):
		$ButtonFolder.emit_signal("pressed")

	if Input.is_action_just_pressed("tts_p"):
		if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN \
		and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MAXIMIZED:
			$OptionButton.show_popup()

func resize_label():
#	print($RichTextLabel.get_line_count())
	$RichTextLabel.size.y = $RichTextLabel.get_line_count() * 27
	if $RichTextLabel.size.y >= 616:
		$RichTextLabel.size.y = 616
		$RichTextLabel.scroll_active = true
	format_suffix()
	size_changed = true

@warning_ignore(integer_division)
func format_suffix():
	total_lines += $RichTextLabel.get_line_count()

	var format_label: String
	var lines_copied = " lines copied "
	if $RichTextLabel.get_line_count() == 1:
		lines_copied = " line copied "

	if total_lines >= 1000000000000000000:
		format_label = lines_copied + "[rainbow freq=0.2 sat=10 val=20](" + str(total_lines / 1000000000000000000) + " Quintillion)[/rainbow]"
	elif total_lines >= 1000000000000000:
		format_label = lines_copied + "[color=CORAL](" + str(total_lines / 1000000000000000) + "Q)[/color]"
	elif total_lines >= 1000000000000:
		format_label = lines_copied + "[color=CYAN](" + str(total_lines / 1000000000000) + "T)[/color]"
	elif total_lines >= 1000000000:
		format_label = lines_copied + "[color=INDIAN_RED](" + str(total_lines / 1000000000) + "B)[/color]"
	elif total_lines >= 10000000:
		format_label = lines_copied + "[color=GREEN](" + str(total_lines / 1000000) + "M)[/color]"
	elif total_lines >= 100000:
		format_label = lines_copied + "[color=YELLOW](" + str(total_lines / 1000) + "K)[/color]"
	else:
		format_label = lines_copied + "[color=WHITE](" + str(total_lines) + ")[/color]"

	$LinesLabel.text = "[center]" + str($RichTextLabel.get_line_count()) + format_label + "[/center]"

func _process(_delta):
	if DisplayServer.clipboard_get() != last_copy:
		match current_mode:
			0:
				if DisplayServer.clipboard_get().count(" ") > 1 or $Utterance.has_focus():
					$ButtonIntSpeak.emit_signal("pressed")
					last_copy = DisplayServer.clipboard_get()
				else:
					$ButtonStop.emit_signal("pressed")
					last_copy = DisplayServer.clipboard_get()
			1:
				if DisplayServer.clipboard_get().count(" ") > 1 or $Utterance.has_focus():
					$ButtonToggle.emit_signal("pressed")
					last_copy = DisplayServer.clipboard_get()
				else:
					pause()
					last_copy = DisplayServer.clipboard_get()
			2:
				last_copy = DisplayServer.clipboard_get()

	if DisplayServer.tts_is_speaking():
		$Label.text = "Speaking..."
		$ButtonToggle.text = "Space: Pause"
	else:
		$Label.text = "Waiting for input..."
		$ButtonToggle.text = "Space: Speak"

@warning_ignore(shadowed_variable)
func _on_utterance_boundary(pos, id):
	$RichTextLabel.text = "[bgcolor=yellow][color=black]" + ut_map[id].substr(0, pos) + "[/color][/bgcolor]" + ut_map[id].substr(pos, -1)
	if size_changed == false:
		resize_label()

@warning_ignore(shadowed_variable)
func _on_utterance_start(id):
	$Log.text += "utterance %d started\n" % [id]

@warning_ignore(shadowed_variable)
func _on_utterance_end(id):
	$RichTextLabel.text = "[bgcolor=yellow][color=black]" + ut_map[id] + "[/color][/bgcolor]"
	$Log.text += "utterance %d ended\n" % [id]
	ut_map.erase(id)
	size_changed = false
	DisplayServer.tts_resume()

@warning_ignore(shadowed_variable)
func _on_utterance_error(id):
	$RichTextLabel.text = ""
	$Log.text += "utterance %d canceled\n" % [id]
	ut_map.erase(id)
	size_changed = false
	$RichTextLabel.text = " U: Focus"
	DisplayServer.tts_resume()

func _on_button_stop_pressed():
	DisplayServer.tts_stop()
	if get_parent().gui_get_focus_owner() != null:
		get_parent().gui_release_focus()
		$RichTextLabel.set_focus_mode(Control.FOCUS_NONE)
	$RichTextLabel.size.y = 27
	$RichTextLabel.scroll_active = false
	$RichTextLabel.text = " U: Focus"

func pause():
	if !DisplayServer.tts_is_paused():
		DisplayServer.tts_pause()
	else:
		DisplayServer.tts_resume()
		
func _on_button_toggle_pressed():
	if !window_active and DisplayServer.tts_is_speaking() or !window_active and !DisplayServer.tts_is_paused() \
	or window_active and !DisplayServer.tts_is_speaking() and !DisplayServer.tts_is_paused():
		if !OS.has_feature("web"):
			if $Tree.get_selected():
				$Log.text += "utterance %d queried\n" % [id]
				match current_mode:
					0, 1:
						ut_map[id] = DisplayServer.clipboard_get()
						DisplayServer.tts_speak(DisplayServer.clipboard_get(), $Tree.get_selected().get_metadata(0), $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, false)
					2:
						ut_map[id] = $Utterance.text
						DisplayServer.tts_speak($Utterance.text, $Tree.get_selected().get_metadata(0), $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, false)
				id += 1
			else:
				# is it possible for alerts to be always on top?
				if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP):
					$ButtonOnTop.emit_signal("pressed")
				OS.alert("Select voice.")

		if OS.has_feature("web"):
			var voice = DisplayServer.tts_get_voices_for_language("en")
			if !voice.is_empty():
				$Log.text += "utterance %d queried\n" % [id]
				match current_mode:
					0, 1:
						ut_map[id] = DisplayServer.clipboard_get()
						DisplayServer.tts_speak(DisplayServer.clipboard_get(), voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, false)
					2:
						ut_map[id] = $Utterance.text
						DisplayServer.tts_speak($Utterance.text, voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, false)
				id += 1
	else:
		pause()

func _on_button_int_speak_pressed():
#	if DisplayServer.tts_is_speaking(): # bad workaround to fix highlight because then you have to press r twice.
#		DisplayServer.tts_stop()
	if !OS.has_feature("web"):
		if $Tree.get_selected():
			$Log.text += "utterance %d interrupt\n" % [id]
			match current_mode:
				0, 1:
					ut_map[id] = DisplayServer.clipboard_get()
					DisplayServer.tts_speak(DisplayServer.clipboard_get(), $Tree.get_selected().get_metadata(0), $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				2:
					ut_map[id] = $Utterance.text
					DisplayServer.tts_speak($Utterance.text, $Tree.get_selected().get_metadata(0), $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
			id += 1
		else:
			# is it possible for alerts to be always on top?
			if DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP):
					$ButtonOnTop.emit_signal("pressed")
			OS.alert("Select voice.")

	if OS.has_feature("web"):
		var voice = DisplayServer.tts_get_voices_for_language("en")
		if !voice.is_empty():
			$Log.text += "utterance %d interrupt\n" % [id]
			match current_mode:
				0, 1:
					ut_map[id] = DisplayServer.clipboard_get()
					DisplayServer.tts_speak(DisplayServer.clipboard_get(), voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				2:
					ut_map[id] = $Utterance.text
					DisplayServer.tts_speak($Utterance.text, voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
			id += 1

func _on_button_clear_log_pressed():
	$Log.text = "\n"

func _on_h_slider_rate_value_changed(value):
	$HSliderRate/Value.text = "%.2fx" % [value]

func _on_h_slider_pitch_value_changed(value):
	$HSliderPitch/Value.text = "%.2fx" % [value]

func _on_h_slider_volume_value_changed(value):
	$HSliderVolume/Value.text = "%d%%" % [value]

func _on_button_demo_pressed():
	var voice = DisplayServer.tts_get_voices_for_language("en")
	if !DisplayServer.tts_is_speaking() and !DisplayServer.tts_is_paused():
		if !voice.is_empty():
			ut_map[id] = $Utterance.placeholder_text
			DisplayServer.tts_speak($Utterance.placeholder_text, voice[0], 50, 1, 1, id)
			id += 1

func _on_line_edit_filter_name_text_changed(_new_text):
	$Tree.clear()
	var root = $Tree.create_item()
	for v in voices:
		if ($LineEditFilterName.text.is_empty() || $LineEditFilterName.text.to_lower() in v["name"].to_lower()) && ($LineEditFilterLang.text.is_empty() || $LineEditFilterLang.text.to_lower() in v["language"].to_lower()):
			var child = $Tree.create_item(root)
			child.set_text(0, v["name"])
			child.set_metadata(0, v["id"])
			child.set_text(1, v["language"])
			child.select(0)

func _on_log_text_set():
	$Log.scroll_vertical = $Log.text.length()

func _on_color_picker_button_color_changed(color):
	RenderingServer.set_default_clear_color($ColorPickerButton.color)
	stylebox_flat.bg_color = $ColorPickerButton.color
	if $ColorPickerButton.color.get_luminance() >= 0.5:
		stylebox_flat.border_color = Color.BLACK
	else:
		stylebox_flat.border_color = Color.WHITE

func _on_rich_text_label_focus_entered():
	stylebox_flat.border_width_bottom = 0
	stylebox_flat.border_width_top = 0

func _on_rich_text_label_focus_exited():
	stylebox_flat.border_width_bottom = 1
	stylebox_flat.border_width_top = 1

func _on_button_fullscreen_pressed():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN \
	and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MAXIMIZED \
	and !DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP):
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		$ButtonFullscreen.set_pressed(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		$ButtonOnTop.disabled = true
		$OptionButton.disabled = true
	elif DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		$ButtonFullscreen.set_pressed(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
		$ButtonOnTop.disabled = false
		$OptionButton.disabled = false

func _on_button_on_top_pressed():
	if !DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP) \
	and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN \
	and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MAXIMIZED:
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, true)
		$ButtonOnTop.set_pressed(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP))
		$ButtonFullscreen.disabled = true
	elif DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP):
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP, false)
		$ButtonOnTop.set_pressed(DisplayServer.window_get_flag(DisplayServer.WINDOW_FLAG_ALWAYS_ON_TOP))
		$ButtonFullscreen.disabled = false

func _on_option_button_item_selected(index):
	var current_selected = index

	match current_selected:
		0:
			DisplayServer.window_set_size(Vector2(854, 480))
		1:
			DisplayServer.window_set_size(Vector2(960, 540))
		2:
			DisplayServer.window_set_size(Vector2(1024, 576))
		3:
			DisplayServer.window_set_size(Vector2(1152, 648))
		4:
			DisplayServer.window_set_size(Vector2(1280, 720))
		5:
			DisplayServer.window_set_size(Vector2(1366, 768))
		6:
			DisplayServer.window_set_size(Vector2(1600, 900))

func _on_button_folder_pressed():
	OS.shell_open(ProjectSettings.globalize_path("user://"))
	
func _notification(what):
	match what:
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_IN:
			window_active = true
		MainLoop.NOTIFICATION_APPLICATION_FOCUS_OUT:
			window_active = false
