
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Destroy the previous UI.
local oldGui = playerGui:FindFirstChild("WBUtilsCommandBar")

if oldGui then
    oldGui:Destroy()
end

-- Clean up the previous instance and its input connections.
if _G.__WBUtilsInstance then
    pcall(function()
        _G.__WBUtilsInstance:Destroy()
    end)

    _G.__WBUtilsInstance = nil
end

local folder = script.Parent

local Registry = require(
    folder:WaitForChild("CommandRegistry")
)

local CommandBar = require(
    folder:WaitForChild("CommandBar")
)

local instance = CommandBar.new(Registry)

_G.__WBUtilsInstance = instance

script.Destroying:Connect(function()
    if _G.__WBUtilsInstance == instance then
        instance:Destroy()
        _G.__WBUtilsInstance = nil
    end
end)

print("[WBUtils] Loaded. Press Right Shift.")
