-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onMenuSelection(selection)
	if selection == 5 then
		window.addEntry(true);
	end
end

function onListChanged()
	window.onListChanged();
end

function onDrop(x, y, draginfo)
	local vReturn = nil;
	if draginfo.isType("shortcut") then
		vReturn = CampaignDataManager.handleDrop(window.getRecordType(), draginfo);
	elseif draginfo.isType("file") then
		vReturn = CampaignDataManager.handleFileDrop(window.getRecordType(), draginfo);
	end
	return vReturn;
end

function update()
	local bEditMode = (window[getName() .. "_iedit"].getValue() == 1);
	
	for _,w in pairs(getWindows()) do
		local node = w.getDatabaseNode();
		if node then
			if not node.isReadOnly() then
				w.idelete.setVisibility(bEditMode);
			else
				w.idelete.setVisibility(false);
			end
		end
	end
end
