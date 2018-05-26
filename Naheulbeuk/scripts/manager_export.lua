-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

aExport = {};

function onInit()
	if User.isHost() then
		Comm.registerSlashHandler("export", processExport);
	end
end

function processExport(sCommand, sParams)
	Interface.openWindow("export", "export");
end

function retrieveExportNodes()
	return aExport;
end

function registerExportNode(rExport)
	table.insert(aExport, rExport)
end

function unregisterExportNode(rExport)
	local nIndex = nil;
	
	for k,v in pairs(aExport) do
		if string.upper(v.name) == string.upper(rExport.name) then
			nIndex = k;
		end
	end
	
	if nIndex then
		table.remove(aExport, nIndex);
	end
end
