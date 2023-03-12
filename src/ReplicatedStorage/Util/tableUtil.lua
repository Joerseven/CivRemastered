local tableUtil = {}

function tableUtil.swapKeyValue(tab)
	local newTable = {}

	for i, v in ipairs(tab) do
		newTable[v] = i
	end

	return newTable
end

function tableUtil.hasIndex(tab, ind)
	for index, value in pairs(tab) do
		if index == ind then
			return true
		end
	end

	return false
end

function tableUtil.hasValue(tab, val)
	for index, value in pairs(tab) do
		if value == val then
			return index
		end
	end

	return false
end

function tableUtil.arrayRemove(t, index)
    local j, n = 1, #t;

    for i=1,n do
        if (i ~= index) then
            -- Move i's kept value to j's position, if it's not already there.
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

function tableUtil.removeIf(t, fnKeep)
    local j, n = 1, #t;

    for i=1,n do
        if (fnKeep(t, i, j)) then
            if (i ~= j) then
                t[j] = t[i];
                t[i] = nil;
            end
            j = j + 1; -- Increment position of where we'll place the next kept value.
        else
            t[i] = nil;
        end
    end

    return t;
end

function tableUtil.Set(tab)
	local set = {}
	for _, value in pairs(tab) do
		set[value] = true
	end
	return set
end

return tableUtil