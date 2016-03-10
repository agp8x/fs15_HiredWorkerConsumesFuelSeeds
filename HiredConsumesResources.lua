--
-- @author: Decker_MMIV - fs-uk.com, forum.farming-simulator.com, modhoster.com
-- @date:   (started) 2011-October
--          (resumed) 2013-July
--
-- @brief:  Tricks the game-scripts to actually consume fuel and seeds,
--          when an AI-worker is hired to do the job.
--
-- @history
--      v0.9    - For FS2011
--  2013-July
--      v0.92   - Updated to FS2013
--              - Stops hired worker, if sowing machine/sprayer is empty or fuel is 1% or less.
--              - Requires patch 1.4.0.x
--      v0.93   - fix for FS2015 holmer DLC (by agp8x@agp8x.org)
--


HiredConsumesResources = {}
HiredConsumesResources.version = 0.93;

--
function HiredConsumesResources.getIsHired(self, superFunc)
  -- Assumption: Looks like only SowingMachine.lua, Sprayer.Lua & Steerable.Lua 
  -- calls this function, to determine if fuel/seeds/fertilizer needs to be decreased or not.
  -- We just "lie", and tell them that it is _not_ controlled by a hired-worker.
  return false;
end;

Vehicle.getIsHired = Utils.overwrittenFunction(Vehicle.getIsHired, HiredConsumesResources.getIsHired);

--
function HiredConsumesResources.updateTick(self, superFunc, dt)
    if superFunc ~= nil then
        superFunc(self,dt);
    end;
    --
    if g_server then
        if self.isHired then
            local shouldDismissWorker = false;
            -- If any of the attached implements is a sowingMachine or sprayer, make sure it has enough in the fillable.
			local oneEmpty=false;
			local allEmpty=true;
            for _,attachable in pairs(self.attachedImplements) do
                if attachable.object ~= nil and (attachable.object.lastSowingArea ~= nil or attachable.object.isSprayerTank ~= nil) then 
                    if attachable.object.fillLevel ~= nil then 
						if attachable.object.fillLevel <= 0 then
							-- no more in sowingMachine/sprayer, so dismiss worker.
							--shouldDismissWorker = true;
							--break
							oneEmpty=true;
						else
							allEmpty=false;
						end;
                    end;
                end;
            end;
			if oneEmpty and allEmpty then
				shouldDismissWorker = true;
			end;
            -- If fuel-level is less than 1%, then dismiss worker.
            if self.fuelFillLevel ~= nil and self.fuelCapacity ~= nil and self.fuelCapacity > 0 then
                if self.fuelFillLevel <= (self.fuelCapacity * 0.01) then
                    shouldDismissWorker = true;
                end
            end
            --
            if shouldDismissWorker then
                if self.stopAITractor ~= nil then
                    self:stopAITractor();
                elseif self.stopAIThreshing ~= nil then
                    self:stopAIThreshing();
                end
            end;
        end;
    end;
end;

Hirable.updateTick = Utils.overwrittenFunction(Hirable.updateTick, HiredConsumesResources.updateTick);

--
print(string.format("Script loaded: HiredConsumesResources.lua (v%.2f)", HiredConsumesResources.version));
