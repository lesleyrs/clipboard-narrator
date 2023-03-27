# Clipboard Narrator
Turn any web page into an audiobook, works in the background on desktop!

# Comparison to Microsoft Edge tts
Edge TTS | Clipboard Narrator
|---|---|
no external application needed if you use Edge | download required
online (even for offline files opened in browser) | offline
many languages available | English only on Windows[^1]
delay each time you start or restart a voice | no delay on Windows[^2]
natural sounding voices | dependant on platform

Windows built-in narrator has a different use case but does use the system voices.

![clipboard-narrator](https://user-images.githubusercontent.com/19632758/210650475-b0b2d8f7-2791-43cc-88cf-d7060cb74884.png)

This tool reads from your clipboard after copying text, with the ability to stop a voice by copying 1 word[^3]. This allows you to start and stop a voice without requiring window focus. It auto-saves the text field to a .txt file and settings to .dat file on closing, this means you should close the application before deleting the saves to reset settings. You could also use the text field to take notes.

Inside the application press `h` to get a tts explanation. Copying the same text back to back does not work, press `r` for that. The `i` key can also be used for entering text. Background colour picker is the button on the top left corner.

***Bugs (mostly visual) are commented in [`main.gd`](main.gd#L20)***

# interrupt, queue, and manual modes
This application works differently based on which mode you are in (changed by pressing tab or shift-tab). Exception to this is that recent clipboards over 1 word long[^3] are saved in `1` to `0` number keys allowing you to interrupt current speech with past clipboards regardless of mode.

- **interrupt**

Will immediately interrupt current voice with `Ctrl-c`, and only reads off clipboard. Copying 1 word will stop the voice.

- **queue**

Will put all clipboards into a queue using `Ctrl-c`, only reads off clipboard but allows you to add non-sequential text to it. Copying 1 word will pause the voice.

- **manual**

Ignores clipboard, only reads from what you put in the text editor and then hit `speak`, `space` or `r`.

[^1]:No limit on other platforms, Microsoft has a restriction for loading voices in third party software https://github.com/godotengine/godot/issues/69788#issuecomment-1343912420
[^2]:Linux seems to be slower at loading system voices compared to Windows https://docs.godotengine.org/en/stable/tutorials/audio/text_to_speech.html#caveats-and-other-information
[^3]:1 word means a maximum of 1 space in the copied selection.
