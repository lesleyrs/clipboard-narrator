# clipboard-narrator
Turn any web page into an audiobook, works in the background on desktop!

Based on: https://github.com/godotengine/godot-demo-projects/pull/744

I made this for myself to save me from doing more reading than needed, but I think it's a good tool anyone can make use of. Thx to [bruvzg](https://github.com/bruvzg) for making it possible! :+1:

Web build will spam for clipboard access as it's required to work currently.

PC build is recommended as it'll be able to read from clipboard in the background. No internet connection needed.

Current problems are commented in `main.gd`, but it's completely functional.

Inside the application press `h` to get a tts explanation. Copying the same text back to back does not work, press `r` for that.

# interrupt, queue, and manual modes
This application works differently based on which mode you are in (changed by pressing tab)

- **interrupt**

Will immediately interrupt current voice with `Ctrl-c`, and only reads off clipboard.

- **queue**

Will put all clipboards into a queue using `Ctrl-c`, only reads off clipboard but allows you to add non-sequential text to it.

- **manual**

Ignores clipboard, only reads from what you put in the text editor and then hit `speak`, `space` or `r`.
