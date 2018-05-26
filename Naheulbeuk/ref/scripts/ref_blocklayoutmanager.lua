-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

m_nFrameOffsetX = 25;
m_nFrameOffsetY = 35;

m_nGraphicOffsetX = 35;
m_nTextWithFrameOffsetX = 35;
m_nTextSansFrameOffsetX = 20;

m_nHeaderFrameOffsetX = 20;
m_nHeaderFrameOffsetY = 20;
m_nHeaderWithFrameOffsetX = 30;
m_nHeaderSansFrameOffsetX = 15;

function onInit()
	for _,win in pairs(getWindows()) do
		buildBlock(win);
	end
end

function addPicture(win, sAlign)
	local ctrl = win.createControl("token_refblock", "picture");
	
	local w, h = getGraphicDimensions(win, sAlign);
	ctrl.setAnchoredWidth(w);
	ctrl.setAnchoredHeight(h);
	
	if sAlign == "left" then
		ctrl.setAnchor("left", "", "left", "absolute", m_nGraphicOffsetX);
	elseif sAlign == "right" then
		ctrl.resetAnchor("left");
		ctrl.setAnchor("right", "", "right", "absolute", -m_nGraphicOffsetX);
	else
		ctrl.setAnchor("left", "", "center", "absolute", tonumber("-" .. w/2));
	end
	ctrl.setVisible(true);

	addCaption(win, "picture");
end

function addImage(win, sAlign)
	local ctrl = win.createControl("image_refblock", "image");
	
	local w, h = getGraphicDimensions(win, sAlign);
	ctrl.setAnchoredWidth(w);
	ctrl.setAnchoredHeight(h);
	
	local iw, ih = ctrl.getImageSize();
	if iw > 0 and ih > 0 then
		ctrl.setViewpoint(0, 0, math.min(w / iw, h / ih));
	end
	
	if sAlign == "left" then
		ctrl.setAnchor("left", "", "left", "absolute", m_nGraphicOffsetX);
	elseif sAlign == "right" then
		ctrl.resetAnchor("left");
		ctrl.setAnchor("right", "", "right", "absolute", -m_nGraphicOffsetX);
	else
		ctrl.setAnchor("left", "", "center", "absolute", tonumber("-" .. w/2));
	end
	ctrl.setVisible(true);
	
	local sLinkClass, sLinkRecord = DB.getValue(win.getDatabaseNode(), "imagelink", "");
	if (sLinkClass ~= "") and (sLinkRecord ~= "") then
		win.createControl("image_clickcapture_refblock", "imagelink");
	end

	addCaption(win, "image");
end

function addIcon(win, sAlign)
	local ctrl = win.createControl("icon_refblock", "icon");
	ctrl.setIcon(DB.getValue(win.getDatabaseNode(), "icon", ""));

	local w, h = getGraphicDimensions(win, sAlign);
	ctrl.setAnchoredWidth(w);
	ctrl.setAnchoredHeight(h);

	if sAlign == "left" then
		ctrl.setAnchor("left", "", "left", "absolute", m_nGraphicOffsetX);
	elseif sAlign == "right" then
		ctrl.resetAnchor("left");
		ctrl.setAnchor("right", "", "right", "absolute", -m_nGraphicOffsetX);
	else
		ctrl.setAnchor("left", "", "center", "absolute", tonumber("-" .. w/2));
	end
		ctrl.setVisible(true);

	addCaption(win, "icon");
end

function addCaption(win, sAnchor)
	local sCaption = DB.getValue(win.getDatabaseNode(), "caption", "");
	if sCaption ~= "" then
		local ctrlCaption = win.createControl("string_refblock_caption", "caption");
		ctrlCaption.setAnchor("top", sAnchor, "bottom", "absolute", 0);
		ctrlCaption.setAnchor("left", sAnchor, "left", "absolute", 0);
		ctrlCaption.setAnchor("right", sAnchor, "right", "absolute", 0);
		ctrlCaption.setVisible(true);

		local sLinkClass, sLinkRecord = DB.getValue(win.getDatabaseNode(), "captionlink", "");
		if (sLinkClass ~= "") and (sLinkRecord ~= "") then
			ctrlCaption.setUnderline(true);
			win.createControl("caption_clickcapture_refblock", "captionlink");
		end
	end
end

