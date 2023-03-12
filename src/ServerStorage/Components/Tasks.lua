local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local Promise = require(ReplicatedStorage.Packages.Promise)
local Tiles = require(ReplicatedStorage.Modules.Tiles)
local Knit = require(ReplicatedStorage.Packages.Knit)

local Actions = require(ServerStorage.Components.Actions)

local Tasks = {}
local WoodTask = {}

local function readyWorker(worker)
	worker:CancelMovement()
	worker.currentTask.idle = true
	Promise.defer(function()
		worker:taskBuilder()
	end)
end

local baseError = function(playerError, worker, message, time)
	playerError(message)
	worker:TeleportBack(time):andThen(function()
		readyWorker(worker)
	end)
end

local ErrorList = {
	["NOPATH"] = function(playerError, worker)
		playerError("A worker can't find a path!")
		worker.currentTask.idle = true
	end, -- when a path can't be found
	["BLOCKEDPATH"] = function(playerError, worker)
		playerError("A workers path has been blocked!")
		worker:TeleportBack(2):andThen(function()
			readyWorker(worker)
		end)
	end, -- when a path is blocked while the character is moving.
	["NORETURN"] = function(playerError, worker)
		playerError("A worker can't get back!")
		worker:TeleportBack(5):andThen(function()
			readyWorker(worker)
		end)
	end,
	["NOTILE"] = function(playerError, worker)
		worker:TeleportBack(1):andThen(function()
			readyWorker(worker)
		end)
	end,
	["NOTHINGHERE"] = function(playerError, worker)
		baseError(playerError, worker, "A worker just lost their workplace!", 1)
	end
}

local function baseTask(meta, name, worker, tile, slot, moveY, playerError)
	local w = setmetatable({}, meta)
	w.tile = tile
	w.slot = slot or 1
	w.idle = false
	w.name = name

	w.path = {}

	w.promise = Promise.resolve()

	local workerType = Tiles.Main[tile.Name].workPositions.workerType

	w.promise = w.promise
		:andThen(function()
			return Actions.CreatePath(worker, tile)
		end)
		:andThen(function(pathInfo)
			return Actions.GoToChange(worker, workerType, pathInfo)
		end)
		:andThen(function(info)
			if not tile.Parent then
				return Promise.reject("NOTILE")
			end
			return Actions.FollowPath(worker, info[1], tile.entrance:GetPivot().Position, info[2]) -- 1 waypoints and 2 path.blocked event
		end)
		:andThen(function()
			return Actions.PrepareWork(worker, tile, w.slot, moveY)
		end)
		:andThen(function()
			return Actions.Harvest(worker, tile)
		end)
		:andThen(function()
			return Actions.MoveToTileEntrance(worker, tile, moveY)
		end)
		:andThen(function()
			return Actions.CreateReturnPath(worker)
		end)
		:andThen(function(info)
			return Actions.FollowPath(worker, info[1], worker:GetSettlementModel().entrance:GetPivot().Position, info[2])
		end)
		:andThen(function()
			return Actions.Deposit(worker)
		end)
		:andThen(function()
			readyWorker(worker)
		end)
		:catch(function(err)
			if type(err) == "string" and ErrorList[err] then
				ErrorList[err](playerError, worker)
				return
			end

			error(err)
		end)

	return w
end

function WoodTask.new(worker, tile, slot, playerError)
	return baseTask(WoodTask, "WoodTask", worker, tile, slot, false, playerError)
end

Tasks.WoodTask = WoodTask

local FarmingTask = {}

function FarmingTask.new(worker, tile, slot, playerError)
	return baseTask(FarmingTask, "FarmingTask", worker, tile, slot, false, playerError)
end

Tasks.FarmingTask = FarmingTask

local ArchTask = {}

function ArchTask.new(worker, tile, slot, playerError)
	return baseTask(ArchTask, "ArchTask", worker, tile, slot, true, playerError)
end

Tasks.ArchTask = ArchTask

local SmithTask = {}

function SmithTask.new(worker, tile, slot, playerError)
	return baseTask(SmithTask, "SmithTask", worker, tile, slot, false, playerError)
end

Tasks.SmithTask = SmithTask

local IdleTask = {}

function IdleTask.new(worker)
	local w = setmetatable({}, IdleTask)
	w.idle = true

	worker:SnapToIdle()

	return w
end

Tasks.IdleTask = IdleTask

local MiningTask = {}

function MiningTask.new(worker, tile, slot, playerError)
	return baseTask(MiningTask, "MiningTask", worker, tile, slot, true, playerError)
end

Tasks.MiningTask = MiningTask

return Tasks
