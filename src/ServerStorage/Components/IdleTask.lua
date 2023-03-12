local IdleTask = {}

function IdleTask.new()
	local t = setmetatable({
        Value = 0,
        Actions = {
            
        },
    }, IdleTask)
	return t
end

return IdleTask
