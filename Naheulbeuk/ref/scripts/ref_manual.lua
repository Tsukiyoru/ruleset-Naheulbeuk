-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local m_sCurrentPage = "";

local m_sIndexPath = "";
local m_sPrevPath = "";
local m_sNextPath = "";

function activateLink(sClass, sRecord)
	if sClass == "reference_manualtextwide" or sClass == "referencemanualpage" then
		local nodeRecord = DB.findNode(sRecord);
		if nodeRecord then
			if nodeRecord.getModule() == getDatabaseNode().getModule() then
				pagelist.closeAll();
				pagelist.createWindowWithClass("reference_manualtextwide", sRecord); 
				pagelist.setScrollPosition(0,0);
				
				m_sCurrentPage = sRecord;
				
				local sModule = getDatabaseNode().getModule();
				ReferenceManualManager.init(sModule, m_sCurrentPage);
				m_sIndexPath = ReferenceManualManager.getIndexRecord(sModule) or "";
				m_sPrevPath = ReferenceManualManager.getPrevRecord(sModule, m_sCurrentPage) or "";
				m_sNextPath = ReferenceManualManager.getNextRecord(sModule, m_sCurrentPage) or "";

				page_top.setVisible(m_sIndexPath ~= "");
				page_prev.setVisible(m_sPrevPath ~= "");
				page_next.setVisible(m_sNextPath ~= "");
				return;
			end
			local nodeParent = nodeRecord.getParent();
			if nodeParent and nodeParent.getPath():sub(1,23) == "reference.refmanualdata" then
				local w = Interface.openWindow("reference_manual", "reference.refmanualindex@" .. nodeRecord.getModule());
				w.activateLink(sClass, sRecord);
				return;
			end
		end
	end
	if sClass == "reference_manualtextwide" then
		sClass = "referencemanualpage";
	end
	Interface.openWindow(sClass, sRecord);
end

function handlePageTop()
	if m_sIndexPath ~= "" then
		activateLink("reference_manualtextwide", m_sIndexPath);
	end
end

function handlePagePrev()
	if m_sPrevPath ~= "" then
		activateLink("reference_manualtextwide", m_sPrevPath);
	end
end

function handlePageNext()
	if m_sNextPath ~= "" then
		activateLink("reference_manualtextwide", m_sNextPath);
	end
end

