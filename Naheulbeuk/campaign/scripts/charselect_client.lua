-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bInitialized = false;

function onInit()
	activeidentities = User.getAllActiveIdentities();

	User.getRemoteIdentities("charsheet", GameSystem.requestCharSelectDetailClient(), addIdentity);
	
	bInitialized = true;
end

function onClose()
	bInitialized = false;
end

function addIdentity(id, vDetails, nodeLocal)
	if not bInitialized then
		return;
	end
	
	for _, v in ipairs(activeidentities) do
		if v == id then
			return;
		end
	end

	local w = createWindow();
	if w then
		w.setId(id);
		w.setLocalNode(nodeLocal);
		
		local sName, sDetails = GameSystem.receiveCharSelectDetailClient(vDetails);
		w.name.setValue(sName);
		w.details.setValue(sDetails);

		if id then
			w.portrait.setIcon("portrait_" .. id .. "_charlist", true);
		end
	end
end
