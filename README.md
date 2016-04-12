# boipushy

An input module for LÖVE. Simplifies input handling by abstracting them away to actions,
enabling pressed/released checks outside of LÖVE's callbacks and taking care of gamepad input as well.

## Usage

```lua
Input = require 'Input'
```

### Creating an input object

```lua
function love.load()
  input = Input()
end
```

### Binding keys to actions

Key is the key pressed e.g. 's'

Action is either 'pressed', 'released', 'held' or 'moved'. 'moved' only applies to some keys (usually mouse 1-5).

Gamestate is an arbitary state e.g. 'level' or 'menu'. 'all' can be used if you want to be called no matter the state.

Id is 0 or nil for keyboard/mouse and the Joystick ID for joysticks.

f is the function you want to be called e.g. print("testing") or function() local t = 3 print(t) end

If you are calling a function on an object you will have to use an anonymous function to pass the parameters correctly
e.g. function(...) fireBullet(...) end

You will have to look at the callback functions for each to see what parameters are passed.

```lua
input:bind(key, action, gamestate, id, f)
input:bind('1', 'released', 'level', nil, function(...) fireBullet(...) end)
input:bind('s', 'pressed', 'menu', 0, function() print(2) end)
input:bind('mouse1', 'moved', 'all', 0, mouseMoved())
```

### Checking if an action is pressed/released/down

```lua
input:bind('1', 'held', 'level', nil, function() print("1 held") end)
```

### Unbinding a key

```lua
input:unbind(key, action, gamestate, id)
input:unbind('1', 'pressed', 'level')
input:unbind('s', 'released', 'menu')
input:unbind('mouse1', 'moved', 'level')
```

### Key/mouse/gamepad Constants

Keyboard constants are unchanged from [here](https://www.love2d.org/wiki/KeyConstant), but mouse and gamepad have been changed to the following:

```lua
-- Mouse
'mouse1'
'mouse2'
'mouse3'
'mouse4'
'mouse5'
'wheelup'
'wheeldown'
'wheelleft'
'wheelright'

-- Gamepad
'fdown' -- fdown/up/left/right = face buttons: a, b...
'fup'
'fleft'
'fright'
'back'
'guide'
'start'
'leftstick' -- left stick pressed or not (boolean)
'rightstick' -- right stick pressed or not (boolean)
'l1'
'r1'
'l2'
'r2'
'dpup' -- dpad buttons
'dpdown'
'dpleft'
'dpright'
'leftx' -- the left stick's horizontal position
'lefty' -- same for vertical
'rightx' -- same for right stick
'righty'
```

### Modifiers

If a modifer has been pressed when a function is bound to a key then then it will bind to key+modifier.

```lua
--Modifiers
'numlock'
'capslock'
'scrolllock'
'rshift'
'lshift'
'rctrl'
'lctrl'
'ralt'
'lalt'
'rgui'
'lgui'
'mode'
```

### LICENSE

You can do whatever you want with this. See the [LICENSE](https://github.com/adonaac/thomas/blob/master/LICENSE).
