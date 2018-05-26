-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sTarget = "";

local sFont = "";
local sSelectedFont = "";
local sFrame = "";
local sSelectedFrame = "";

local nDisplayRows = 0;
local nMaxRows = 0;
local nRowHeight = 20;

local nOrder = 0;

function setTarget(sTargetParam)
	sTarget = sTargetParam;
end

function optionClicked(opt)
	window[sTarget].optionClicked(opt);
end

function setFonts(sNormal, sSelection)
	sFont = sNormal or "";
	sSelectedFont = sSelection or "";

	for _,w in ipairs(getWindows()) do
		w.setFonts(sFont, sSelectedFont);
	end
end

function setFrames(sNormal, sSelection)
	sFrame = sNormal or "";
	sSelectedFrame = sSelection or "";

	for _,w in ipairs(getWindows()) do
		w.setFrames(sFrame, sSelectedFrame);
	end
end

function setMaxRows(nNewMaxRows)
	nMaxRows = nNewMaxRows;
	adjustHeight();
end

function adjustHeight()
	local nNewDisplayRows = #(getWindows());
	if nMaxRows > 0 then
		nNewDisplayRows = math.min(nMaxRows, nNewDisplayRows);
	end
	if nNewDisplayRows ~= nDisplayRows then
		nDisplayRows = nNewDisplayRows
		setAnchoredHeight(nDisplayRows * nRowHeight);
	end
end

function add(sValue, sText)
	local w = createWindow();
	w.Text.setValue(sText);
	w.Value.setValue(sValue);
	w.setFonts(sFont, sSelectedFont);
	w.setFrames(sFrame, sSelectedFrame);

	w.Order.setValue(nOrder);
	nOrder = nOrder + 1;
	
	adjustHeight();
end

function clear()
	closeAll();
	nOrder = 0;
end

function onLoseFocus()
	window[sTarget].hideList();
end

