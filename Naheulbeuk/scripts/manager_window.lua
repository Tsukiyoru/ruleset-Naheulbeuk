-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function getReadOnlyState(nodeRecord)
	local nDefault = 0;
	if nodeRecord.getModule() then
		nDefault = 1;
	end
	local bLocked = (DB.getValue(nodeRecord, "locked", nDefault) ~= 0);
	local bReadOnly = true;
	if nodeRecord.isOwner() and not nodeRecord.isReadOnly() and not bLocked then
		bReadOnly = false;
	end
	
	return bReadOnly;
end
