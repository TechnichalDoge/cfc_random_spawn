CFCRandomSpawn = CFCRandomSpawn or {}

local customSpawnsForMap = CFCRandomSpawn.Config.CUSTOM_SPAWNS[game.GetMap()]
local mapHasCustomSpawns = customSpawnsForMap ~= nil

if not mapHasCustomSpawns then return end

CFCRandomSpawn.spawnPointRankings = CFCRandomSpawn.spawnPointRankings or {}

local function getMeasurablePlayers()
    local measurablePlayers = {}
    for _, ply in pairs( player.GetHumans() ) do
        if ( ply:Alive() ) then
            table.insert( measurablePlayers, ply )
        end
    end

    return measurablePlayers
end

-- This is operating on a model of spawn points and players as electrons putting a force on each other
-- The best spawn point is the spawn point under the smallest sum of forces then. This is why we use physics terms here
local distSqr = 900 -- ( 30^2 )
local randMin, randMax = 1, 4

local function getPlayerForceFromCustomSpawn( spawn )
    local totalDistanceSquared = 0
    local measurablePlayers = getMeasurablePlayers()

    for _, ply in pairs( measurablePlayers ) do
        local plyDistanceSqr = ( ply:GetPos():DistToSqr( spawn ) )
        if plyDistanceSqr < distSqr then plyDistanceSqr = 1 end
        totalDistanceSquared = totalDistanceSquared + 1 / plyDistanceSqr
    end

    return totalDistanceSquared
end

function CFCRandomSpawn.getOptimalSpawnPosition()
    local randomSpawn = math.random( randMin, randMax )
    PrintTable( CFCRandomSpawn.spawnPointRankings[randomSpawn] )
    return CFCRandomSpawn.spawnPointRankings[randomSpawn].spawnPos
end

function CFCRandomSpawn.updateSpawnPointRankings()
    local playerIDSFromSpawns = {}

    for _, spawn in pairs( customSpawnsForMap ) do
        local spawnPosition = spawn.spawnPos
        local playerNetForce = getPlayerForceFromCustomSpawn( spawnPosition )
        local spawnDistanceData = {}
        spawnDistanceData.spawnPos = spawnPosition
        spawnDistanceData["inverse-distance-squared"] = playerNetForce

        table.insert( playerIDSFromSpawns, spawnDistanceData ) -- IDS == Inverse Distance Squared

        CFCRandomSpawn.spawnPointRankings = playerIDSFromSpawns
        table.SortByMember( CFCRandomSpawn.spawnPointRankings, "inverse-distance-squared", true )
    end

    --timer.Create( "CFC_UpdateOptimalSpawnPosition", 0.5, 0, CFCRandomSpawn.updateSpawnPointRankings )
end

function CFCRandomSpawn.handlePlayerSpawn( ply )
    if not ( ply and IsValid( ply ) ) then return end
    if ply.LinkedSpawnPoint then return end

    CFCRandomSpawn.updateSpawnPointRankings( ply )
    local optimalSpawnPosition = CFCRandomSpawn.getOptimalSpawnPosition()

    ply:SetPos( optimalSpawnPosition )
end

hook.Add( "PlayerSpawn", "CFC_PlayerSpawning", CFCRandomSpawn.handlePlayerSpawn )
