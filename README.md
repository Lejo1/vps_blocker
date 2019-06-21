# Vps Blocker

This mod checks the ips of the player for vpns, proxys, or other hosting services. These clients will be blocked

It gets the information from nastyhosts.com and iphub.info

Installing
----------

First you need to add vps_blocker to secure.http_mods to allow https  requests.

If you want to use iphub.info(recommend) you need to register there and paste your API key in the minetest config to iphub_key = 123

Set the kick message:

vps_kick_message = "You are using a proxy, vpn or other hosting services, please disable them to play on this server."

Commands
--------

Use /vps_wl (add or remove) (name) to allow people using vps.

License
-------

The idea for the mod is taken from https://github.com/red-001/block_vps but it's a complete redo of it.

Created by [Lejo](https://github.com/Lejo1)
License: MIT
