-- Party V1.1 by Misterff1

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
	self.canKill = false
end

function PartyPlayer:Enter()
	
    	self.player:SetWorld(self.Party.world)
	self.player:SetModelId(15)
    	self.Party.world:SetTime(1)
	self.Party.world:SetTimeStep(0)

	self:Spawn()
	
    	Network:Send(self.player, "PartyEnter")
end

function PartyPlayer:Spawn()
	
	local spawn = self.Party.spawns[ math.random(1, #self.Party.spawns) ]
	
    	self.canKill = false
	self.player:Teleport(spawn, Angle())
    	self.player:ClearInventory()
    	
    	self.player:GiveWeapon(0, Weapon(Weapon.BubbleGun))
	self.player:GiveWeapon(1, Weapon(Weapon.BubbleGun))
	self.player:GiveWeapon(2, Weapon(Weapon.BubbleGun))
	self.player:SetHealth(50)
	
    	self.canKill = false
end

function PartyPlayer:Leave()
	
    	self.player:SetWorld(self.start_world)
    	self.player:Teleport(self.start_pos, Angle())
	self.player:SetModelId(self.oldmodel)
	self.player:ClearInventory()
	
    	for k,v in pairs(self.inventory) do
        self.player:GiveWeapon(k, v)
    	end

    	Network:Send(self.player, "PartyExit")
end


class "Party"

	function table.find(l, f)
		
	  for _, v in ipairs(l) do
	  if v == f then
	  return _
    	  end
  	end
  	
  	return nil
end


function Party:CreateSpawns()

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

            table.insert(self.spawns, Vector3( x, y+400, z ))
        end
        cnt = cnt + 1
    end
    end
end


function Party:__init(spawn)
	
    	self.world = World.Create()
        
	self.spawns = {}
	self.center = Vector3(13199.354492, 1284.939697, -4907.594238)
	self.maxDist = 100

    	self:CreateSpawns()
    
    	self.players = {}
    	self.last_broadcast = 0
	
    	Events:Subscribe("PlayerChat", self, self.ChatMessage)
    	Events:Subscribe("ModuleUnload", self, self.ModuleUnload)
       	Events:Subscribe("PlayerJoin", self, self.PlayerJoined)
    	Events:Subscribe("PlayerQuit", self, self.PlayerQuit)
       	Events:Subscribe("PlayerDeath", self, self.PlayerDeath)
    	Events:Subscribe("PlayerSpawn", self, self.PlayerSpawn)
   	Events:Subscribe("JoinGamemode", self, self.JoinGamemode)
end

function Party:ModuleUnload()

    	for k,v in pairs(self.players) do
		v:Leave()
        	self:MessagePlayer(v.player, "Party script unloaded. You returned to the default world")
    	end
    
    	self.players = {}
end

function Party:IsInParty(player)
	return self.players[player:GetId()] ~= nil
end

function Party:MessagePlayer(player, message)
    	player:SendChatMessage("[Party] " .. message, Color(0xfff0b010))
end

function Party:MessagePlayers(message)
    	for k,v in pairs(self.players) do
        	self:MessagePlayer(v.player, message)
    	end
end

function Party:MessageGlobal(message)
    	Chat:Broadcast("[Party] " .. message, Color(0xfff0c5b0))
end

function Party:EnterParty(player)
	
    	if player:GetWorld() ~= DefaultWorld then
        	self:MessagePlayer(player, "You must exit all other game modes before joining.")
        	return
    	end
    
    	local args = {}
    	args.name = "Party"
    	args.player = player
    	Events:Fire("JoinGamemode", args)
    
    	local p = PartyPlayer(player, self)
    	p:Enter()
    
    	self:MessagePlayer(player, "You have entered the Party! Type /party to leave.") 
    
    	self.players[player:GetId()] = p
end

function Party:LeaveParty(player)
	
    	local p = self.players[player:GetId()]
    	if p == nil then return end
    	p:Leave()
    
    	self:MessagePlayer(player, "You have left the Party! Type /party to enter at any time.")    
    	self.players[player:GetId()] = nil
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
    
    	return false
end


function Party:PlayerJoined(args)
    	self.players[args.player:GetId()] = nil
end


function Party:PlayerQuit(args)
    	self.players[args.player:GetId()] = nil
end


function Party:PlayerDeath(args)
    	if ( not self:IsInParty(args.player) ) then
        	return true
    	end
end


function Party:PlayerSpawn(args)
    	if ( not self:IsInParty(args.player) ) then
		return true
    	end
    
    	self:MessagePlayer(args.player, "You respawned in the party. Type /party to exit")
	self.players[args.player:GetId()]:Spawn()
		
    	return false
end


function Party:JoinGamemode( args )
    	if args.name ~= "Party" then
        	self:LeaveParty(args.player)
    	end
end

Party = Party()
