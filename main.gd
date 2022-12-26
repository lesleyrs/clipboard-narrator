extends Control

var id = 0
var ut_map = {}
var voices
var last_copy = DisplayServer.clipboard_get()
enum MODES { INTERRUPT, QUEUE, MANUAL }
var current_state = MODES.INTERRUPT
var current_title = "INTERRUPT MODE"

# TODO
# allow hidpi good for gui or not?
# RenderingServer.set_default_clear_color() colorpicker?
# add theme and font, find out best anchors and window settings, 2d scaling is bugged right now
# mini mode with always on top, google icons w/ borderless (atm glitchy and moves when opened)
# don't interrupt before voice ended/cancelled, interrupting voice breaks the yellow highlighting
# disable scrolling if speaking or why is scroll bar glitchy/forced to bottom?
# no smart word wrap mode for textedit https://github.com/godotengine/godot/issues/3985
# save clipboard in array for going back in history?
# allow forcing english by default setting after saving
# web build cuts off before finishing help text, very buggy

# Note: On Windows and Linux (X11), utterance text can use SSML markup.
# SSML support is engine and voice dependent. If the engine does not support SSML,
# you should strip out all XML markup before calling tts_speak().

func _ready():
	DisplayServer.window_set_title("Clipboard Narrator - %s" % current_title) # check after saving if it works
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
		$Log.text += "\nWeb build needs window focus to read clipboard.\nCurrently English only.\nPC build recommended.\n"
	elif voices.size() == 1:
		$Log.text += "\n%d voice available\n" % [voices.size()]
	elif voices.size() > 1:
		$Log.text += "\n%d voices available\n" % [voices.size()]
			
	$Log.text += "=======================\n"

	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_STARTED, Callable(self, "_on_utterance_start"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_ENDED, Callable(self, "_on_utterance_end"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_CANCELED, Callable(self, "_on_utterance_error"))
	DisplayServer.tts_set_utterance_callback(DisplayServer.TTS_UTTERANCE_BOUNDARY, Callable(self, "_on_utterance_boundary"))
	set_process(true) # what's the purpose of this? low processor mode on or off?
	
func _unhandled_input(_event):
	DisplayServer.window_set_title("Clipboard Narrator - %s" % current_title)
	if Input.is_action_just_pressed("tts_shift_tab") and !$Utterance.has_focus():
		match current_state:
			0:
				current_state = MODES.MANUAL
				current_title = "MANUAL MODE"
			1:
				current_state = MODES.INTERRUPT
				current_title = "INTERRUPT MODE"
			2:
				current_state = MODES.QUEUE
				current_title = "QUEUE MODE"
				
	elif Input.is_action_just_pressed("tts_tab") and !$Utterance.has_focus():
		match current_state:
			0:
				current_state = MODES.QUEUE
				current_title = "QUEUE MODE"
			1:
				current_state = MODES.MANUAL
				current_title = "MANUAL MODE"
			2:
				current_state = MODES.INTERRUPT
				current_title = "INTERRUPT MODE"
				
	if Input.is_action_just_pressed("tts_space") and !DisplayServer.tts_is_speaking():
		$ButtonSpeak.emit_signal("pressed")
		
	elif Input.is_action_just_pressed("tts_space") and DisplayServer.tts_is_speaking():
		$ButtonPause.emit_signal("pressed")
	
	if Input.is_action_just_pressed("tts_escape"):
		$Utterance.release_focus()
		
	if Input.is_action_just_pressed("tts_enter") or Input.is_action_just_pressed("tts_i"):
		$Utterance.grab_focus.call_deferred()
		
	if Input.is_action_just_pressed("tts_z"):
		$HSliderRate.grab_focus.call_deferred()
		
	if Input.is_action_just_pressed("tts_x"):
		$HSliderPitch.grab_focus.call_deferred()
		
	if Input.is_action_just_pressed("tts_c"):
		$HSliderVolume.grab_focus.call_deferred()
		
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
		
func _process(_delta):
	if DisplayServer.clipboard_get() != last_copy:
		match current_state:
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
		$Label.modulate = Color(1, 0, 0)
		$Label.text = "Speaking..."
	else:
		$Label.modulate = Color(1, 1, 1)
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
	$Log.text += "utterance %d cancelled\n" % [id]
	ut_map.erase(id)
	
func _on_button_stop_pressed():
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
			match current_state:
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
			match current_state:
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
			match current_state:
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
			match current_state:
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
	var help_text = \
"Tab or Shift-Tab to change modes (in title bar).
Enter to focus text editor. Escape to lose focus.
Space to start/pause. S to stop. R to repeat. H for help.
Z-X-C keys to focus sliders, Shift for faster speed.

Note: The granularity of pitch, rate, and volume is engine and voice dependent. Values may be truncated."

	if !voice.is_empty():
		if OS.has_feature("web"):
			ut_map[id] = help_text
			DisplayServer.tts_speak(help_text, voice[0], 50, 1, 1, id)
			id += 1
			
		if !OS.has_feature("web"):
			ut_map[id] = help_text
			DisplayServer.tts_speak(help_text, voice[0], 50, 1, 1, id)
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
