local input_path = (...):match('(.-)[^%.]+$') .. '.'
local Input = {}
local self = {}
Input.__index = Input

-- Local references
  local pairs = pairs
  local assert = assert
  local next = next
	local setmetatable = setmetatable
  
Input.all_keys = {
    " ", "return", "escape", "backspace", "tab", "space", "!", "\"", "#", "$", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", "0", "1", "2", "3", "4",
    "5", "6", "7", "8", "9", ":", ";", "<", "=", ">", "?", "@", "[", "\\", "]", "^", "", "`", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m",
    "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "capslock", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "printscreen",
    "scrolllock", "pause", "insert", "home", "pageup", "delete", "end", "pagedown", "right", "left", "down", "up", "numlock", "kp/", "kp*", "kp-", "kp+", "kpenter",
    "kp0", "kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9", "kp.", "kp,", "kp=", "application", "power", "f13", "f14", "f15", "f16", "f17", "f18", "f19",
    "f20", "f21", "f22", "f23", "f24", "execute", "help", "menu", "select", "stop", "again", "undo", "cut", "copy", "paste", "find", "mute", "volumeup", "volumedown",
    "alterase", "sysreq", "cancel", "clear", "prior", "return2", "separator", "out", "oper", "clearagain", "thsousandsseparator", "decimalseparator", "currencyunit",
    "currencysubunit", "lctrl", "lshift", "lalt", "lgui", "rctrl", "rshift", "ralt", "rgui", "mode", "audionext", "audioprev", "audiostop", "audioplay", "audiomute",
    "mediaselect", "brightnessdown", "brightnessup", "displayswitch", "kbdillumtoggle", "kbdillumdown", "kbdillumup", "eject", "sleep", "mouse1", "mouse2", "mouse3",
    "mouse4", "mouse5", "wheelup", "wheeldown", "wheelleft", "wheelright", "fdown", "fup", "fleft", "fright", "back", "guide", "start", "leftstick", "rightstick", "l1", "r1", "l2", "r2", "dpup",
    "dpdown", "dpleft", "dpright", "leftx", "lefty", "rightx", "righty",
}

Input.modifiers = {'numlock', 'capslock', 'scrolllock', 'rshift', 'lshift', 'rctrl', 'lctrl', 'ralt', 'lalt', 'rgui', 'lgui', 'mode'}

local copy = function(t1)
    local out = {}
    for k, v in pairs(t1) do out[k] = v end
    return out
end

local function updateJoysticks()
  local joysticks = love.joystick.getJoysticks()
  for k, v in pairs(joysticks) do
    if k <= 4 and v:isGamepad() then
      self.joysticks_to_ids[v] = k
    end
  end
end

-- Modifier must be input as some actions won't use modifiers e.g. mouse movement
local function executeFunction(action, id, key, modifier, ...)
    local binding = self.binds[action]
    if binding[self.currentstate] ~= nil and binding[self.currentstate][id] ~=nil then
      local idbinding = binding[self.currentstate][id]
      if idbinding ~= nil then
        if modifier == nil then
          if idbinding[key] ~= nil then
            idbinding[key](...)
          end
        else
          if idbinding[modifier] ~= nil and idbinding[modifier][key] ~= nil then
            idbinding[modifier][key](...)
          end
        end
      end
    end
    if modifier == nil then
      if self.binds[action]["all"][id][key] ~= nil then
        self.binds[action]["all"][id][key](...)
      end
    else
      if self.binds[action]["all"][id][modifier] ~= nil and self.binds[action]["all"][id][modifier][key] ~= nil then
        self.binds[action]["all"][id][modifier][key](...)
      end
    end
end

local function setState(id, key, value)
  self.state[id][key] = value
end

--Use this to do Alt+Y etc, remember to set to blank after
-- Will only work if it's a modifier
local function setModifier(key)
  if key == nil or Input.modifiers[key] ~= nil then
    self.currentmodifier = key
  end
end

