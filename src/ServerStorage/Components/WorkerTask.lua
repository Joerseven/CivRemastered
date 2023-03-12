local WorkerTask = {}

function WorkerTask.new()
    local w = setmetatable({}, WorkerTask)

    -- Number : The amount of weight the task should have.
    w.Value = 1
    -- Actions : The actions that this task would use.
    w.Actions = {}

    return w
end

return WorkerTask