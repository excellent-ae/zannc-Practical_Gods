---@meta _

---@diagnostic disable-next-line: undefined-global
local mods = rom.mods

---@diagnostic disable: lowercase-global
---@module 'LuaENVY-ENVY-auto'
mods["LuaENVY-ENVY"].auto()

---@diagnostic disable-next-line: undefined-global
rom = rom
---@diagnostic disable-next-line: undefined-global
_PLUGIN = PLUGIN

game = rom.game

modutil = mods["SGG_Modding-ModUtil"]

chalk = mods["SGG_Modding-Chalk"]
reload = mods["SGG_Modding-ReLoad"]
sjson = mods["SGG_Modding-SJSON"]
gods = mods["zannc-GodsAPI"].auto()

---@module 'Practical_Gods-zannc-config'
config = chalk.auto("config.lua")
public.config = config

import_as_fallback(rom.game)

local function on_ready()
	local package = rom.path.combine(_PLUGIN.plugins_data_mod_folder_path, _PLUGIN.guid)
	modutil.mod.Path.Wrap("SetupMap", function(base)
		LoadPackages({ Name = package })
		base()
	end)

	import("boons/artemisBoons.lua")
	import("boons/hermesBoons.lua")
	import("boons/athenaBoons.lua")
	import("boons/dioBoons.lua")
end

local function on_reload() end

local loader = reload.auto_single()

modutil.once_loaded.game(function()
	mod = modutil.mod.Mod.Register(_PLUGIN.guid)
	loader.load(on_ready, on_reload)
end)
