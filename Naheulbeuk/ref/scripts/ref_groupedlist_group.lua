-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function showFullHeaders(bShow)
	groupframe.setVisible(bShow);
	group.setVisible(bShow);
end

local bSortEnabled = false;
function initialize()
	bSortEnabled = true;
	list.applySort();
end

local aSortOrder = {};
local aSortDesc = {};
function setColumnInfo(aColumns)
	for _,rColumn in ipairs(aColumns) do
		if (rColumn.nSortOrder or 0) > 0 then
			aSortOrder[rColumn.nSortOrder] = rColumn.sName;
			aSortDesc[rColumn.nSortOrder] = rColumn.bSortDesc;
		end
	end
	for _,rColumn in ipairs(aColumns) do
		if (rColumn.nSortOrder or 0) <= 0 then
			aSortOrder[#aSortOrder + 1] = rColumn.sName;
			aSortDesc[#aSortOrder] = rColumn.bSortDesc;
		end
	end
end
function onSortCompare(w1, w2)
	if not bSortEnabled then
		return;
	end
	
	for k,v in ipairs(aSortOrder) do
		local vw1 = w1[v].getValue();
		local vw2 = w2[v].getValue();
		if vw1 ~= vw2 then
			if aSortDesc[k] then
				return vw1 < vw2;
			else
				return vw1 > vw2;
			end
		end
	end
end