function addText(win, sAlign, bUseSecondField)
	local node = win.getDatabaseNode();

	local sFrame = DB.getValue(node, "frame", "");
	if sAlign == "left" or sFrame == "noframe" then
		sFrame = "";
	end

	local sName = "text";
	if bUseSecondField then
		sName = "text2";
	end
	
	local ctrl = win.createControl("ft_refblock", sName);
	
	if sFrame ~= "" then
		if sAlign == "left" then
			ctrl.setAnchor("left", "", "left", "absolute", m_nTextWithFrameOffsetX);
			ctrl.setAnchor("right", "", "center", "absolute", -m_nTextWithFrameOffsetX);
		elseif sAlign == "right" then
			ctrl.setAnchor("left", "", "center", "absolute", m_nTextWithFrameOffsetX);
			ctrl.setAnchor("right", "", "right", "absolute", -m_nTextWithFrameOffsetX);
		else
			ctrl.setAnchor("left", "", "left", "absolute", m_nTextWithFrameOffsetX);
			ctrl.setAnchor("right", "", "right", "absolute", -m_nTextWithFrameOffsetX);
		end
		
		ctrl.setAnchor("top", "", "top", "absolute", m_nFrameOffsetY);
		ctrl.setFrame("referenceblock-" .. sFrame, m_nFrameOffsetX, m_nFrameOffsetY, m_nFrameOffsetX, m_nFrameOffsetY);
		
		local ctrlSpacer = win.createControl("spacer_refblock", "");
		ctrlSpacer.setAnchor("top", sName, "bottom", "absolute", 0);
		ctrlSpacer.setAnchor("left", sName, "left", "absolute", 0);
		ctrlSpacer.setAnchor("right", sName, "right", "absolute", 0);
		ctrlSpacer.setVisible(true);
	else
		if sAlign == "left" then
			ctrl.setAnchor("right", "", "center", "absolute", -m_nTextSansFrameOffsetX);
		elseif sAlign == "right" then
			ctrl.setAnchor("left", "", "center", "absolute", m_nTextSansFrameOffsetX);
		end
	end
	
	local sGraphicType = getGraphicType(node);
	if sGraphicType ~= "" then
		local nGraphicWidth = getGraphicDimensions(win, sAlign);
		local nOffset = nGraphicWidth + (2*m_nGraphicOffsetX);
		if sFrame ~= "" then
			nOffset = nOffset + (m_nTextWithFrameOffsetX - m_nTextSansFrameOffsetX);
		end
		if sAlign == "left" then
			ctrl.setAnchor("right", "", "right", "absolute", -nOffset);
		elseif sAlign == "right" then
			ctrl.setAnchor("left", "", "left", "absolute", nOffset);
		end
	end

	ctrl.setVisible(true);
end

function addHeader(win)
	local node = win.getDatabaseNode();

	local sName = "text";
	local sFrame = DB.getValue(node, "frame", "");
	if sFrame == "noframe" then
		sFrame = "";
	end
	
	local ctrl = win.createControl("header_refblock", sName);
	
	if sFrame ~= "" then
		ctrl.setAnchor("left", "", "left", "absolute", m_nHeaderWithFrameOffsetX);
		ctrl.setAnchor("right", "", "right", "absolute", -m_nHeaderWithFrameOffsetX);
		ctrl.setAnchor("top", "", "top", "absolute", m_nHeaderFrameOffsetY);
		ctrl.setFrame("referenceblock-" .. sFrame, m_nHeaderFrameOffsetX, m_nHeaderFrameOffsetY, m_nHeaderFrameOffsetX, m_nHeaderFrameOffsetY);
		
		local ctrlSpacer = win.createControl("spacer_refblock", "");
		ctrlSpacer.setAnchor("top", sName, "bottom", "absolute", 0);
		ctrlSpacer.setAnchor("left", sName, "left", "absolute", 0);
		ctrlSpacer.setAnchor("right", sName, "right", "absolute", 0);
		ctrlSpacer.setVisible(true);
	end
	
	ctrl.setVisible(true);
end

function buildBlock(win)
	local node = win.getDatabaseNode();

	local sBlockType = DB.getValue(node, "blocktype", "");
	if sBlockType == "header" then
		addHeader(win);
	else
		local sGraphicType = getGraphicType(node);
		local sAlign = DB.getValue(node, "align", "");
		local aAlign = StringManager.split(sAlign, ",");

		-- Single column
		if #aAlign <= 1 then
			if sGraphicType == "token" then
				addPicture(win, "center");
			elseif sGraphicType == "image" then
				addImage(win, "center");
			elseif sGraphicType == "icon" then
				addIcon(win, "center");
			else
				addText(win, "center");
			end
		-- Dual columns
		elseif #aAlign >= 2 then
			addText(win, aAlign[1]);
			
			if sGraphicType == "token" then
				addPicture(win, aAlign[2]);
			elseif sGraphicType == "image" then
				addImage(win, aAlign[2]);
			elseif sGraphicType == "icon" then
				addIcon(win, aAlign[2]);
			else
				addText(win, aAlign[2], true);
			end
		end
	end
end

function getGraphicType(node)
	local sBlockType = DB.getValue(node, "blocktype", "");
	if sBlockType:match("picture") then
		return "token";
	elseif sBlockType:match("image") then
		return "image";
	elseif sBlockType:match("icon") then
		return "icon";
	end
	return "";
end

function getGraphicDimensions(win, sAlign) 
	local sSizeData = DB.getValue(win.getDatabaseNode(), "size", "");
	local sSizeDataW, sSizeDataH = sSizeData:match("(%d+),(%d+)");

	local w = tonumber(sSizeDataW) or 100;
	local h = tonumber(sSizeDataH) or 100;

	if sAlign == "left" or sAlign == "right" then
		if w > 300 then
			local scale = w / 300;
			w = 300;
			h = h / scale;
		end
	end

	return w, h;
end
