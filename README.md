# Clipboard Narrator
Turn any web page into an audiobook, works in the background on desktop!

***Bugs are commented in [`main.gd`](main.gd#L20), otherwise feel free to report any issues!***

Based on: https://github.com/godotengine/godot-demo-projects/pull/744

I made this for myself to save me from doing more reading than needed, but I think it's a good tool anyone can make use of. Thx to [bruvzg](https://github.com/bruvzg) for making it possible! :+1:

![clipboard-narrator](https://user-images.githubusercontent.com/19632758/210650475-b0b2d8f7-2791-43cc-88cf-d7060cb74884.png)

This tool reads from your clipboard after copying text, with the ability to stop a voice by copying 1 word[^1]. This allows you to start and stop a voice without requiring window focus. It auto-saves the text field to a .txt file and settings to .dat file on closing, this means you should close the application before deleting the saves to reset settings. You could also use the text field to take notes.

Inside the application press `h` to get a tts explanation. Copying the same text back to back does not work, press `r` for that. The `i` key can also be used for entering text. Background colour picker is the button on the top left corner.

# interrupt, queue, and manual modes
This application works differently based on which mode you are in (changed by pressing tab or shift-tab). Exception to this is that recent clipboards over 1 word long[^1] are saved in `1` to `0` number keys allowing you to interrupt current speech with past clipboards regardless of mode.

- **interrupt**

Will immediately interrupt current voice with `Ctrl-c`, and only reads off clipboard. Copying 1 word will stop the voice.

- **queue**

Will put all clipboards into a queue using `Ctrl-c`, only reads off clipboard but allows you to add non-sequential text to it. Copying 1 word will pause the voice.

- **manual**

Ignores clipboard, only reads from what you put in the text editor and then hit `speak`, `space` or `r`.

[^1]:1 word means a maximum of 1 space in the copied selection.
