-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sModule = nil;
local bActive = false;

function onMenuSelection(selection)
	if selection == 8 then
		Module.revert(sModule);
	end
end

function update()
	local info = Module.getModuleInfo(sModule);
	
	if not User.isHost() then
		if info.permission == "disallow" then
			close();
			return;
		end
	end
	
	name.setValue(info.displayname or info.name);
	author.setValue(info.author);
	
	if info.loaded then
		load.setIcon(load.states[1].loaded[1]);
		button_load.setValue(1);
		bActive = true;
	else
		load.setIcon(load.states[1].unloaded[1]);
		button_load.setValue(0);
		bActive = false;
	end
	
	if info.permission == "disallow" then
		permissions.setIcon(permissions.states[1].block[1]);
	elseif info.permission == "allow" then
		permissions.setIcon(permissions.states[1].allow[1]);
	elseif info.loadpending then
		permissions.setIcon(permissions.states[1].pending[1]);
	else
		permissions.setIcon(permissions.states[1].none[1]);
	end
	
	local thumbwidget = thumbnail.findWidget("remote");
	if info.installed then
		if thumbwidget then
			thumbwidget.destroy();
		end
	else
		if not thumbwidget then
			thumbwidget = thumbnail.addBitmapWidget("module_remote");
			thumbwidget.setPosition("bottomleft", 10, 0);
			thumbwidget.setName("remote");
		end
	end
	
	local tokenswidget = thumbnail.findWidget("hastokens");
	if info.hastokens then
		if not tokenswidget then
			tokenswidget = thumbnail.addBitmapWidget("module_hastokens");
			tokenswidget.setPosition("bottomright", -10, 0);
			tokenswidget.setName("hastokens");
		end
		hastokens.setValue(1);
	else
		if tokenswidget then
			tokenswidget.destroy();
		end
		hastokens.setValue(0);
	end

	if info.hasdata then
		hasdata.setValue(1);
	else
		hasdata.setValue(0);
	end
	
	if info.intact then
		resetMenuItems();
	else
		registerMenuItem(Interface.getString("module_menu_revert"), "shuffle", 8);
	end
	
	windowlist.window.list.applyFilter();
end

function setEntryName(sName)
	sModule = sName;
	thumbnail.setIcon("module_" .. sModule);
	update();
end

function getEntryName()
	return sModule;
end

function isActive()
	return bActive;
end

function toggleActivation()
	if bActive then
		deactivate();
	else
		activate();
	end
end

function activate()
	Module.activate(sModule);
end

function deactivate()
	Module.deactivate(sModule);
end

function setPermissions(p)
	if p == "disallow" then
		Module.setModulePermissions(sModule, false, false);
	elseif p == "allow" then
		Module.setModulePermissions(sModule, true, false);
	end
end