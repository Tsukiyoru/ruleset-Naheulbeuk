-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;
local bDataFilter = false;
local bTokenFilter = false;

function onInit()
	local modules = Module.getModules();
	for _, v in ipairs(modules) do
		checkEntry(v);
	end
	
	Module.onModuleAdded = checkEntry;
	Module.onModuleUpdated = checkEntry;
	Module.onModuleRemoved = removeEntry;
	
	bInitialized = true;
end

function addEntry(name)
	local w = list.createWindow();
	if w then
		w.setEntryName(name);
	end
end

function checkEntry(name)
	for _,v in pairs(list.getWindows()) do
		if v.getEntryName() == name then
			v.update();
			list.applyFilter();
			return;
		end
	end
	addEntry(name);
end

function removeEntry(name)
	for _,v in pairs(list.getWindows()) do
		if v.getEntryName() == name then
			v.close();
			return;
		end
	end
end

function setDataFilter()
	bDataFilter = true;
	bTokenFilter = false;
	updateContents();
end

function setTokenFilter()
	bTokenFilter = true;
	bDataFilter = false;
	updateContents();
end

function updateContents()
	if bTokenFilter then
		title.setValue(Interface.getString("module_window_titletoken"));
	else
		title.setValue(Interface.getString("module_window_titledata"));
	end
	list.applyFilter();
end

function onModuleFilter(w)
	if bTokenFilter then
		if w.hastokens.getValue() == 0 then
			return false;
		end
	else
		if w.hasdata.getValue() == 0 then
			return false;
		end
	end
	if filter_open.getValue() == 1 then
		if not w.isActive() then
			return false;
		end
	end
	local sNameFilter = filter_name.getValue();
	if sNameFilter ~= "" then
		if not string.find(w.name.getValue():lower(), sNameFilter:lower(), 0, true) then
			return false;
		end
	end
	return true;
end
