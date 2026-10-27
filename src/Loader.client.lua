
--[[
    WBUtils Command Bar — Standalone
    Place in a LocalScript in an experience you control.

    Features:
      • Right Shift toggles the command bar
      • Dark translucent command bar
      • Yellow WBUtils prompt
      • Command and argument autocomplete
      • help, echo, radiospam demo
      • Cleans up the previous UI when re-run
]]

local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
if not player then
    warn("[WBUtils] This script must run on the client.")
    return
end

local playerGui = game:GetService("CoreGui")
local GUI_NAME = "WBUtilsCommandBar"

-- Clean up a previous copy of this UI.
local oldGui = playerGui:FindFirstChild(GUI_NAME)
if oldGui then
    oldGui:Destroy()
end

-- Disconnect old script-owned input connections if this script is
-- re-executed in an environment that preserves this table.
_G.WBUtilsCleanup = _G.WBUtilsCleanup or {}
if _G.WBUtilsCleanup.Input then
    _G.WBUtilsCleanup.Input:Disconnect()
    _G.WBUtilsCleanup.Input = nil
end

local Registry = {}

local function register(name, description, args, run)
    Registry[name] = {
        Name = name,
        Description = description,
        Args = args or {},
        Run = run,
    }
end

register("help", "List available commands", {}, function()
    local names = {}
    for name in pairs(Registry) do
        table.insert(names, name)
    end
    table.sort(names)

    print("[WBUtils] Available commands:")
    for _, name in ipairs(names) do
        print("  " .. name .. " — " .. Registry[name].Description)
    end
end)

register("echo", "Print text to the output", {
    {
        Name = "Text",
        Description = "Text to print",
        Options = {},
    },
}, function(args)
    print("[WBUtils] " .. table.concat(args, " "))
end)

register("radiospam", "Use at own risc - insta ban", {}, function()
     while true do 
         local ReplicatedStorage = game:GetService("ReplicatedStorage")
         local Radio = ReplicatedStorage:WaitForChild("Events"):WaitForChild("Radio")

         for i = 1, 1000 do
              Radio:FireServer(tostring(i))
              print("Sent:", i)
              task.wait(1)
         end
        end
end)

-- UI helpers
local function create(className, properties, parent)
    local object = Instance.new(className)
    for key, value in pairs(properties or {}) do
        object[key] = value
    end
    object.Parent = parent
    return object
end

