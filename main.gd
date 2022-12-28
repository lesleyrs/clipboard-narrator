extends Control

var id = 0
var ut_map = {}
var voices
var last_copy = DisplayServer.clipboard_get()
enum MODES { INTERRUPT, QUEUE, MANUAL }
var current_mode = MODES.INTERRUPT
var current_title = "INTERRUPT MODE"
var stylebox_flat = StyleBoxFlat.new()

# TODO
# add logo/icon, see current state of embedding pck
# why does it color the black borders from canvas_mode? what's causing it?
# turn speak and pause into 1 button and keep the held down + change text? add always on top toggle + resize
# try linux primary clipboard + test linux html
# allow forcing english by default setting after saving + colorpicker reset default right click? + default mode loading+title + size/always on top keeping
# save clipboard in array for going back in history 1-0 keys? pause toggle with selecting 1 word
# how to limit "fit content height" size and allow scrolling somehow
# don't interrupt before voice ended/cancelled, interrupting voice breaks the yellow highlighting
# web build cuts off speech before finishing help text, and following higlight rarely works.
# non english voices not shown in list because it can't find them.
# no smart word wrap mode for textedit https://github.com/godotengine/godot/issues/3985
# font oversampling bug with canvas mode https://github.com/godotengine/godot/issues/56399 it works on current layout though

# Note: On Windows and Linux (X11), utterance text can use SSML markup.
# SSML support is engine and voice dependent. If the engine does not support SSML,
# you should strip out all XML markup before calling tts_speak().

func _ready():
	$ColorPickerButton.color = "4d4d4d"
	stylebox_flat.border_width_bottom = 3
	stylebox_flat.border_width_left = 3
	stylebox_flat.border_width_right = 3
	stylebox_flat.border_width_top = 3
	stylebox_flat.border_color = Color.CRIMSON
	stylebox_flat.bg_color = $ColorPickerButton.color
	$RichTextLabel.add_theme_stylebox_override("normal", stylebox_flat)
	
	DisplayServer.window_set_title("Clipboard Narrator - %s" % current_title)
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
	DisplayServer.window_set_title("Clipboard Narrator - %s" % current_title)
	if Input.is_action_just_pressed("tts_shift_tab") and !$Utterance.has_focus():
		var voice = DisplayServer.tts_get_voices_for_language("en")
		if !voice.is_empty():
			match current_mode:
				0:
					current_mode = MODES.MANUAL
					current_title = "MANUAL MODE"
					ut_map[id] = "MANUAL MODE"
					DisplayServer.tts_speak("MANUAL MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				1:
					current_mode = MODES.INTERRUPT
					current_title = "INTERRUPT MODE"
					ut_map[id] = "INTERRUPT MODE"
					DisplayServer.tts_speak("INTERRUPT MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				2:
					current_mode = MODES.QUEUE
					current_title = "QUEUE MODE"
					ut_map[id] = "QUEUE MODE"
					DisplayServer.tts_speak("QUEUE MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
		id += 1
				
	elif Input.is_action_just_pressed("tts_tab") and !$Utterance.has_focus():
		var voice = DisplayServer.tts_get_voices_for_language("en")
		if !voice.is_empty():
			match current_mode:
				0:
					current_mode = MODES.QUEUE
					current_title = "QUEUE MODE"
					ut_map[id] = "QUEUE MODE"
					DisplayServer.tts_speak("QUEUE MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				1:
					current_mode = MODES.MANUAL
					current_title = "MANUAL MODE"
					ut_map[id] = "MANUAL MODE"
					DisplayServer.tts_speak("MANUAL MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
				2:
					current_mode = MODES.INTERRUPT
					current_title = "INTERRUPT MODE"
					ut_map[id] = "INTERRUPT MODE"
					DisplayServer.tts_speak("INTERRUPT MODE", voice[0], $HSliderVolume.value, $HSliderPitch.value, $HSliderRate.value, id, true)
		id += 1
				
	if Input.is_action_just_pressed("tts_space") and !DisplayServer.tts_is_speaking():
		$ButtonSpeak.emit_signal("pressed")
		
	elif Input.is_action_just_pressed("tts_space") and DisplayServer.tts_is_speaking():
		$ButtonPause.emit_signal("pressed")
		
	if Input.is_action_just_pressed("tts_escape"):
		get_parent().gui_release_focus()
		
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
		
func _process(_delta):
	if DisplayServer.clipboard_get() != last_copy:
		match current_mode:
			0:
				$ButtonIntSpeak.emit_signal("pressed")
				last_copy = DisplayServer.clipboard_get()
			1:
				$ButtonSpeak.emit_signal("pressed")
				last_copy = DisplayServer.clipboard_get()
			2:
				last_copy = DisplayServer.clipboard_get()
		
	$ButtonPause.set_pressed(DisplayServer.tts_is_paused())
	if DisplayServer.tts_is_speaking():
		$Label.text = "Speaking..."
	else:
		$Label.text = "Waiting for input..."

func _on_utterance_boundary(pos, id):
	$RichTextLabel.text = "[bgcolor=yellow][color=black]" + ut_map[id].substr(0, pos) + "[/color][/bgcolor]" + ut_map[id].substr(pos, -1)

func _on_utterance_start(id):
	$Log.text += "utterance %d started\n" % [id]

func _on_utterance_end(id):
	$RichTextLabel.text = "[bgcolor=yellow][color=black]" + ut_map[id] + "[/color][/bgcolor]"
	$Log.text += "utterance %d ended\n" % [id]
	ut_map.erase(id)

func _on_utterance_error(id):
	$RichTextLabel.text = ""
	$Log.text += "utterance %d canceled\n" % [id]
	ut_map.erase(id)
	
func _on_button_stop_pressed():
	if !DisplayServer.tts_is_speaking():
		$RichTextLabel.text = ""
	DisplayServer.tts_stop()

func _on_button_pause_pressed():
	if $ButtonPause.pressed:
		DisplayServer.tts_pause()
	else:
		DisplayServer.tts_resume()
		
func _on_button_speak_pressed():
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
			
func _on_button_int_speak_pressed():
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
	
func _on_button_fullscreen_pressed():
	if DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_FULLSCREEN \
	and DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_MAXIMIZED: # temporary?
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	elif DisplayServer.window_get_mode() != DisplayServer.WINDOW_MODE_WINDOWED:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
