-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	OptionsManager.registerCallback("IMID", onOptionIDChanged);
end

-- Registration functions

local aImages = {};
function registerImage(cImage)
	table.insert(aImages, cImage);
	onImageInit(cImage);
end
function unregisterImage(cImage)
	for k, v in ipairs(aImages) do
		if v == cImage then
			table.remove(aImages, k);
			return;
		end
	end
end

local aImageInitHandlers = {};
function registerImageInitHandler(fCallback)
	table.insert(aImageInitHandlers, fCallback);
end
function unregisterImageInitHandler(fCallback)
	for k, v in ipairs(aImageInitHandlers) do
		if v == fCallback then
			table.remove(aImageInitHandlers, k);
			return;
		end
	end
end

-- Event handlers

function onOptionIDChanged()
	for _,vImage in ipairs(aImages) do
		if vImage.window.onIDChanged then
			vImage.window.onIDChanged();
		end
	end
end

function onImageInit(cImage)
	for _,vToken in ipairs(cImage.getTokens()) do
		TokenManager.updateAttributesFromToken(vToken);
	end
end

function onTokenAdd(tokenMap)
	local nodeImage = tokenMap.getContainerNode();
	for _,vImage in ipairs(aImages) do
		if vImage.getDatabaseNode() == nodeImage then
			TokenManager.updateAttributesFromToken(tokenMap);
			if User.isHost() and OptionsManager.getOption("TASG") ~= "off" then
				TokenManager.autoTokenScale(tokenMap);
			end
			if vImage.window.updateDisplay then
				vImage.window.updateDisplay();
			end
			break;
		end
	end
end

function onTokenDelete(tokenMap)
	local nodeImage = tokenMap.getContainerNode();
	for _,vImage in ipairs(aImages) do
		if vImage.getDatabaseNode() == nodeImage then
			if vImage.window.updateDisplay then
				vImage.window.updateDisplay();
			end
			break;
		end
	end
end