local gui = create("ScreenGui", {
    Name = GUI_NAME,
    ResetOnSpawn = false,
    IgnoreGuiInset = true,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, playerGui)

local bar = create("Frame", {
    Name = "CommandBar",
    AnchorPoint = Vector2.new(0.5, 0),
    Position = UDim2.new(0.5, 0, 0, 90),
    Size = UDim2.new(0.7, 0, 0, 42),
    BackgroundColor3 = Color3.fromRGB(22, 22, 25),
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 10,
}, gui)

create("UICorner", {
    CornerRadius = UDim.new(0, 7),
}, bar)

create("UIStroke", {
    Color = Color3.fromRGB(75, 75, 82),
    Transparency = 0.25,
    Thickness = 1,
}, bar)

local prompt = create("TextLabel", {
    Name = "Prompt",
    Position = UDim2.fromOffset(12, 0),
    Size = UDim2.new(0, 205, 1, 0),
    BackgroundTransparency = 1,
    Font = Enum.Font.Code,
    Text = player.Name .. " @WBUtils@Ollie&",
    TextColor3 = Color3.fromRGB(255, 211, 64),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    ZIndex = 11,
}, bar)

local input = create("TextBox", {
    Name = "Input",
    Position = UDim2.new(0, 220, 0, 0),
    Size = UDim2.new(1, -232, 1, 0),
    BackgroundTransparency = 1,
    ClearTextOnFocus = false,
    Font = Enum.Font.Code,
    PlaceholderText = "<Command Name> <Args>",
    PlaceholderColor3 = Color3.fromRGB(145, 145, 153),
    Text = "",
    TextColor3 = Color3.fromRGB(240, 240, 245),
    TextSize = 15,
    TextXAlignment = Enum.TextXAlignment.Left,
    ZIndex = 11,
}, bar)

local suggestions = create("Frame", {
    Name = "Suggestions",
    Position = UDim2.new(0, 0, 1, 5),
    Size = UDim2.new(1, 0, 0, 0),
    AutomaticSize = Enum.AutomaticSize.Y,
    BackgroundColor3 = Color3.fromRGB(25, 25, 29),
    BackgroundTransparency = 0.05,
    BorderSizePixel = 0,
    Visible = false,
    ZIndex = 20,
}, bar)

create("UICorner", {
    CornerRadius = UDim.new(0, 6),
}, suggestions)

local suggestionLayout = create("UIListLayout", {
    Padding = UDim.new(0, 2),
    SortOrder = Enum.SortOrder.LayoutOrder,
}, suggestions)

create("UIPadding", {
    PaddingTop = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft = UDim.new(0, 5),
    PaddingRight = UDim.new(0, 5),
}, suggestions)

local function clearSuggestions()
    for _, child in ipairs(suggestions:GetChildren()) do
        if child:IsA("TextButton") then
            child:Destroy()
        end
    end
    suggestions.Visible = false
end

local function addSuggestion(title, detail, value, order)
    local button = create("TextButton", {
        Name = "Suggestion",
        LayoutOrder = order,
        Size = UDim2.new(1, 0, 0, 28),
        BackgroundColor3 = Color3.fromRGB(40, 40, 46),
        BackgroundTransparency = 0.15,
        BorderSizePixel = 0,
        AutoButtonColor = true,
        Font = Enum.Font.Code,
        Text = "  " .. title .. "    " .. detail,
        TextColor3 = Color3.fromRGB(225, 225, 232),
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 21,
    }, suggestions)

    create("UICorner", {
        CornerRadius = UDim.new(0, 4),
    }, button)

    button.Activated:Connect(function()
        input.Text = value
        input.CursorPosition = #input.Text + 1
        input:CaptureFocus()
        clearSuggestions()
    end)
end

local function updateSuggestions()
    clearSuggestions()

    local text = input.Text
    local commandPart, remainder = text:match("^%s*(%S*)%s*(.*)$")
    commandPart = commandPart or ""
    remainder = remainder or ""

    local matches = 0

    if remainder == "" then
        local names = {}
        for name in pairs(Registry) do
            if name:sub(1, #commandPart):lower() == commandPart:lower() then
                table.insert(names, name)
            end
        end
        table.sort(names)

        for _, name in ipairs(names) do
            local command = Registry[name]
            addSuggestion(
                name,
                command.Description,
                name .. " ",
                matches + 1
            )
            matches += 1
            if matches >= 6 then
                break
            end
        end
    else
        local command = Registry[commandPart:lower()]
        if command then
            local words = {}
            for word in remainder:gmatch("%S+") do
                table.insert(words, word)
            end

            local argIndex = #words
            local partial = ""
            if remainder:sub(-1) ~= " " then
                partial = words[#words] or ""
                argIndex = math.max(1, #words)
            else
                argIndex = #words + 1
            end

            local argSpec = command.Args[argIndex]
            if argSpec and argSpec.Options then
                for _, option in ipairs(argSpec.Options) do
                    if option:lower():sub(1, #partial) == partial:lower() then
                        local prefix = remainder
                        if partial ~= "" then
                            prefix = remainder:sub(1, #remainder - #partial)
                        end
                        local value = commandPart .. " " .. prefix .. option
                        addSuggestion(option, argSpec.Description or "", value, matches + 1)
                        matches += 1
                        if matches >= 6 then
                            break
                        end
                    end
                end
            end
        end
    end

    suggestions.Visible = matches > 0
end

local function parseArguments(text)
    local result = {}
    for word in text:gmatch("%S+") do
        table.insert(result, word)
    end
    return result
end

local function executeCommand()
    local parts = parseArguments(input.Text)
    local name = table.remove(parts, 1)

    if not name or name == "" then
        return
    end

    local command = Registry[name:lower()]
    if not command then
        warn("[WBUtils] Unknown command: " .. name)
        return
    end

    local ok, err = pcall(command.Run, parts)
    if not ok then
        warn("[WBUtils] Command failed: " .. tostring(err))
    end
end

input:GetPropertyChangedSignal("Text"):Connect(updateSuggestions)

input.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        executeCommand()
        input.Text = ""
    end
    clearSuggestions()
end)

local toggleConnection = UserInputService.InputBegan:Connect(function(key, processed)
    if processed then
        return
    end

    if key.KeyCode == Enum.KeyCode.RightShift then
        bar.Visible = not bar.Visible
        if bar.Visible then
            input:CaptureFocus()
            updateSuggestions()
        else
            input:ReleaseFocus()
            clearSuggestions()
        end
    elseif key.KeyCode == Enum.KeyCode.Escape and bar.Visible then
        bar.Visible = false
        input:ReleaseFocus()
        clearSuggestions()
    end
end)

_G.WBUtilsCleanup.Input = toggleConnection

gui.Destroying:Connect(function()
    if _G.WBUtilsCleanup.Input == toggleConnection then
        toggleConnection:Disconnect()
        _G.WBUtilsCleanup.Input = nil
    end
end)

print("[WBUtils] Loaded. Press Right Shift to open the command bar.")
