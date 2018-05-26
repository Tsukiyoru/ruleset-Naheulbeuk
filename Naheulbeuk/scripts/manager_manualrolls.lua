--
-- Please see the license.html file included with this distribution for
-- attribution and copyright information.
--

local cButton = nil;

function onInit()
	Interface.onDesktopInit = onDesktopInit
end

function onDesktopInit()
	update();
	OptionsManager.registerCallback("MANUALROLL", update);
end

function update()
	if OptionsManager.isOption("MANUALROLL", "on") then
		if not cButton then
			local wChat = Interface.findWindow("chat", "");
			if wChat then
				cButton = wChat.createControl("button_manualrolls", "manualrolls");
			end
		end
	else
		if cButton then
			cButton.destroy();
			cButton = nil;
		end
		local wRolls = Interface.openWindow("manualrolls", "");
		if wRolls then
			wRolls.list.closeAll();
			wRolls.close();
		end
	end
end