function Input.new()
    self.joysticks_to_ids = {}
    self.joystick_axis_values = {[0]={}, [1]={}, [2]={}, [3]={}, [4]={}}
    self.ids = {[0]={}, [1]={}, [2]={}, [3]={}, [4]={}} -- Keyboard + Mouse and 4 Joysticks
    self.state = {[0]={}, [1]={}, [2]={}, [3]={}, [4]={}}  -- Button State
    self.currentstate = "all" -- Game State
    self.currentmodifier = nil -- Keyboard Modifer
    self.binds = {["pressed"] = {[self.currentstate] = copy(self.ids)}, ["moved"] = {[self.currentstate] = copy(self.ids)}, ["released"] = {[self.currentstate] = copy(self.ids)}, ["held"] = {[self.currentstate] = copy(self.ids)}}
    
    local callbacks = {'keypressed', 'keyreleased', 'mousepressed', 'mousereleased', 'mousemoved', 'joystickadded', 'joystickremoved', 'gamepadpressed', 'gamepadreleased', 'gamepadaxis', 'wheelmoved', 'update'}
    local old_functions = {}
    local empty_function = function() end
    for _, f in ipairs(callbacks) do
        old_functions[f] = love[f] or empty_function
        love[f] = function(...)
            old_functions[f](...)
            self[f](self, ...)
        end
    end
    
    return setmetatable(self, Input)
end

--action can be pressed, released, moved or held
--id is used to detect different controllers, 0 is for keyboard
--e.g bind("s", "moved", "game", 0, game:whatever(val))
--if gamestate == nil then the function will be called no matter the state
--
function Input:bind(key, action, gamestate, id, f)
  assert(type(f) == 'function', "f is not a function")
  if Input.modifiers[key] == nil then
    if gamestate == nil then gamestate = "all" end
    if self.joysticks_to_ids[id] ~= nil then id = self.joysticks_to_ids[id] else id = 0 end
    if id == nil then id = 0 end
    if self.binds[action][gamestate] == nil then self.binds[action][gamestate] = {} end
    if self.binds[action][gamestate][id] == nil then self.binds[action][gamestate][id] = {} end
    if self.currentmodifier == nil then
      self.binds[action][gamestate][id][key] = f
    else
      if self.binds[action][gamestate][id][self.currentmodifier] == nil then
        self.binds[action][gamestate][id][self.currentmodifier] = {}
      end
      self.binds[action][gamestate][id][self.currentmodifier][key] = f
    end
    return true -- Binding successful
  end
  return false -- Trying to bind to a modifier, try again with new key
end

function Input:unbind(key, action, gamestate, id)
  if Input.modifiers[key] == nil then
    if gamestate == nil then gamestate = "all" end
    if id == nil then id = 0 end
    if self.currentmodifier == nil then
      self.binds[action][gamestate][id][key] = nil
    else
      self.binds[action][gamestate][id][self.currentmodifier][key] = nil
    end
    return true
  end
  return false
end

function Input:unbindAll()
  self.binds = nil
  self.binds = {["pressed"] = {["all"] = copy(self.ids)}, ["moved"] = {["all"] = copy(self.ids)}, ["released"] = {["all"] = copy(self.ids)}, ["held"] = {["all"] = copy(self.ids)}}
end

function Input:changeState(gamestate)
  if gamestate == nil or gamestate == "all" then
    self.currentstate = "all"
  else
    self.currentstate = gamestate
    for action, statelist in pairs(self.binds) do
      if statelist[gamestate] == nil then
        self.binds[action][gamestate] = copy(self.ids)
      end
    end
  end
end

local key_to_button = {mouse1 = '1', mouse2 = '2', mouse3 = '3', mouse4 = '4', mouse5 = '5'}
local axis_to_button = {leftx = 'leftx', lefty = 'lefty', rightx = 'rightx', righty = 'righty', l2 = 'triggerleft', r2 = 'triggerright'}

local function held()
    local bindings = self.binds["held"][self.currentstate]
    local modifier = self.currentmodifier
    if bindings ~= nil then
      for id, keylist in pairs(bindings) do
        if keylist ~= nil then
          for key, func in pairs(keylist) do
            if modifier == nil then
              if self.state[id][key] and key_to_button[key] == nil and axis_to_button[key] == nil then
                bindings[id][key]()
              end
            else
              if self.state[id][key] and self.state[id][modifier] then
                bindings[id][modifier][key]()
              end
            end
          end
        end
      end
    end
end

function Input:update(dt)
    held()
    self.state[0]['wheelup'] = false
    self.state[0]['wheeldown'] = false
    self.state[0]['wheelleft'] = false
    self.state[0]['wheelright'] = false
end

