function ResourceTower:CollectResources()

    for _, player in ipairs(GetEntitiesForTeam("Player", self:GetTeamNumber())) do
        if player:isa("Alien") or not player:isa("Commander") then
            player:AddResources(kPlayerResPerInterval)
        end
    end
    
    local team = self:GetTeam()
    if team and not team:GetIsAlienTeam() then
        team:AddTeamResources(kTeamResourcePerTick, true)
    end

    if self:isa("Extractor") then
       self:TriggerEffects("extractor_collect")
    else
        self:TriggerEffects("harvester_collect")
    end
    
    local attached = self:GetAttached()
    
    if attached and attached.CollectResources then
    
        -- reduces the resource count of the node
        attached:CollectResources()
    
    end

end