# Mjolnir.winter

A module for moving/resizing your windows using a fluent interface (see Usage below).

The name winter is a portmanteu of **win**dow mas**ter**.

## Usage

    local winter = require "mjolnir.winter"

    local cmdalt  = {"cmd", "alt"}
    local scmdalt  = {"cmd", "alt", "shift"}
    local ccmdalt = {"ctrl", "cmd", "alt"}

    -- make the focused window a 200px, full-height window and put it at the left screen edge
    hotkey.bind(cmdalt, 'h', winter.focused():wide(200):tallest():leftmost():place())

    -- make a full-height window and put it at the right screen edge
    hotkey.bind(cmdalt, 'j', winter.focused():tallest():rightmost():place())

    -- full-height window, full-width window, and a combination
	hotkey.bind(scmdalt, '\\', winter.focused():tallest():resize())
	hotkey.bind(scmdalt, '-', winter.focused():widest():resize())
	hotkey.bind(scmdalt, '=', winter.focused():widest():tallest():resize())

*NOTE*: One must start with `winter.focused()` or `winter.window('title')`
and end with a command `move()`, `place()`, `resize()`, or `act()`
(they are all synonyms for the same action). This chain of commands
will return a function that one can easily pass to hotkey.bind.
