
require 'nixio'

function urldecode( str, no_plus )

 local function __chrdec( hex )
  return string.char( tonumber( hex, 16 ) )
 end

 if type(str) == "string" then
  if not no_plus then
   str = str:gsub( "+", " " )
  end

  str = str:gsub( "%%([a-fA-F0-9][a-fA-F0-9])", __chrdec )
 end

 return str
end

function urldecode_params(url, tbl)

 local params = tbl or { }

 if url:find("?") then
  url = url:gsub( "^.+%?([^?]+)", "%1" )
 end

 for pair in url:gmatch( "[^&;]+" ) do

  -- find key and value
  local key = urldecode( pair:match("^([^=]+)")     )
  local val = urldecode( pair:match("^[^=]+=(.+)$") )

  -- store
  if type(key) == "string" and key:len() > 0 then
   if type(val) ~= "string" then val = "" end

   if not params[key] then

    params[key] = val
   elseif type(params[key]) ~= "table" then
    params[key] = { params[key], val }
   else
    table.insert( params[key], val )
   end
  end
 end

 return params
end


function get_post_data(env)
    if env == nil or env.CONTENT_LENGTH == nil or type(env.CONTENT_LENGTH) ~= "string" then
       return {}
    end

    local len = tonumber(env.CONTENT_LENGTH)
    if len == nil or len <= 0 then
        return {}
    end
    return urldecode_params(io.read(len))
end

html_begin = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <title>Monitor Panel</title>
        <meta http-equiv="refresh" content="1" / >
    </head>
    <body>
]]

panel_form01 = [[
    <form action="pMonitor.lua" method="post">
        <img src="pMonitor/panel.png" width="520" height="370" border="0" />

        <div style="position: absolute; left: 153px; top: 117px;">
          <button type="submit" name="DOOR" value="OPEN"><img src="pMonitor/dButton.png" width="50" height="17"></button>
        </div>
        <div style="position: absolute; left: 222px; top: 117px;">
          <button type="submit" name="GATE" value="UP"><img src="pMonitor/gButtonUp.png" width="17" height="17"></button>
        </div>
        <div style="position: absolute; left: 258px; top: 117px;">
          <button type="submit" name="GATE" value="DOWN"><img src="pMonitor/gButtonDown.png" width="17" height="17"></button>
        </div>
]]

panel_door = [[
      <div style="position: absolute; left: 8px; top: 85px;">
            <img src="pMonitor/dOpen.png" width="90" height="90">
      </div>
]]

panel_gate = [[
        <div style="position: absolute; left: 335px; top: 135px;">
            <img src="pMonitor/Gate.png" width="190" height="10">
      </div>
]]

panel_car = [[
        <div style="position: absolute; left: 360px; top: 30px;">
            <img src="pMonitor/car.png" width="70" height="100">
      </div>
]]
panel_guest = [[
        <div style="position: absolute; left: 20px; top: 30px;">
            <img src="pMonitor/people.png" width="50" height="60">
      </div>
]]

panel_form_image =[[
      <div style="position: absolute; left: 26px; top: 205px;">
        <img src="http://192.168.43.183:8080/?action=stream" width="220" height="165">
      </div>
      <div style="position: absolute; left: 295px; top: 205px;">
        <img src="http://192.168.43.163:8080/?action=stream" width="220" height="165">
      </div>
]]

panel_form_last = [[
      </form>
]]

html_end = [[
    </body>
</html>
]]

local env = nixio.getenv()
local post_data = get_post_data(env)
local statusString = "door:C,gate:D,car:N,guest:A"
----------------------123456789012345678901234567
local serialREAD = io.open("/dev/ttyS0","r")
local serialWRITE = io.open("/dev/ttyS0","w")
os.execute("stty -F /dev/ttyS0 57600")

serialWRITE:write("#")
serialWRITE:flush()
statusString  = serialREAD:read()
serialREAD:flush()

io.write("Content-Type: text/html\r\n\r\n")
io.write(html_begin)
io.write(panel_form01)
io.write(panel_form_last)

-- print( statusString)
-- print(post_data.GATE)
-- print(post_data.DOOR)

if string.sub( statusString, 6,6) == "O" then
     io.write(panel_door)
end
if string.sub( statusString, 13,13) == "D" then
     io.write(panel_gate)
end
if string.sub( statusString, 19,19) == "Y" then
     io.write(panel_car)
end
if string.sub( statusString, 27,27) == "P" then
     io.write(panel_guest)
end

io.write(panel_form_image)

if post_data.GATE == "UP" then
    serialWRITE:write("2")
elseif post_data.GATE == "DOWN" then
    serialWRITE:write("3")
    io.write(panel_gate)
end
if post_data.DOOR == "OPEN" then
    serialWRITE:write("1")
    io.write(panel_door)
end

io.write(html_end)

serialWRITE:flush()
serialWRITE:close()
serialREAD:close()
