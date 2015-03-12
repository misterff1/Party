--------------------------------------------------------------------------------------------
----|                           	 Party v1.1                                    |----
----|                                   By Misterff1                                   |----
--------------------------------------------------------------------------------------------

class 'Party'


function Party:__init( )
	
	Network:Subscribe( "PartyEnter", self, self.Enter )
	Network:Subscribe( "PartyExit", self, self.Exit )
    	Network:Subscribe( "PartyEnterBorder", self, self.EnterBorder )
	Network:Subscribe( "PartyExitBorder", self, self.ExitBorder )
    	Network:Subscribe( "PartyUpdatePoints", self, self.UpdatePoints )
    	Network:Subscribe( "PartyUpdateScores", self, self.UpdateScores )

    	Events:Subscribe( "Render", self, self.Render )
    	Events:Subscribe( "ModuleLoad", self, self.ModulesLoad )
    	Events:Subscribe( "ModulesLoad", self, self.ModulesLoad )
    	Events:Subscribe( "ModuleUnload", self, self.ModuleUnload )
	
	self.oob = false
    	self.pts = 0
    	self.scores = { }
    	self.inMode = false
    	
end


function Party:Enter( )
    	self.inMode = true
end


function Party:Exit( )
	Waypoint:Remove( )
    	self.inMode = false
end


function Party:EnterBorder( )
	self.oob = true
end


function Party:ExitBorder( )
	self.oob = false
end


function Party:UpdatePoints( pts )
    	self.pts = pts
end


function Party:UpdateScores( scores )
    	self.scores = scores
end


function Party:ModulesLoad( )
	
    	Events:Fire( "HelpAddItem",
        	{
            	name = "Party",
            	text = 
                	"The Party is a passive game mode.\n \n" ..
                	"To enter the Party, type /party in chat and hit enter. " ..
                	"You will be transported to the mhc, where you will respawn " ..
        		"until you exit by using the command once more.\n \n" ..
                	"If you leave the party mode, your items and model " ..
                	"will be restored."
		 } )
        
end

function Party:ModuleUnload( )
	
    	Events:Fire( "HelpRemoveItem",
        	{
            		name = "Party"
        	} )
        
end


function Party:RightText( msg, y, color )
	
    	local w = Render:GetTextWidth( msg, TextSize.Default )
    	Render:DrawText( Vector2(Render.Width - w, y), msg, color, TextSize.Default )
    
end


function Party:Render( )
	
    	if not self.inMode then return end 
    	if Game:GetState() ~= GUIState.Game then return end
    
    	if not self.oob then return end
	
	local text = "Out of Bounds!"
    	local text_width = Render:GetTextWidth( text, TextSize.Gigantic )
    	local text_height = Render:GetTextHeight( text, TextSize.Gigantic )

	local pos = Vector2((Render.Width - text_width)/2, (Render.Height - text_height)/2 )

    	Render:DrawText( pos, text, Color( 255, 255, 255 ), TextSize.Gigantic )
    	
end

Party = Party()
