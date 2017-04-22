Hive.kResourceUpdateTime = 2
Hive.kResourceValue = 2.5
Hive.kResourcePerTick = (Hive.kResourceValue / 6) * Hive.kResourceUpdateTime
Hive.kResourceCapPerHive = 65


local kImpulseInterval = 10

local kHiveDyingThreshold = 0.4

local kCheckLowHealthRate = 12


local function UpdateHealing(self)

    if GetIsUnitActive(self) and not self:GetGameEffectMask(kGameEffect.OnFire) then
    
        if self.timeOfLastHeal == nil or Shared.GetTime() > (self.timeOfLastHeal + Hive.kHealthUpdateTime) then
            
            local players = GetEntitiesForTeam("Player", self:GetTeamNumber())
            
            for index, player in ipairs(players) do
            
                if player:GetIsAlive() and ((player:GetOrigin() - self:GetOrigin()):GetLength() < Hive.kHealRadius) then   
                    -- min healing, affects skulk only
                    player:AddHealth(math.max(10, player:GetMaxHealth() * Hive.kHealthPercentage), true )                
                end
                
            end
            
            self.timeOfLastHeal = Shared.GetTime()
            
        end
        
    end
    
end

local function UpdateResources(self)
	        
    if self:GetIsAlive() and self:GetIsBuilt() then
		if self.timeOfLastRes == nil or Shared.GetTime() > (self.timeOfLastRes + Hive.kResourceUpdateTime) then
			local team = self:GetTeam()
			if team then
				local hives = GetEntitiesForTeam("Hive", self:GetTeamNumber())
				local builtHives = {}

				-- allow only built hives to spawn eggs
				for _, hive in ipairs(hives) do

					if hive:GetIsBuilt() and hive:GetIsAlive() then
						table.insert(builtHives, hive)
					end

				end
				
				local cap = ( Hive.kResourceCapPerHive * #builtHives) 
				if team:GetTeamResources() < ( cap ) then
					amount = math.min(Hive.kResourcePerTick, cap - team:GetTeamResources()  )
					team:AddTeamResources(amount, true)
					self.timeOfLastRes = Shared.GetTime()
				end
			end
		end
	end
end

local function FireImpulses(self) 

    local now = Shared.GetTime()
    
    if not self.lastImpulseFireTime then
        self.lastImpulseFireTime = now
    end    
    
    if now - self.lastImpulseFireTime > kImpulseInterval then
    
        local removals = {}
        for key, id in pairs(self.cystChildren) do
        
            local child = Shared.GetEntity(id)
            if child == nil then
                removals[key] = true
            else
                if child.TriggerImpulse and child:isa("Cyst") then
                    child:TriggerImpulse(now)
                else
                    Print("Hive.cystChildren contained a: %s", ToString(child))
                    removals[key] = true
                end
            end
            
        end
        
        for key,_ in pairs(removals) do
            self.cystChildren[key] = nil
        end
        
        self.lastImpulseFireTime = now
        
    end
    
end

local function CheckLowHealth(self)

    if not self:GetIsAlive() then
        return
    end
    
    local inCombat = self:GetIsInCombat()
    if inCombat and (self:GetHealth() / self:GetMaxHealth() < kHiveDyingThreshold) then
    
        -- Don't send too often.
        self.lastLowHealthCheckTime = self.lastLowHealthCheckTime or 0
        if Shared.GetTime() - self.lastLowHealthCheckTime >= kCheckLowHealthRate then
        
            self.lastLowHealthCheckTime = Shared.GetTime()
            
            -- Notify the teams that this Hive is close to death.
            SendGlobalMessage(kTeamMessageTypes.HiveLowHealth, self:GetLocationId())
            
        end
        
    end
    
end

function Hive:OnUpdate(deltaTime)

    PROFILE("Hive:OnUpdate")
    
    CommandStructure.OnUpdate(self, deltaTime)
    
    UpdateHealing(self)
    
    FireImpulses(self)
    
    CheckLowHealth(self)
	
	UpdateResources(self)
    
    if not self:GetIsAlive() then
    
        local destructionAllowedTable = { allowed = true }
        if self.GetDestructionAllowed then
            self:GetDestructionAllowed(destructionAllowedTable)
        end
        
        if destructionAllowedTable.allowed then
            DestroyEntity(self)
        end

	end
    
end

