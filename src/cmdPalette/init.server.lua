local modules = script:WaitForChild("modules")
local loader = script.Parent:FindFirstChild("LoaderUtils", true).Parent

local require = require(loader).bootstrapPlugin(modules)

local CoreGui = game:GetService("CoreGui")
local Selection = game:GetService("Selection")

local CommandPalette = require("CommandPalette")
local CommandPaletteConstants = require("CommandPaletteConstants")
local Maid = require("Maid")

local currentPalette

local function renderPalette(targetInstance)
	local maid = Maid.new()

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "CommandPalette"
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = CoreGui
	maid:GiveTask(screenGui)

	local cmdPalette = CommandPalette.new(targetInstance)
	maid:GiveTask(cmdPalette)

	maid:GiveTask(cmdPalette:Render({
		Parent = screenGui;
	}):Subscribe(function()
		cmdPalette:SetInputFocused(true)
	end))

	cmdPalette:Show()

	return maid, cmdPalette
end

local function cleanup(maid, palette)
	if not palette then
		return
	end

	currentPalette = nil

	palette:Hide()

	task.delay(0.3, function()
		maid:Destroy()
	end)
end

local function initialize(plugin)
	local maid = Maid.new()

	local macro = plugin:CreatePluginAction(
		"[Command Palette] Open",
		"[Command Palette] Open",
		"Open the Command Palette on the currently selected instance.",
		CommandPaletteConstants.PLUGIN_ICON,
		true
	)

	maid:GiveTask(macro.Triggered:Connect(function()
		if currentPalette then
			cleanup(currentPalette)
		else
			local selection = Selection:Get()
			if not selection then
				print("[CommandPalette] Please select an instance!")
				return
			end

			local paletteMaid, palette = renderPalette(selection[1])

			currentPalette = palette
			maid._current = paletteMaid

			paletteMaid:GiveTask(palette.EscapePressed:Connect(function()
				cleanup(paletteMaid, palette)
			end))
		end
	end))

	maid:GiveTask(plugin.Unloading:Connect(function()
		maid:Destroy()
	end))

	return maid
end

if plugin then
	initialize(plugin)
end