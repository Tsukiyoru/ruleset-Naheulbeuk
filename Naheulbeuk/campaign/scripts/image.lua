-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if User.isHost() then
		setTokenOrientationMode(false);
	end
	onCursorModeChanged();
	onGridStateChanged();
end

function onCursorModeChanged(sTool)
	window.onCursorModeChanged();
end

function onGridStateChanged(gridtype)
	window.onGridStateChanged();
end

function onTargetSelect(aTargets)
	local aSelected = getSelectedTokens();
	if #aSelected == 0 then
		local tokenActive = TargetingManager.getActiveToken(self);
		if tokenActive then
			local bAllTargeted = true;
			for _,vToken in ipairs(aTargets) do
				if not vToken.isTargetedBy(tokenActive) then
					bAllTargeted = false;
					break;
				end
			end
			
			for _,vToken in ipairs(aTargets) do
				tokenActive.setTarget(not bAllTargeted, vToken);
			end
			return true;
		end
	end
end

function onDrop(x, y, draginfo)
	local sDragType = draginfo.getType();
	
	if sDragType == "combattrackerff" then
		-- Grab faction data from drag object
		local sFaction = draginfo.getStringData();

		-- Determine image viewpoint
		-- Handle zoom factor (>100% or <100%) and offset drop coordinates
		local vpx, vpy, vpz = getViewpoint();
		x = x / vpz;
		y = y / vpz;
		
		-- If grid, then snap drop point and adjust drop spread
		local nDropSpread = 15;
		if hasGrid() then
			x, y = snapToGrid(x, y);
			nDropSpread = getGridSize();
		end

		-- Get the CT window
		local ctwnd = Interface.findWindow("combattracker_host", "combattracker");
		if ctwnd then
		    -- Loop through the CT entries
			for k,v in pairs(ctwnd.list.getWindows()) do
				-- Make sure we have the right fields to work with
				if v.token and v.friendfoe then
					-- Look for entries with the same faction
					if v.friendfoe.getStringValue() == sFaction then
						-- Get the entries token image
						local tokenproto = v.token.getPrototype();
						if tokenproto then
						    -- Add it to the image at the drop coordinates
							TokenManager.setDragTokenUnits(DB.getValue(v.getDatabaseNode(), "space"));
							local tokenMap = addToken(tokenproto, x, y);
							TokenManager.endDragTokenWithUnits();

							-- Update the CT entry's token references
							v.token.replace(tokenMap);
							
							-- Offset drop coordinates for next token = nice spread :)
							if x >= (nDropSpread * 1.5) then
								x = x - nDropSpread;
							end
							if y >= (nDropSpread * 1.5) then
								y = y - nDropSpread;
							end
						end
					end
				end
			end
		end
		
		return true;
	end
end
