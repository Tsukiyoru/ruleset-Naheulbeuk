-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function delete()
	windowlist.window.handleCategoryDelete(category.getValue());
end

function handleDrop(draginfo)
	if draginfo.isType("shortcut") then
		local sCategory = category.getValue();
		if sCategory ~= "*" then
			local _,sRecord = draginfo.getShortcutData();
			DB.setCategory(sRecord, sCategory);
		end
		return true;
	end
end

function handleSelect()
	windowlist.window.handleCategorySelect(category.getValue());
end

function handleCategoryNameChange(sOriginal, sNew)
	windowlist.window.handleCategoryNameChange(sOriginal, sNew);
end
