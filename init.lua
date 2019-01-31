--  Declear some default tables

local http = minetest.request_http_api()
assert(http ~= nil, "You need to add vps_blocker to secure.http_mods")

local kick_message = minetest.settings:get("vps_kick_message") or "You are using a proxy, vpn or other hosting services, please disable them to play on this server."
local iphub_key = minetest.settings:get("iphub_key")

vps_blocker = {}
local storage = minetest.get_mod_storage()
--[[
modstorage of ip == 0 not checked yet
                 == 1 checked allow
                 == 2 checked deny
                 == 3 checking
]]

--  Add the main ipcheckup function
function vps_blocker.check_ip(name, ip)
  --  First nastyhosts request
  storage:set_int(ip, 3)
  local req = {
    ["url"] = "http://v1.nastyhosts.com/"..ip
  }
  local callback = function(result)
    local data = minetest.parse_json(result.data)
    if result.completed and result.succeeded and data and data.status == 200 then --  Correct request
      if data.suggestion == "deny" then
        storage:set_int(ip, 2)
      elseif storage:get_int(ip) ~= 2 then
        storage:set_int(ip, 1)
      end
      vps_blocker.handle_player(name, ip)
    else minetest.log("error", "vps_blocker: Incorrect request!")
    end
  end
  http.fetch(req, callback)
  --  Second may iphub request
  if iphub_key then
    local ireq = {
      ["url"] = "http://v2.api.iphub.info/ip/"..ip,
      ["extra_headers"] = {"X-Key: "..iphub_key}
    }
    local icallback = function(result)
      local data = minetest.parse_json(result.data)
      if result.completed and result.succeeded and data and data.block then --  Correct request
        if data.block == 1 then
          storage:set_int(ip, 2)
        elseif storage:get_int(ip) ~= 2 then
          storage:set_int(ip, 1)
        end
        vps_blocker.handle_player(name, ip)
      else minetest.log("error", "vps_blocker: Incorrect request!")
      end
    end
    http.fetch(ireq, icallback)
  end
end

--  Add a function which handels what do do(check, kick, nth...)
function vps_blocker.handle_player(name, ip)
  if not name or not ip or storage:get_int(ip) == 1 or storage:get_int(name) == 1 then
    return
  end
  if storage:get_int(ip) == 0 then
    vps_blocker.check_ip(name, ip)
  end
  if storage:get_int(ip) == 2 then
    local player = minetest.get_player_by_name(name)
    if player then
      minetest.kick_player(name, kick_message)
    else return kick_message
    end
  end
end

--  Do handle_player on prejoin and norma join
minetest.register_on_prejoinplayer(vps_blocker.handle_player)
minetest.register_on_joinplayer(function(player)
  local name = player:get_player_name()
  local ip = minetest.get_player_ip(name)
  vps_blocker.handle_player(name, ip)
end)

--  Add a command to whitelist players
minetest.register_chatcommand("vps_wl", {
  description = "Allow a player to use vps services.",
  params = "<add or remove> <name or ip>",
  privs = {server=true},
  func = function(name, params)
    local p = string.split(params, " ")
    if p[1] == "add" then
      storage:set_int(p[2], 1)
      return true, "Added "..p[2].." to the whitelist."
    elseif p[1] == "remove" then
      storage:set_int(p[2], 0)
      return true, "Removed "..p[2].." from the whitelist."
    else return false, "Invalid Input"
    end
  end
})
