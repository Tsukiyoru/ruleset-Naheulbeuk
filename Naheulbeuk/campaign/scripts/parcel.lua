-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("MIID", StateChanged);

	if User.isHost() and GameSystem.currencies then
		if coins.getWindowCount() == 0 then
			local nCoinTypes = #(GameSystem.currencies);
			for i = 1, #(GameSystem.currencies) do
				local w = coins.createWindow();
				w.description.setValue(GameSystem.currencies[i]);
			end
			onLockChanged();
		end
	end
end

function onClose()
	OptionsManager.unregisterCallback("MIID", StateChanged);
end

function StateChanged()
	for _,w in ipairs(items.getWindows()) do
		w.onIDChanged();
	end
	items.applySort();
end

function onDrop(x, y, draginfo)
	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	if bReadOnly then
		return;
	end
	
	return ItemManager.handleAnyDrop(getDatabaseNode(), draginfo);
end

function onLockChanged()
	if header.subwindow then
		header.subwindow.update();
	end

	local bReadOnly = WindowManager.getReadOnlyState(getDatabaseNode());
	
	if bReadOnly then
		coins_iedit.setValue(0);
		items_iedit.setValue(0);
	end
	coins_iedit.setVisible(not bReadOnly);
	items_iedit.setVisible(not bReadOnly);

	coins.setReadOnly(bReadOnly);
	for _,w in pairs(coins.getWindows()) do
		w.amount.setReadOnly(bReadOnly);
		w.description.setReadOnly(bReadOnly);
	end

	items.setReadOnly(bReadOnly);
	for _,w in pairs(items.getWindows()) do
		if w.count then
			w.count.setReadOnly(bReadOnly);
		end
		w.name.setReadOnly(bReadOnly);
		w.nonid_name.setReadOnly(bReadOnly);
	end
end
