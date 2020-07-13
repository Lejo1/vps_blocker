--  Default proxy and vpn checker websites
--  The best checker should be the first registered!

--  Iphub.info

local iphub_key = minetest.settings:get("iphub_key")
if iphub_key then
  local check = {}
  function check.getreq(ip)
    local req = {
      ["url"] = "http://v2.api.iphub.info/ip/"..ip,
      ["extra_headers"] = {"X-Key: "..iphub_key}
    }
    local callback = function(result)
      if result.code == 429 then --  Iphub request limit reached!
        check.active = false
        return nil, "IPhub Limit reached!"
      end
      local data = minetest.parse_json(result.data)
      if result.completed and result.succeeded and data and data.block then --  Correct request
        if data.block == 1 then
          return false
        else return true
        end
      else return nil, "Incorrect iphub request!"
      end
    end
    return req, callback
  end

  vps_blocker.register_checker(check)
end

--  Getipintel.net

local contact = minetest.settings:get("getipintel_contact")
if contact then
  local check = {}
  function check.getreq(ip)
    local req = {
      ["url"] = "https://check.getipintel.net/check.php?contact="..contact.."&ip="..ip
    }
    local callback = function(result)
      if result.code == 429 then --  Iphub request limit reached!
        check.active = false
        return nil, "Getipintel Limit reached!"
      end
      local data = tonumber(result.data)
      if result.completed and result.succeeded and result.code == 200 and data then --  Correct request
        if data > 0.99 then
          return false
        else return true
        end
      else return nil, "Incorrect getipintel request!"
      end
    end
    return req, callback
  end

  vps_blocker.register_checker(check)
end

--  Proxycheck.io

do
  local proxycheck_key = minetest.settings:get("proxycheck_key")
  local check = {}
  function check.getreq(ip)
    local req = {
      ["url"] = "http://proxycheck.io/v2/"..ip.."?vpn=1"
    }
    if proxycheck_key then
      req.url = req.url.."&key="..proxycheck_key
    end
    local callback = function(result)
      local data = minetest.parse_json(result.data)
      if result.completed and result.succeeded and data then --  Correct request
        if data.status == "ok" or data.status == "warning" and data[ip] and data[ip].proxy then
          if data[ip].proxy == "yes" then
            return false
          else return true
          end
        elseif data.status == "denied" and string.find(data.message, "exhausted") then
          check.active = false
          return nil, "Proxycheck Limit reached!"
        else return nil, (data.status or "error") .. ": "..(data.message or "Bad request-result!")
        end
      else return nil, "Incorrect iphub request!"
      end
    end
    return req, callback
  end

  vps_blocker.register_checker(check)
end
