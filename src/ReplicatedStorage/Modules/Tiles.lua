local function reverseTable(tab)
	local ntab = {}
	for i, v in pairs(tab) do
		ntab[v.name] = i
	end
	return ntab
end

local Tiles = {}

Tiles.Main = {
	{ name = "Grass", service = "TileService", grow = "Forest", canSettle = true, path = true },
	{ name = "Sand", service = "TileService", grow = "PalmSand", canSettle = true, path = true },
	{
		name = "Desert",
		service = "TileService",
		grow = "CactusDesert",
		raise = "DesertRuins",
		canSettle = true,
		path = true,
	},
	{
		name = "Snow",
		service = "TileService",
		grow = "SnowForest",
		raise = "SnowMountain",
		canSettle = true,
		path = true,
	},
	{ name = "Stone", service = "TileService", raise = "Mountain", canSettle = true, path = true },
	{ name = "Farmland", service = "TileService", grow = "Farm", path = true },
	{ name = "CactusDesert", service = "GrowTileService", grow = "DesertForest"},
	{ name = "DesertRuins", service = "RaiseTileService", work = "DesertRuinsClaimed" },
	{
		name = "DesertRuinsClaimed",
		service = "WorkedTileService",
		task = "ArchTask",
		workPositions = {
			workerType = "WorkerArch",
			pOffset = {
				Vector3.new(0.8297319412231445, 1.3179600238800049, 0.617156982421875),
				Vector3.new(-0.8868560791015625, 0.5380682945251465, -1.0492401123046875),
			},
			aOffset = {
				{ 0, 0, 0 },
				{ 0, 0, 0 },
			},
		},
	},
	{ name = "Farm", service = "GrowTileService", work = "FarmClaimed", path = true },
	{
		name = "FarmClaimed",
		service = "WorkedTileService",
		task = "FarmTask",
		workPositions = {
			workerType = "WorkerFarm",
			pOffset = {
				Vector3.new(-0.791022789478302, 0.4, 0.7904281616210938),
				Vector3.new(0.4199025630950928, 0.4, -0.7922630310058594),
			},
			aOffset = {
				{ 0, 0, 0 },
				{ 0, 0, 0 },
			},
		},
	},
	{ name = "Forest", service = "GrowTileService", work = "ForestClaimed" },
	{
		name = "ForestClaimed",
		service = "WorkedTileService",
		task = "WoodTask",
		workPositions = {
			workerType = "WorkerAxe",
			pOffset = {
				Vector3.new(0.78680095672607422, 0.4, 1.635516357421875),
				Vector3.new(-0.38680095672607422, 0.4, 0.435516357421875),
			},
			aOffset = {
				{ 0, 0, 0 },
				{ 0, math.rad(180), 0 },
			},
		},
	},
	{ name = "Mountain", raise = "Volcano", service = "RaiseTileService", work = "MountainClaimed" },
	{
		name = "MountainClaimed",
		service = "WorkedTileService",
		task = "MiningTask",
		workPositions = {
			workerType = "WorkerPick",
			pOffset = {
				Vector3.new(-1.3919496536254883, 0.4, 0.14594268798828125),
				Vector3.new(1.3919496536254883, 0.4, -1.3919496536254883),
			},
			aOffset = {
				{ math.rad(60), 0, 0 },
				{ math.rad(35), 0, 0 },
			},
		},
	},
	{ name = "PalmSand", service = "GrowTileService", work = "PalmSandClaimed" },
	{
		name = "PalmSandClaimed",
		service = "WorkedTileService",
		task = "WoodTask",
		workPositions = {
			workerType = "WorkerAxe",
			pOffset = {
				Vector3.new(1.1544685363769531, 0.42253825068473816, -1.1764564514160156),
				Vector3.new(-1.4060649871826172, 0.45824313163757324, -0.9404144287109375),
			},
			aOffset = {
				{ 0, 0, 0 },
				{ 0, 0, 0 },
			},
		},
	},
	{ -- print(workspace.Workspace6.SettlementLV1.Workers.WorkerIdle:GetPivot():ToObjectSpace(workspace.Workspace6.SettlementLV1:GetPivot()).Position)
		name = "SettlementLV1",
		service = "SettlementService",
		idlePositions = {
			pOffset = {
				Vector3.new(0.75, 0, 0.75),
			},
			aOffset = {
				{ 0, math.rad(180), 0 },
			},
			path = {
				{
					Vector3.new(0.75, 0, -1.02392578125),
					Vector3.new(0.00701904296875, 0, -1.02392578125),
					Vector3.new(0.00701904296875, 0, -0.1575927734375),
				},
			},
		},
		capacity = 1,

		xpNext = 64,
	},
	{
		name = "SettlementLV2",
		service = "SettlementService",
		idlePositions = {
			pOffset = {
				Vector3.new(0.3, 0, 0.9),
				Vector3.new(-0.4, 0, -0),
			},
			aOffset = {
				{ 0, math.rad(180), 0 },
				{ 0, math.rad(180), 0 },
			},
		},
		capacity = 2,
		xpNext = 128,
	},
	{
		name = "SettlementLV3",
		service = "SettlementService",
		idlePositions = {
			pOffset = {
				Vector3.new(1.1104736328125, 0, -0.8346786499023438),
				Vector3.new(-1.3, 0, -0.65),
				Vector3.new(-0.0865631103515625, 0, -0.24002838134765625),
			},
			aOffset = {
				{ 0, math.rad(180), 0 },
				{ 0, 0, 0 },
				{ 0, math.rad(180), 0 },
			},
		},
		capacity = 3,
		xpNext = 256,
	},
	{ name = "SnowForest", service = "GrowTileService", work = "SnowForestClaimed" },
	{
		name = "SnowForestClaimed",
		service = "WorkedTileService",
		task = "WoodTask",
		workPositions = {
			workerType = "WorkerAxe",
			pOffset = {
				Vector3.new(0.8183584213256836, 0.5080760717391968, 1.2220897674560547),
				Vector3.new(1.3189659118652344, 0.6147733926773071, -1.3869438171386719),
			},
			aOffset = {
				{ 0, 0, 0 },
				{ 0, 0, 0 },
			},
		},
	},
	{ name = "SnowMountain", service = "RaiseTileService", work = "SnowMountainClaimed" },
	{
		name = "SnowMountainClaimed",
		service = "WorkedTileService",
		task = "MiningTask",
		workPositions = {
			workerType = "WorkerPick",
			pOffset = {
				Vector3.new(-1.3919496536254883, 0.4, 0.14594268798828125),
				Vector3.new(1.3919496536254883, 0.4, -1.3919496536254883),
			},
			aOffset = {
				{ math.rad(60), 0, 0 },
				{ math.rad(35), 0, 0 },
			},
		},
	},
	{ name = "Volcano", service = "RaiseTileService", work = "VolcanoClaimed" },
	{
		name = "VolcanoClaimed",
		service = "WorkedTileService",
		task = "SmithTask",
		workPositions = {
			workerType = "WorkerSmith",
			pOffset = {
				Vector3.new(0.507535934, 0.577667236, 1.49374008),
				Vector3.new(1.38934994, 0.573547363, 0.983337402),
			},
			aOffset = {
				{ 0, -0.698131799697876, 0 },
				{ 0, 1.3089969158172607, 0 },
			},
		},
	},
	{
		name = "SettlementLV4",
		service = "SettlementService",
		idlePositions = {
			pOffset = {
				Vector3.new(1.2578182220458984, 0, -0.17272186279296875),
				Vector3.new(-1.443382740020752, 0, 0.01526641845703125),
				Vector3.new(0.8666377067565918, 1.51, 1.3299789428710938),
				Vector3.new(-0.3000001907348633, 0, -0.3000030517578125),
			},
			aOffset = {
				{ 0, math.rad(180), 0 },
				{ 0, 0, 0 },
				{ 0, math.rad(180), 0 },
				{ 0, math.rad(180), 0 },
			},
		},
		capacity = 4,
		xpNext = 512,
	},
	{
		name = "SettlementLV5",
		service = "SettlementService",
		idlePositions = {
			pOffset = {
				Vector3.new(0.4895625114440918, 1.4746825695037842, 0.2723731994628906),
				Vector3.new(-0.024521827697753906, 0, 1.0382766723632812),
				Vector3.new(0.7297892570495605, 0, -0.9290237426757812),
				Vector3.new(1.1829757690429688, 1.5897053480148315, -1.3735885620117188),
				Vector3.new(-0.5518927574157715, 0, -0.5445671081542969),
			},
			aOffset = {
				{ 0, math.rad(0), 0 },
				{ 0, 0, 0 },
				{ 0, math.rad(0), 0 },
				{ 0, math.rad(0), 0 },
				{ 0, math.rad(0), 0 },
			},
		},
		capacity = 5,
		--xpNext = 1024,
	},
	{
		name = "DesertForest",
		service = "GrowTileService",
	}
}

setmetatable(Tiles.Main, {
	__index = function(_, key)
		local reversed = Tiles._reversed[key]
		if reversed then
			return Tiles.Main[reversed]
		end
		return nil
	end,
})

Tiles._unWork = (function()
	local unWorkTable = {}
	for _, v in pairs(Tiles.Main) do
		if v.work then
			unWorkTable[v.work] = { v.name, v.service }
		end
	end
	return unWorkTable
end)()

Tiles._reversed = reverseTable(Tiles.Main)

--- Get the id of a tile from its name
--- @return number
function Tiles.GetId(name: string)
	return Tiles._reversed[name]
end

function Tiles.checkSettle(name)
	if Tiles.Main[name].canSettle then
		return true
	end

	return false
end

function Tiles.GetTasks(name)
	return {
		grow = Tiles.Main[name].grow,
		raise = Tiles.Main[name].raise,
		delete = true,
	}
end

function Tiles.checkWork(tile)
	if not tile then
		return false
	end

	local name = Tiles.Main[tile.name].work

	if name then
		return name
	end

	return false
end

function Tiles.unwork(tile)
	return Tiles._unWork[tile.Name][1], Tiles._unWork[tile.Name][2]
end

return Tiles
