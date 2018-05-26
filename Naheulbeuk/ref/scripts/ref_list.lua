-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local sFilter = "filter";

function onInit()
	if altfilter then
		sFilter = altfilter[1];
	end
end

function onFilter(w)
	local f = getFilter(w);
	if f == "" then
		setHeadersVisible(w, true);
		return true;
	end

	setHeadersVisible(w, false);
	
	local bShow = true;
	if w.keywords then
		local sKeyWordsLower = w.keywords.getValue():lower();
		for word in f:gmatch("%w+") do
			if not sKeyWordsLower:find(word, 0, true) then
				bShow = false;
			end
		end
	else
		local sNameLower = w.name.getValue():lower();
		for word in f:gmatch("%w+") do
			if not sNameLower:find(word, 0, true) then
				bShow = false;
			end
		end
	end

	if bShow then
		setPathVisible(w);
	end
	
	return bShow;
end

function setHeadersVisible(w, bShow)
	local vTop = w;
	while vTop.windowlist or vTop.parentcontrol do
		if vTop.windowlist then
			vTop = vTop.windowlist.window;
		else
			vTop = vTop.parentcontrol.window;
		end
		if vTop.showFullHeaders then
			vTop.showFullHeaders(bShow);
		end
	end
end

function setPathVisible(w)
	local vTop = w;
	while vTop.windowlist or vTop.parentcontrol do
		if vTop.windowlist then
			vTop.windowlist.setVisible(true);
			vTop = vTop.windowlist.window;
		else
			vTop.parentcontrol.setVisible(true);
			vTop = vTop.parentcontrol.window;
		end
	end
end

function getFilter(w)
	local vTop = w;
	while vTop.windowlist or vTop.parentcontrol do
		if vTop.windowlist then
			vTop = vTop.windowlist.window;
		else
			vTop = vTop.parentcontrol.window;
		end
	end
	if not vTop[sFilter] then
		return "";
	end

	return vTop[sFilter].getValue():lower();
end
