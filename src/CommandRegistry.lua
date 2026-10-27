
local Registry = {}

Registry.Commands = {
    {
        Name = "help",
        Description = "List all available commands",
        Args = {},
        Run = function(args, context)
            for _, command in ipairs(context.Registry.Commands) do
                print(command.Name .. " - " .. command.Description)
            end
        end,
    },

    {
        Name = "echo",
        Description = "Print a message",
        Args = {},
        Run = function(args)
            print("[WBUtils]", table.concat(args, " "))
        end,
    },
}

function Registry:Get(name)
    name = string.lower(name or "")

    for _, command in ipairs(self.Commands) do
        if string.lower(command.Name) == name then
            return command
        end
    end

    return nil
end

function Registry:Add(command)
    assert(type(command) == "table", "Expected command table")
    assert(type(command.Name) == "string", "Command needs a name")
    assert(type(command.Run) == "function", "Command needs a Run callback")
    assert(not self:Get(command.Name), "Command already exists")

    table.insert(self.Commands, command)
end

return Registry
