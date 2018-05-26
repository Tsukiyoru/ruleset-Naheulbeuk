-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	font.add("", "")
	if GameSystem.languagefonts then
		for kLangFont,vLangFont in pairs(GameSystem.languagefonts) do
			font.add(vLangFont, kLangFont);
		end
	end
end

function onHover(bState) 
	if bState then 
		setFrame("rowshade")
	else
		setFrame(nil)
	end
end

function onDragStart(button, x, y, draginfo)
	local sLang = name.getValue()
	if sLang ~= "" then
		draginfo.setType("language")
		draginfo.setIcon("button_speak")
		draginfo.setStringData(sLang)
		return true
	end
end
