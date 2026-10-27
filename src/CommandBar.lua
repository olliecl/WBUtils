
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")

local CommandBar = {}
CommandBar.__index = CommandBar

local COLORS = {
    Background = Color3.fromRGB(38, 42, 46),
    Header = Color3.fromRGB(56, 61, 66),
    Row = Color3.fromRGB(68, 74, 80),
    Selected = Color3.fromRGB(85, 95, 103),
    Yellow = Color3.fromRGB(255, 220, 65),
    White = Color3.fromRGB(245, 245, 245),
    Muted = Color3.fromRGB(190, 195, 200),
}

local GUI_NAME = "WBUtilsCommandBar"

local function create(class, properties, parent)
    local obj = Instance.new(class)

    for key, value in pairs(properties) do
        obj[key] = value
    end

    obj.Parent = parent
    return obj
end

function CommandBar.new(registry)
    local self = setmetatable({}, CommandBar)

    self.Registry = registry
    self.Player = Players.LocalPlayer
    self.Connections = {}
    self.Opened = false
    self.SelectedIndex = 1
    self.Suggestions = {}

    self:Build()

    return self
end

function CommandBar:Connect(signal, callback)
    local connection = signal:Connect(callback)
    table.insert(self.Connections, connection)
    return connection
end

function CommandBar:Build()
    local playerGui = self.Player:WaitForChild("PlayerGui")

    -- Remove an old UI before building a replacement.
    local previous = playerGui:FindFirstChild(GUI_NAME)
    if previous then
        previous:Destroy()
    end

    local gui = create("ScreenGui", {
        Name = GUI_NAME,
        ResetOnSpawn = false,
        DisplayOrder = 100,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
    }, playerGui)

    self.Gui = gui

    local main = create("Frame", {
        Name = "Main",
        Position = UDim2.fromOffset(5, 14),
        Size = UDim2.fromOffset(417, 40),
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.06,
        BorderSizePixel = 0,
        Visible = false,
    }, gui)

    self.Main = main

    self.Prompt = create("TextLabel", {
        Name = "Prompt",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(0, 0, 1, 0),
        AutomaticSize = Enum.AutomaticSize.X,
        BackgroundTransparency = 1,
        Text = self.Player.Name .. " @WBUtils@Ollie& ",
        TextColor3 = COLORS.Yellow,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, main)

    self.Input = create("TextBox", {
        Name = "CommandInput",
        Position = UDim2.fromOffset(10, 0),
        Size = UDim2.new(1, -20, 1, 0),
        BackgroundTransparency = 1,
        Text = "",
        PlaceholderText = "<Command Name> <Args>",
        PlaceholderColor3 = COLORS.Muted,
        TextColor3 = COLORS.White,
        TextSize = 12,
        Font = Enum.Font.Code,
        TextXAlignment = Enum.TextXAlignment.Left,
        ClearTextOnFocus = false,
        MultiLine = false,
    }, main)

    local function positionInput()
        local offset = self.Prompt.TextBounds.X + 12
        self.Input.Position = UDim2.fromOffset(offset, 0)
        self.Input.Size = UDim2.new(1, -offset - 8, 1, 0)
    end

    positionInput()

    self:Connect(
        self.Prompt:GetPropertyChangedSignal("TextBounds"),
        positionInput
    )

    self.Dropdown = create("Frame", {
        Name = "Autocomplete",
        Position = UDim2.new(0, 217, 0, 40),
        Size = UDim2.fromOffset(300, 0),
        BackgroundColor3 = COLORS.Background,
        BackgroundTransparency = 0.04,
        BorderSizePixel = 0,
        Visible = false,
        ClipsDescendants = true,
    }, main)

    self:Connect(
        self.Input:GetPropertyChangedSignal("Text"),
        function()
            self:Refresh()
        end
    )

    self:Connect(self.Input.FocusLost, function(enterPressed)
        if enterPressed then
            self:Execute()
        end
    end)

    self:Connect(UIS.InputBegan, function(input, processed)
        if input.KeyCode == Enum.KeyCode.RightShift then
            self:SetOpen(not self.Opened)
            return
        end

        if processed or not self.Opened then
            return
        end

        if not self.Input:IsFocused() then
            return
        end

        if input.KeyCode == Enum.KeyCode.Tab then
            self:Complete(self.Suggestions[self.SelectedIndex])

        elseif input.KeyCode == Enum.KeyCode.Down then
            self.SelectedIndex = math.min(
                self.SelectedIndex + 1,
                math.max(#self.Suggestions, 1)
            )
            self:Refresh()

        elseif input.KeyCode == Enum.KeyCode.Up then
            self.SelectedIndex = math.max(
                self.SelectedIndex - 1,
                1
            )
            self:Refresh()
        end
    end)

    self:Refresh()
end

function CommandBar:SetOpen(value)
    self.Opened = value
    self.Main.Visible = value

    if value then
        self:Refresh()
        self.Input:CaptureFocus()
    else
        self.Input:ReleaseFocus()
    end
end

function CommandBar:GetSuggestions()
    local text = self.Input.Text
    local parts = string.split(text, " ")
    local trailingSpace = text:sub(-1) == " "
    local commandName = parts[1] or ""
    local command = self.Registry:Get(commandName)

    -- Suggest command names.
    if not command then
        local results = {}

        for _, item in ipairs(self.Registry.Commands) do
            if string.sub(
                string.lower(item.Name),
                1,
                #commandName
            ) == string.lower(commandName) then
                table.insert(results, {
                    Name = item.Name,
                    Description = item.Description or "Command",
                    IsCommand = true,
                })
            end
        end

        return results
    end

    -- Suggest the current argument.
    local argIndex = #parts

    if trailingSpace then
        argIndex += 1
    end

    local options = command.Args
        and command.Args[argIndex - 1]

    if not options then
        return {{
            Name = command.Name,
            Description = command.Description or "Command",
            IsCommand = true,
        }}
    end

    local current = trailingSpace and "" or (parts[#parts] or "")
    local results = {}

    for _, option in ipairs(options) do
        local name = type(option) == "table"
            and option.Name or option

        local description = type(option) == "table"
            and option.Description or "Argument"

        if string.sub(string.lower(name), 1, #current)
            == string.lower(current) then
            table.insert(results, {
                Name = name,
                Description = description,
                IsCommand = false,
            })
        end
    end

    return results
end

function CommandBar:Complete(item)
    if not item then
        return
    end

    if item.IsCommand then
        self.Input.Text = item.Name

        local command = self.Registry:Get(item.Name)

        if command and command.Args and #command.Args > 0 then
            self.Input.Text ..= " "
        end
    else
        local text = self.Input.Text

        if text:sub(-1) == " " then
            self.Input.Text = text .. item.Name
        else
            local parts = string.split(text, " ")
            parts[#parts] = item.Name
            self.Input.Text = table.concat(parts, " ")
        end
    end

    self.Input.CursorPosition = #self.Input.Text + 1
    self.Input:CaptureFocus()
    self:Refresh()
end

function CommandBar:Refresh()
    if not self.Input or not self.Dropdown then
        return
    end

    self.Suggestions = self:GetSuggestions()

    local count = math.min(#self.Suggestions, 8)

    self.SelectedIndex = math.clamp(
        self.SelectedIndex,
        1,
        math.max(count, 1)
    )

    for _, child in ipairs(self.Dropdown:GetChildren()) do
        if child:IsA("Frame") then
            child:Destroy()
        end
    end

    self.Dropdown.Visible = self.Opened and count > 0
    self.Dropdown.Size = UDim2.fromOffset(300, count * 30)

    for index = 1, count do
        local item = self.Suggestions[index]

        local row = create("Frame", {
            Name = "Suggestion" .. index,
            Position = UDim2.fromOffset(0, (index - 1) * 30),
            Size = UDim2.new(1, 0, 0, 30),
            BackgroundColor3 = index == self.SelectedIndex
                and COLORS.Selected or COLORS.Row,
            BorderSizePixel = 0,
        }, self.Dropdown)

        local button = create("TextButton", {
            Size = UDim2.fromScale(1, 1),
            BackgroundTransparency = 1,
            Text = "",
            AutoButtonColor = false,
        }, row)

        self:Connect(button.Activated, function()
            self:Complete(item)
        end)

        create("TextLabel", {
            Position = UDim2.fromOffset(10, 0),
            Size = UDim2.new(0.42, 0, 1, 0),
            BackgroundTransparency = 1,
            Text = item.Name,
            TextColor3 = COLORS.White,
            TextSize = 12,
            Font = Enum.Font.Code,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)

        create("TextLabel", {
            Position = UDim2.new(0.42, 0, 0, 0),
            Size = UDim2.new(0.58, -8, 1, 0),
            BackgroundTransparency = 1,
            Text = item.Description,
            TextColor3 = COLORS.Muted,
            TextSize = 11,
            Font = Enum.Font.Code,
            TextTruncate = Enum.TextTruncate.AtEnd,
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
    end
end

function CommandBar:Execute()
    local parts = string.split(self.Input.Text, " ")
    local name = table.remove(parts, 1)
    local command = self.Registry:Get(name)

    if command then
        local ok, err = pcall(
            command.Run,
            parts,
            {
                Registry = self.Registry,
                Player = self.Player,
            }
        )

        if not ok then
            warn("[WBUtils] Command error:", err)
        end
    elseif name and name ~= "" then
        warn("[WBUtils] Unknown command:", name)
    end

    self.Input.Text = ""
    self:Refresh()

    if self.Opened then
        self.Input:CaptureFocus()
    end
end

function CommandBar:Destroy()
    self.Opened = false

    for _, connection in ipairs(self.Connections) do
        pcall(function()
            connection:Disconnect()
        end)
    end

    table.clear(self.Connections)

    if self.Gui then
        self.Gui:Destroy()
        self.Gui = nil
    end
end

return CommandBar
