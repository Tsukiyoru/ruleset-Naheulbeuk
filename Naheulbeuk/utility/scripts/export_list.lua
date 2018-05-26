-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	addCategories();
end

function onDrop(x, y, draginfo)
	if draginfo.isType("shortcut") then
		for _,v in ipairs(getWindows()) do
			local sClass, sRecord = draginfo.getShortcutData();
		
			-- Find matching export category
			local bMatch = false;
			for kSource,vSource in ipairs(v.getSources()) do
				if sRecord:match("^" .. vSource) then
					bMatch = true;
				end
			end
			if bMatch then
				-- Check duplicates
				for _,c in ipairs(v.entries.getWindows()) do
					if c.getDatabaseNode().getNodeName() == sRecord then
						return true;
					end
				end
			
				-- Create entry
				local w = v.entries.createWindow(draginfo.getDatabaseNode());
				w.open.setValue(sClass, sRecord);
				
				v.all.setValue(0);
				break;
			end
		end
		
		return true;
	end
end

function addCategories()
	local aCategories = ExportManager.retrieveExportNodes();
	
	for _,r in ipairs(aCategories) do
		local w = createWindow();
		w.label.setValue(r.label);
		w.setExportType(r.name);
		w.setSource(r.source or r.name);
		w.setTarget(r.export or r.name);
		w.setRefTarget(r.exportref or r.export or r.name);
	end
	
	applySort();
end
