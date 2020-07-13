# Vps Blocker

This mod checks the ips of the player for vpns, proxys, or other hosting services. These clients will be blocked  
It gets the information from proxy-check websites like iphub.info

Installing
----------

First you need to add vps_blocker to secure.http_mods to allow http requests.

Set the kick message:  
vps_kick_message = "You are using a proxy, vpn or other hosting services, please disable them to play on this server."

Commands
--------

Use /vps_wl (add or remove) (name) to allow people using vps.

Checkers
--------

Paste the keys to the minetest.conf

###### iphub.info

To use iphub.info you need to register there(recommend)  
You get 1000 requests/day for free  
iphub_key = 123

###### getipintel.net

You must set an own contact email for getipintel.net  
Please first go to the webpage and read what it's used for!  
getipintel_contact = example@example.com

###### proxycheck.io

For a higher request limit 1000 instead of 100 requests and dashboard register at there webpage
proxycheck_key = 1-2-3-4

License
-------

The idea for the mod is taken from https://github.com/red-001/block_vps but it's a complete redo of it.

Created by [Lejo](https://github.com/Lejo1)
License: MIT
