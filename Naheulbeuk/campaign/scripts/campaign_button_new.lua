-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sRecordType = "";

function onInit()
	if class then
		setRecordType(class[1]);
	end
end

function setRecordType(sNewRecordType)
	sRecordType = sNewRecordType;
end

function onButtonPress()
	if User.isHost() then
		local node = window.getDatabaseNode().createChild();
		if node then
			local w = Interface.openWindow(sRecordType, node.getNodeName());
			if w and w.name then
				w.name.setFocus();
			elseif w.header and w.header.subwindow and w.header.subwindow.name then
				w.header.subwindow.name.setFocus();
			end
		end
	else
		local nodeWin = window.getDatabaseNode();
		if nodeWin then
			Interface.requestNewClientWindow(sRecordType, nodeWin.getNodeName());
		end
	end
	
	window.list_iedit.setValue(0);
end
