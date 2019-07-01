--  Declear some default tables

local http = minetest.request_http_api()
assert(http ~= nil, "You need to add vps_blocker to secure.http_mods")

local kick_message = minetest.settings:get("vps_kick_message") or "You are using a proxy, vpn or other hosting services, please disable them to play on this server."
local iphub_key = minetest.settings:get("iphub_key")
local iphub_limit_reached = false

vps_blocker = {}
local cache = {}
local storage = minetest.get_mod_storage()
--[[
cache of ip == nil not checked yet
                 == 1 checked allow
                 == 2 checked deny
]]

--  Add the main ipcheckup function
function vps_blocker.check_ip(name, ip)
  --  First nastyhosts request only if iphub is not used
  if not iphub_key or iphub_limit_reached then
    local req = {
      ["url"] = "http://v1.nastyhosts.com/"..ip
    }
    local callback = function(result)
      local data = minetest.parse_json(result.data)
      if result.completed and result.succeeded and data and data.status == 200 then --  Correct request
        local iphash = minetest.sha1(ip)
        if data.suggestion == "deny" then
          cache[iphash] = 2
        elseif cache[iphash] ~= 2 then
          cache[iphash] = 1
        end
        vps_blocker.handle_player(name, ip)
      else minetest.log("error", "vps_blocker: Incorrect nastyhosts request!")
      end
    end
    http.fetch(req, callback)

  else --  Second may iphub request
    local ireq = {
      ["url"] = "http://v2.api.iphub.info/ip/"..ip,
      ["extra_headers"] = {"X-Key: "..iphub_key}
    }
    local icallback = function(result)
      local data = minetest.parse_json(result.data)
      if result.completed and result.succeeded and data and data.block then --  Correct request
        local iphash = minetest.sha1(ip)
        if data.block == 1 then
          cache[iphash] = 2
        elseif cache[iphash] ~= 2 then
          cache[iphash] = 1
        end
        vps_blocker.handle_player(name, ip)
      else minetest.log("error", "vps_blocker: Incorrect iphub request!")
      end
      if result.code == 429 then --  Iphub request limit reached!
        minetest.log("error", "vps_blocker: IPhub Limit reached! Checking with nastyhosts instead until next restart!")
        iphub_limit_reached = true
      end
    end
    http.fetch(ireq, icallback)
  end
end

--  Add a function which handels what do do(check, kick, nth...)
function vps_blocker.handle_player(name, ip)
  if not ip then
    return
  end
  local iphash = minetest.sha1(ip)
  if not name or not iphash or cache[iphash] == 1 or storage:get_int(name) == 1 then
    return
  end
  if not cache[iphash] then
    vps_blocker.check_ip(name, ip)
  end
  if cache[iphash] == 2 then
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
  params = "<add or remove> <name>",
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