function Input:keypressed(key, scancode, isrepeat)
    local id = 0 --It's a keyboard
    self.state[id][key] = true
    setModifier(key)
    executeFunction("pressed", id, key, self.currentmodifier, isrepeat)
end

function Input:keyreleased(key, scancode, isrepeat)
    local id = 0 --It's a mouse
    self.state[id][key] = false
    if self.currentmodifer == key then setModifier(nil) end
    executeFunction("released", id, key, self.currentmodifier, isrepeat)
end

local button_to_key = {[1] = 'mouse1', [2] = 'mouse2', [3] = 'mouse3', [4] = 'mouse4', [5] = 'mouse5'}

function Input:mousepressed(x, y, button, istouch)
    local id = 0 --It's a mouse
    local key = button_to_key[button]
    self.state[id][key] = true
    executeFunction("pressed", id, key, self.currentmodifier, x, y, button, istouch)
end

function Input:mousereleased(x, y, button, istouch)
    local id = 0 --It's a mouse
    local key = button_to_key[button]
    self.state[id][key] = false
    executeFunction("released", id, key, self.currentmodifier, x, y, button, istouch)
end

-- Assumes you only want to do this when a key is pressed on the mouse.
-- Could technically work for all keys but it would pick up things such
-- as wheelup and wheeldown which we don't want.
function Input:mousemoved(x, y, dx, dy)
    local id = 0 --It's a mouse
    for k, key in pairs(button_to_key) do
      if self.state[id][key] == true then
        executeFunction("held", id, key, self.currentmodifier, x, y, dx, dy)
      else
        executeFunction("moved", id, key, self.currentmodifier, x, y, dx, dy)
      end
    end
end

function Input:wheelmoved(x, y)
    local id = 0 --It's a mouse
    local key = nil
    if y > 0 then 
      key = 'wheelup'
    elseif y < 0 then 
      key = 'wheeldown'
    end
    if key ~= nil then
      self.state[id][key] = true
      executeFunction("moved", id, key, self.currentmodifier, y)
    end
    key = nil
    if x > 0 then 
      key = 'wheelleft'
    elseif x < 0 then 
      key = 'wheelright'
    end
    if key ~= nil then
      self.state[id][key] = true
      executeFunction("moved", id, key, self.currentmodifier, x)
    end
end

local button_to_gamepad = {a = 'fdown', y = 'fup', x = 'fleft', b = 'fright', back = 'back', guide = 'guide', start = 'start',
                           leftstick = 'leftstick', rightstick = 'rightstick', leftshoulder = 'l1', rightshoulder = 'r1',
                           dpup = 'dpup', dpdown = 'dpdown', dpleft = 'dpleft', dpright = 'dpright'}
local gamepad_to_button = {fdown = 'a', fup = 'y', fleft = 'x', fright = 'b', back = 'back', guide = 'guide', start = 'start',
                           leftstick = 'leftstick', rightstick = 'rightstick', l1 = 'leftshoulder', r1 = 'rightshoulder',
                           dpup = 'dpup', dpdown = 'dpdown', dpleft = 'dpleft', dpright = 'dpright'}
local button_to_axis = {leftx = 'leftx', lefty = 'lefty', rightx = 'rightx', righty = 'righty', triggerleft = 'l2', triggerright = 'r2'}

function Input:joystickadded(joystick)
  updateJoysticks()
end

function Input:joystickremoved(joystick)
  updateJoysticks()
end

function Input:gamepadpressed(joystick, button)
    local id = self.joysticks_to_ids[joystick:getID()]
    local key = button_to_gamepad[button]
    self.state[id][key] = true
    executeFunction("pressed", id, key, nil)
end

function Input:gamepadreleased(joystick, button)
    local id = self.joysticks_to_ids[joystick:getID()]
    local key = button_to_gamepad[button]
    self.state[id][key] = false
    executeFunction("released", id, key, nil)
end


function Input:gamepadaxis(joystick, axis, value)
    local id = self.joysticks_to_ids[joystick:getID()]
    local key = button_to_axis[axis]
    if self.joystick_axis_values[key] ~= nil and self.joystick_axis_values[key] == value then
      executeFunction("held", id, key, nil, value)
    else
      executeFunction("moved", id, key, nil, value)
    end
    self.joystick_axis_values[key] = value
end

  return setmetatable(Input,{
    __call = function(self,...)
      return self:new(...)
    end
  })
