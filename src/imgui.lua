---@meta _
---@diagnostic disable

-- local function drawMenu()
-- 	local value, checked
-- 	local currentConfig = {
-- 		ArtemisAttackCritScale = config.ArtemisAttackCritScale,
-- 		ArtemisSpecialCritScale = config.ArtemisSpecialCritScale,
-- 	}

-- 	value, checked = rom.ImGui.Checkbox("Artemis Critical Attack Scaling", config.ArtemisAttackCritScale)
-- 	if checked then
-- 		config.ArtemisAttackCritScale = value
-- 	end

-- 	value, checked = rom.ImGui.Checkbox("Artemis Critical Special Scaling", config.ArtemisSpecialCritScale)
-- 	if checked then
-- 		config.ArtemisSpecialCritScale = value
-- 	end

-- 	if config.ArtemisAttackCritScale ~= currentConfig.ArtemisAttackCritScale or config.ArtemisSpecialCritScale ~= currentConfig.ArtemisSpecialCritScale then
-- 		print("Configuration changed, updating Artemis Boon")
-- 		currentConfig.ArtemisAttackCritScale = config.ArtemisAttackCritScale
-- 		currentConfig.ArtemisSpecialCritScale = config.ArtemisSpecialCritScale
-- 		ConfigureArtemisBoon(config.ArtemisAttackCritScale, config.ArtemisSpecialCritScale)
-- 	end
-- end

-- -- standalone
-- rom.gui.add_imgui(function()
-- 	if rom.ImGui.Begin("Practical Gods") then
-- 		drawMenu()
-- 		rom.ImGui.End()
-- 	end
-- end)

-- -- dropdown
-- rom.gui.add_to_menu_bar(function()
-- 	if rom.ImGui.BeginMenu("Configure") then
-- 		drawMenu()
-- 		rom.ImGui.EndMenu()
-- 	end
-- end)
