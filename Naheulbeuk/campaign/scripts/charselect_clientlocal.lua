-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	localIdentities = User.getLocalIdentities();
	for _, v in ipairs(localIdentities) do
		addIdentity(v.databasenode);
	end
	
	if User.isLocal() then
		DB.addHandler("charsheet.*", "onAdd", addIdentity);
		DB.addHandler("charsheet.*.name", "onUpdate", onDetailsUpdate);
		DB.addHandler("charsheet.*.level", "onUpdate", onDetailsUpdate);
	end
end

function onClose()
	if User.isLocal() then
		DB.removeHandler("charsheet.*", "onAdd", addIdentity);
		DB.removeHandler("charsheet.*.name", "onUpdate", onDetailsUpdate);
		DB.removeHandler("charsheet.*.level", "onUpdate", onDetailsUpdate);
	end
end

function onDetailsUpdate(nodeField)
	local nodeChar = nodeField.getParent();
	local sID = nodeChar.getName();
	
	for _,w in pairs(getWindows()) do
		if w.id == sID then
			local sName, sDetails = GameSystem.getCharSelectDetailLocal(nodeChar);
			w.name.setValue(sName);
			w.details.setValue(sDetails);
			break;
		end
	end
end

function addIdentity(nodeLocal)
	local w = createWindow();
	if w then
		w.setId(nodeLocal.getName());
		w.setLocalNode(nodeLocal);

		local sName, sDetails = GameSystem.getCharSelectDetailLocal(nodeLocal);
		w.name.setValue(sName);
		w.details.setValue(sDetails);

		if id then
			w.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end
	end
end

function onListChanged()
	update();
end

function update()
	local bEditMode = (window.button_localedit.getValue() == 1);
	for _,w in pairs(getWindows()) do
		w.idelete.setVisibility(bEditMode);
		w.iexport.setVisible(bEditMode);
	end
end
