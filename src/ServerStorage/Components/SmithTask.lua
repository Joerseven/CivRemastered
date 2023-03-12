local SmithTask = {}

function SmithTask.new()
    local w = setmetatable({}, SmithTask)

    print("Hi! Smith task has fired.")

    return w
end

return SmithTask