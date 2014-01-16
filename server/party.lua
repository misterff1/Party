--[[
    Party v0.1
    Created by Misterff1
]]

--[[
    Wrapper class for each player who joins the Party
]]
class "PartyPlayer"
function PartyPlayer:__init(player, Party)
    self.Party = Party
    self.player = player
    self.start_pos = player:GetPosition()
    self.start_world = player:GetWorld()
    self.inventory = player:GetInventory()
	self.oldmodel = self.player:GetModelId()
	self.color = player:GetColor()
	self.oob = false
    self.pts = 0
    self.canKill = false
end

function PartyPlayer:Enter()
    self.player:SetWorld(self.Party.world)
self.player:SetModelId(15)
    self.Party.world:SetTime(1)
self.Party.world:SetTimeStep(0)

    self:Spawn()
	
    Network:Send( self.player, "PartyEnter" )
end

function PartyPlayer:Spawn()
    self.canKill = false
	local spawn = self.Party.spawns[ math.random(1, #self.Party.spawns) ]
	self.player:Teleport(spawn, Angle())
    self.player:ClearInventory()
	if self.Party.it == self.player then
		self.player:GiveWeapon(0, Weapon(Weapon.BubbleGun))
		self.player:GiveWeapon(1, Weapon(Weapon.BubbleGun))
	else
		self.player:GiveWeapon(0, Weapon(Weapon.BubbleGun))
		self.player:GiveWeapon(1, Weapon(Weapon.BubbleGun))
		
	end
    self.player:SetHealth(50)
    self.canKill = false
end

function PartyPlayer:Leave()
    self.player:SetWorld( self.start_world )
    self.player:Teleport( self.start_pos, Angle() )
self.player:SetModelId(self.oldmodel)
    self.player:ClearInventory()
    for k,v in pairs(self.inventory) do
        self.player:GiveWeapon( k, v )
    end
	self.player:SetColor( self.color )
    Network:Send( self.player, "PartyExit" )
end

--[[
    Actual Party gamemode.
    TODO: Add a name so that you can have many Party modes running through the single script.
]]
class "Party"
function table.find(l, f)
  for _, v in ipairs(l) do
    if v == f then
      return _
    end
  end
  return nil
end

local Ids = {
    --[[4,
    8,
    33,
    40,
    41,
    42,
    68,
    71,
    76,]]
	11,
	36,
	90,
	61,
	17,
	83
}

-- local Ids = {
    -- 2
-- }

function GetRandomVehicleId()
    return Ids[math.random(1 , #Ids)]
end

function Party:CreateSpawns()
    --local center = Vector3( 13199.354492, 1284.939697, -4907.594238 )
    local cnt = 0
    local blacklist = { 0, 174, 19, 18, 17, 16, 170, 171, 172, 173, 151, 152, 153, 154, 155, 129, 128, 127, 126, 125, 110, 109, 108, 107, 84, 83, 82, 81, 80, 64, 63, 62, 61, 39, 38, 36, 35 }
    local dist = self.maxDist - 128
	
    for j=0,8,1 do
    for i=0,360,1 do        
        if table.find(blacklist, cnt) == nil then
            local x = self.center.x + (math.sin( 2 * i * math.pi/360 ) * dist * math.random())
            local y = self.center.y 
            local z = self.center.z + (math.cos( 2 * i * math.pi/360 ) * dist * math.random())
            
            local radians = math.rad(360 - i)
            
            angle = Angle.AngleAxis(radians , Vector3(0 , -1 , 0))

            --local vehicle = Vehicle.Create( GetRandomVehicleId(), Vector3( x, y, z ), angle )
            
            --vehicle:SetEnabled( true )
            --vehicle:SetWorld( self.world )

            --self.vehicles[vehicle:GetId()] = vehicle
            table.insert(self.spawns, Vector3( x, y+400, z ))
        end
        cnt = cnt + 1
    end
    end
end

function Party:UpdateScores()
    scores = {}
    for k,v in pairs(self.players) do
        table.insert(scores, { name=v.player:GetName(), pts=v.pts, it=(self.it == v.player)})
    end
    table.sort(scores, function(a, b) return a.pts > b.pts end)
    for k,v in pairs(self.players) do
        Network:Send( v.player, "PartyUpdateScores", scores )
    end
end

function Party:SetIt( v )
    self.it = v.player
    self.oldIt = v.player
    v:Spawn()
    self:UpdateScores()
end

function Party:__init( spawn )
    self.world = World.Create()
        
    self.spawns = {}
	self.center = Vector3(13199.354492, 1284.939697, -4907.594238)
	self.maxDist = 100

    self.vehicles = {}
    self:CreateSpawns()
    
    self.players = {}
    self.last_broadcast = 0
	
    Events:Subscribe( "PlayerChat", self, self.ChatMessage )
    Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
    
    Events:Subscribe( "PlayerJoin", self, self.PlayerJoined )
    Events:Subscribe( "PlayerQuit", self, self.PlayerQuit )
    
    Events:Subscribe( "PlayerDeath", self, self.PlayerDeath )
    Events:Subscribe( "PlayerSpawn", self, self.PlayerSpawn )
    Events:Subscribe( "PostTick", self, self.PostTick )

    Events:Subscribe( "PlayerEnterVehicle", self, self.PlayerEnterVehicle )
    Events:Subscribe( "PlayerExitVehicle", self, self.PlayerExitVehicle )

    Events:Subscribe( "JoinGamemode", self, self.JoinGamemode )
end

function Party:ModuleUnload()
    -- Remove the vehicles we have spawned
    for k,v in pairs(self.vehicles) do
        v:Remove()
    end
    self.vehicles = {}
    
    -- Restore the players to their original position and world.
    for k,v in pairs(self.players) do
        v:Leave()
        self:MessagePlayer(v.player, "Party script unloaded. You have been restored to your starting pos.")
    end
    self.players = {}
end

function Party:PostTick()
       
end

function Party:IsInParty(player)
    return self.players[player:GetId()] ~= nil
end

function Party:GetDomePlayer(player)
    return self.players[player:GetId()]
end

function Party:MessagePlayer(player, message)
    player:SendChatMessage( "[Party] " .. message, Color(0xfff0b010) )
end

function Party:MessagePlayers(message)
    for k,v in pairs(self.players) do
        self:MessagePlayer(v.player, message)
    end
end

function Party:MessageGlobal(message)
    Chat:Broadcast( "[Party] " .. message, Color(0xfff0c5b0) )
end

function Party:EnterParty(player)
    if player:GetWorld() ~= DefaultWorld then
        self:MessagePlayer(player, "You must exit all other game modes before joining.")
        return
    end
    
    local args = {}
    args.name = "Party"
    args.player = player
    Events:Fire( "JoinGamemode", args )
    
    local p = PartyPlayer(player, self)
    p:Enter()
    
    self:MessagePlayer(player, "You have entered the Party! Type /party to leave.") 
    
    if self.oldIt and self.it then
         
    else
        self:SetIt( p )
    end
    
    self.players[player:GetId()] = p
    self:UpdateScores()
end

function Party:LeaveParty(player)
    local p = self.players[player:GetId()]
    if p == nil then return end
    p:Leave()
    
    self:MessagePlayer(player, "You have left the Party! Type /party to enter at any time.")    
    self.players[player:GetId()] = nil
	if self.it == player then self.it = nil end
    self:UpdateScores()
end

function Party:ChatMessage(args)
    local msg = args.text
    local player = args.player
    
    if ( msg:sub(1, 1) ~= "/" ) then
        return true
    end    
    
    local cmdargs = {}
    for word in string.gmatch(msg, "[^%s]+") do
        table.insert(cmdargs, word)
    end
    
    if ( cmdargs[1] == "/party" ) then
        if ( self:IsInParty(player) ) then
            self:LeaveParty(player, false)
        else        
            self:EnterParty(player)
        end
    end
	--[[if (cmdargs[1] == "/pos" ) then
		local pos = player:GetPosition()
		self:MessagePlayer(player, "Your coordinates are ("..pos.x..","..pos.y..","..pos.z..")")
	end]]
    return false
end

function Party:PlayerJoined(args)
    self.players[args.player:GetId()] = nil
	if self.it == args.player then self.it = nil end
    self:UpdateScores()
end

function Party:PlayerQuit(args)
    self.players[args.player:GetId()] = nil
	if self.it == args.player then self.it = nil end
    self:UpdateScores()
end

function Party:PlayerDeath(args)
    if ( not self:IsInParty(args.player) ) then
        return true
    end
	if self.it == args.player then
		args.player:SetColor( Color(0, 255, 0) )
		if args.killer then
			self.it = args.killer
            self.oldIt = args.killer
            self.players[self.it:GetId()].pts = self.players[self.it:GetId()].pts + 5
            Network:Send( self.it, "PartyUpdatePoints", self.players[self.it:GetId()].pts )
			self.players[args.killer:GetId()]:Spawn()
		else
			self.it = nil
            if args.reason == DamageEntity.None then
                self:MessagePlayers(args.player:GetName().." has perished!")
            elseif args.reason == DamageEntity.Physics then
                self:MessagePlayers(args.player:GetName().." was crushed!")
            elseif args.reason == DamageEntity.Bullet then
                self:MessagePlayers(args.player:GetName().." was filled with lead!")
            elseif args.reason == DamageEntity.Explosion then
                self:MessagePlayers(args.player:GetName().." asploded!")
            elseif args.reason == DamageEntity.Vehicle then
                self:MessagePlayers(args.player:GetName().." was demolished!")
            end
		end
        self:UpdateScores()
	elseif self.it and self.it == args.killer then
        self.players[self.it:GetId()].pts = self.players[self.it:GetId()].pts + 1
        Network:Send( self.it, "PartyUpdatePoints", self.players[self.it:GetId()].pts )
        self:UpdateScores()
    end
end

function Party:PlayerSpawn(args)
    if ( not self:IsInParty(args.player) ) then
        return true
    end
    
    self:MessagePlayer(args.player, "You have spawned in the Party. Type /party if you wish to leave.")
	
	self.players[args.player:GetId()]:Spawn()    
    return false
end

function Party:PlayerEnterVehicle(args)
    if ( not self:IsInParty(args.player) ) then
        return true
    end
	args.vehicle:SetHealth(0)
end

function Party:PlayerExitVehicle(args)
    if ( not self:IsInParty(args.player) ) then
        return true
    end
end

function Party:JoinGamemode( args )
    if args.name ~= "Party" then
        self:LeaveParty( args.player )
    end
end

Party = Party()