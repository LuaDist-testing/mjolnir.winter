--- === mjolnir.winter ===
---
--- A module for moving/resizing windows using a fluent interface (see Usage below).
---
--- The name winter is a portmanteu of **win**dow mas**ter**.
---
--- Usage:
---
---     local winter = require "mjolnir.winter"
---
---     local cmdalt  = {"cmd", "alt"}
---     local scmdalt  = {"cmd", "alt", "shift"}
---     local ccmdalt = {"ctrl", "cmd", "alt"}
---
---     -- make the focused window a 200px, full-height window and put it at the left screen edge
---     hotkey.bind(cmdalt, 'h', winter.focused():wide(200):tallest():leftmost():place())
---
---     -- make a full-height window and put it at the right screen edge
---     hotkey.bind(cmdalt, 'j', winter.focused():tallest():rightmost():place())
---
---     -- full-height window, full-width window, and a combination
---     hotkey.bind(scmdalt, '\\', winter.focused():tallest():resize())
---     hotkey.bind(scmdalt, '-', winter.focused():widest():resize())
---     hotkey.bind(scmdalt, '=', winter.focused():widest():tallest():resize())
---
--- *NOTE*: One must start with `winter.focused()` or `winter.window('title')`
--- and end with a command `move()`, `place()`, `resize()`, or `act()`
--- (they are all synonyms for the same action). This chain of command
---- will return a function that one can pass to hotkey.bind.
---
---
--- [Github Page](https://github.com/knl/mjolnir.winter)
---
--- @author    Nikola Knezevic
--- @copyright 2014
--- @license   BSD
---
--- @module mjolnir.winter

-- main module class table
local winter = {
  _VERSION     = '0.1.0',
  _DESCRIPTION = 'A module for moving/resizing windows using a fluent interface',
  _URL         = 'https://github.com/knl/mjolnir.winter',
}

local appfinder = require "mjolnir.cmsj.appfinder"
local window = require "mjolnir.window"

-- class that deals with coordinate transformations
local CoordTrans = {}

function CoordTrans:set(win, screen, f)
  local screenrect = screen:frame()
  print(string.format("set: screen x=%d, y=%d, w=%d, h=%d", screenrect.x, screenrect.y, screenrect.w, screenrect.h))
  print(string.format("set: input f x=%d, y=%d, w=%d, h=%d", f.x, f.y, f.w, f.h))
  newf = {
    x = f.x + screenrect.x,
    y = f.y + screenrect.y,
    w = f.w,
    h = f.h,
  }
  print(string.format("set: input f x=%d, y=%d, w=%d, h=%d", newf.x, newf.y, newf.w, newf.h))
  win:setframe(newf)
end

function CoordTrans:get(win, _screen)
  local f = win:frame()
  local screen = _screen or win:screen()
  local screenrect = screen:frame()
  print(string.format("get: screen x=%d, y=%d, w=%d, h=%d", screenrect.x, screenrect.y, screenrect.w, screenrect.h))
  print(string.format("get: win f x=%d, y=%d, w=%d, h=%d", f.x, f.y, f.w, f.h))
  return {
    x = f.x - screenrect.x,
    y = f.y - screenrect.y,
    w = f.w,
    h = f.h,
    screenw = screenrect.w,
    screenh = screenrect.h,
  }
end

local function new_coord_trans()
  local self = {}
  setmetatable(self, { __index = CoordTrans })
  return self
end

-- class table for the main thing
local Winter = {}

function winter.new(ct)
  local self = {}
  self.ct = ct or new_coord_trans()
  setmetatable(self, { __index = Winter })
  return self
end

-- class table representing an action on a window
WinterAction = {}

local function init_winter_action(title)
  return {
    -- coord transformer
    ct = 0,
    -- title of the window, '' denotes the focused window
    title = title,
    -- location
    x = -1,
    y = -1,
    -- dimensions
    w = 0,
    h = 0,
    -- changes accrued in the methods
    dx = 0,
    dy = 0,
    dw = 0,
    dh = 0,
    -- 'mosts'
    _tallest = false,
    _widest = false,
    _leftmost = false,
    _rightmost = false,
    _topmost = false,
    _bottommost = false,
  }
end

--- mjolnir.Winter.focused()
--- Function
--- Creates a new WinterAction object for the focused window
function Winter:focused()
  _self = init_winter_action('')
  _self.ct = self.ct
  setmetatable(_self, { __index = WinterAction })
  return _self
end

--- mjolnir.Winter:window(title)
--- Function
--- Creates a new WinterAction object for the main window of the app titled 'title'
function Winter:window(title)
  assert(title and title ~= '', 'Cannot find a window without a title')
  _self = init_winter_action(title)
  _self.ct = self.ct
  setmetatable(_self, { __index = WinterAction })
  return _self
end

--- mjolnir.winter:snap(win)
--- Function
--- Snaps the window into a cell
function Winter:snap(win)
  if win:isstandard() then
    self.ct:set(win, self:get(win), win:screen())
  end
end

--- mjolnir.winter.pushwindow_nextscreen()
--- Function
--- Moves the focused window to the next screen, using its current cell on that screen.
function Winter:pushwindow_nextscreen()
  local win = window.focusedwindow()
  self.ct:set(win, grid.get(win), win:screen():next())
end

--- mjolnir.winter.pushwindow_prevscreen()
--- Function
--- Moves the focused window to the previous screen, using its current cell on that screen.
function Winter:pushwindow_prevscreen()
  local win = window.focusedwindow()
  self.ct:set(win, grid.get(win), win:screen():previous())
end

--- mjolnir.winteraction:xpos(x)
--- Function
--- Sets windows' x position to x, defaults to 0
function WinterAction:xpos(x)
  self.x = x or 0
  self._leftmost = false
  self._rightmost = false
  return self
end

--- mjolnir.winteraction:ypos(y)
--- Function
--- Sets windows' y position to y, defaults to 0
function WinterAction:ypos(y)
  self.y = y or 0
  self._topmost = false
  self._bottommost = false
  return self
end

--- mjolnir.winteraction:right(by)
--- Function
--- Moves the window to the right 'by' units. 'by' defaults to 1.
function WinterAction:right(by)
  self.dx = self.dx + (by or 1)
  return self
end

--- mjolnir.winteraction:left(by)
--- Function
--- Moves the window to the left 'by' units. 'by' defaults to 1.
function WinterAction:left(by)
  self.dx = self.dx - (by or 1)
  return self
end

--- mjolnir.winteraction:up(by)
--- Function
--- Moves the window to the up 'by' units. 'by' defaults to 1.
function WinterAction:up(by)
  self.dy = self.dy - (by or 1)
  return self
end

--- mjolnir.winteraction:down()
--- Function
--- Moves the window to the down 'by' units. 'by' defaults to 1.
function WinterAction:down(by)
  self.dy = self.dy + (by or 1)
  return self
end

--- mjolnir.winteraction:wide(w)
--- Function
--- Set's the window to be w units wide.
function WinterAction:wide(w)
  self.w = w
  self._widest = false
  return self
end

--- mjolnir.winteraction:tall(h)
--- Function
--- Set's the window to be h units tall.
function WinterAction:tall(h)
  self.h = h
  self._tallest = false
  return self
end

--- mjolnir.winteraction:thinner(by)
--- Function
--- Makes the window thinner by 'by' units.
--- by can be a negative number, too.
--- If by is omitted, defaults to 1.
function WinterAction:thinner(by)
  self.dw = self.dw - (by or 1)
  self._widest = false
  return self
end

--- mjolnir.winteraction:wider(by)
--- Function
--- Makes the window wider by 'by' units.
--- by can be a negative number, too.
--- If by is omitted, defaults to 1.
function WinterAction:wider(by)
  self.dw = self.dw + (by or 1)
  self._widest = false
  return self
end

--- mjolnir.winteraction:taller(by)
--- Function
--- Makes the window taller by 'by' units.
--- by can be a negative number, too.
--- If by is omitted, defaults to 1.
function WinterAction:taller(by)
  self.dh = self.dh + (by or 1)
  self._tallest = false
  return self
end

--- mjolnir.winteraction:shorter(by)
--- Function
--- Makes the window taller by 'by' units.
--- by can be a negative number, too.
--- If by is omitted, defaults to 1.
function WinterAction:shorter(by)
  self.dh = self.dh - (by or 1)
  self._tallest = false
  return self
end

--- mjolnir.winteraction:tallest()
--- Function
--- Makes windows' height the height of the screen.
function WinterAction:tallest()
  self._tallest = true
  self.dh = 0
  self.h = 0
  self.y = 0
  return self
end

--- mjolnir.winteraction:widest()
--- Function
--- Makes windows' width the width of the screen.
function WinterAction:widest()
  self._widest = true
  self.dw = 0
  self.w = 0
  self.x = 0
  return self
end

--- mjolnir.winteraction:leftmost()
--- Function
--- Makes the window align with the left screen border. Any preceding
--- commands to change the horizontal position of the window are
--- forgotten.
function WinterAction:leftmost()
  self.dx = 0
  self._leftmost = true
  return self
end

--- mjolnir.winteraction:rightmost()
--- Function
--- Makes the window align with the right screen border. Any preceding
--- commands to change the horizontal position of the window are
--- forgotten.
function WinterAction:rightmost()
  self.dx = 0
  self._rightmost = true
  return self
end

--- mjolnir.winteraction:topmost()
--- Function
--- Makes the window align with the top screen border. Any preceding
--- commands to change the vertical position of the window are
--- forgotten.
function WinterAction:topmost()
  self.dy = 0
  self._topmost = true
  return self
end

--- mjolnir.winteraction:bottommost()
--- Function
--- Makes the window align with the bottom screen border. Any preceding
--- commands to change the vertical position of the window are
--- forgotten.
function WinterAction:bottommost()
  self.dy = 0
  self._bottommost = true
  return self
end

--- mjolnir.winteraction:act()
--- Function
--- Finalizes all previous commands for changing windows' size and
--- position. This command will produce an anonymous, parameterless
--- function that can be fed to hotkey.bind method (from hotkey
--- package).
function WinterAction:act()
  return function()
    local f = {}
    local win = nil
    if title then
       local app = appfinder.app_from_name(title)
       win = app:mainwindow()
       -- alert.show(string.format('application title for %q is %q, main window %q', title, app:title(), window:title()))
    else
      win = window.focusedwindow()
    end

    local origf = self.ct:get(win)
    -- print(string.format("origf x=%d, y=%d, w=%d, h=%d", origf.x, origf.y, origf.w, origf.h))
    -- print(string.format("self x=%d, y=%d, w=%d, h=%d", self.x, self.y, self.w, self.h))
    -- print(string.format("self dx=%d, dy=%d, dw=%d, dh=%d", self.dx, self.dy, self.dw, self.dh))

    -- take defaults
    f.w = (self.w == 0) and origf.w or self.w
    f.h = (self.h == 0) and origf.h or self.h
    f.x = (self.x == -1) and origf.x or self.x
    f.y = (self.y == -1) and origf.y or self.y

    -- widest and tallest

    if self._widest then
      f.w = origf.screenw
    end
    if self._tallest then
      f.h = origf.screenh
    end
    -- adjust width and height
    if self.dw ~= 0 then
      f.w = math.min(origf.screenw, math.max(1, f.w + self.dw))
    end
    if self.dh ~= 0 then
      f.h = math.min(origf.screenh, math.max(1, f.h + self.dh))
    end

    -- and positions
    if self._topmost then
       f.y = 0
    end
    if self._leftmost then
       f.x = 0
    end
    if self._rightmost then
       f.x = origf.screenw - f.w
    end
    if self._bottommost then
       f.y = origf.screenh - f.h
    end

    if self.dx ~= 0 then
      f.x = math.min(origf.screenw, math.max(0, f.x + self.dx))
    end
    if self.dy ~= 0 then
      f.y = math.min(origf.screenh, math.max(0, f.y + self.dy))
    end

    -- print(string.format("final f x=%d, y=%d, w=%d, h=%d", f.x, f.y, f.w, f.h))
    -- print(string.format("application is '%q'", win:title()))
    self.ct:set(win, win:screen(), f)
  end
end

--- mjolnir.winteraction:resize()
--- Function
--- Alias for act()
WinterAction.resize = WinterAction.act
--- mjolnir.winteraction:move()
--- Function
--- Alias for act()
WinterAction.move = WinterAction.act
--- mjolnir.winteraction:place()
--- Function
--- Alias for act()
WinterAction.place = WinterAction.act

return winter
