-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local bHandleOption = false;
local sRecordType = nil;

function getRecordType()
	return sRecordType;
end
function setRecordType(sNewRecordType)
	bHandleOption = false;
	sRecordType = sNewRecordType;
	local sDisplayText = LibraryData.getDisplayText(sRecordType);
	name.setValue(sDisplayText);
	icon.setIcon(LibraryData.getDisplayIcons(sRecordType));
	synchState();
	bHandleOption = true;
end

function synchState()
	if DesktopManager.getSidebarButtonState(sRecordType) then
		sidebar.setValue(1);
	else
		sidebar.setValue(0);
	end
end

function onHover(bOnWindow)
	if bOnWindow then
		setFrame("rowshade");
	else
		setFrame(nil);
	end
end

function onOptionChanged()
	if not bHandleOption then
		return;
	end
	DesktopManager.onSidebarOptionChanged(sRecordType, sidebar.getValue());
end
