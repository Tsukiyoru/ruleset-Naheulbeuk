-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	if GameSystem.currencyDefault then
		setDefaultCurrency(GameSystem.currencyDefault);
	end
end

-- NOTE: Assumes field is a child of each item record, and is a string data type.
local sItemCostField = "cost";
function setItemCostField(sField)
	sItemCostField = sField;
end
local sItemCostCurrency = "";
function setDefaultCurrency(s)
	sItemCostCurrency = s;
end

--
-- DROP HANDLING
--

function addItem(sClass, nodeSource, bTransferAll)
	Debug.console('DEPRECATED (v3.2.0) (PartyLootManager.addItem): Use ItemManager.handleItem("partysheet", nil, sClass, sRecord, bTransferAll)');
	ItemManager.handleItem("partysheet", nil, sClass, nodeSource, bTransferAll);
end

--
-- DISTRIBUTION
--

function distribute()
	distributeParcelAssignments();
	distributeParcelCoins();
end

function distributeParcelAssignments()
	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local rMember = {};
				rMember.name = StringManager.trim(DB.getValue(v, "name", ""));
				rMember.node = nodePC;
				rMember.given = {};
				
				table.insert(aParty, rMember);
			end
		end
	end
	if #aParty == 0 then
		return;
	end

	-- Add assigned items to party members
	local nItems = 0;
	local aItemsAssigned = {};
	for _,vItem in pairs(DB.getChildren("partysheet.treasureparcelitemlist")) do
		local sItem = DB.getValue(vItem, "name", "");
		local nCount = math.max(DB.getValue(vItem, "count", 0), 1);
		if sItem ~= "" and nCount > 0 then
			nItems = nItems + 1;

			local sAssign = DB.getValue(vItem, "assign", "");
			if sAssign ~= "" then
				local aSplit = StringManager.split(sAssign, ",;\r", true);
				if #aSplit > nCount then
					ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] " .. Interface.getString("ps_message_itemfailtoomanyassign") .. " (" .. sAssign .. ")");
					break;
				end

				local aAssigned = {};
				for _,vAssign in ipairs(aSplit) do
					local rMember = nil;
					for _,vMember in ipairs(aParty) do
						if vAssign == vMember.name then
							rMember = vMember;
						end
					end
					if rMember then
						table.insert(aAssigned, rMember);
					else
						ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] " .. Interface.getString("ps_message_itemfailcharmissing") .. " (" .. vAssign .. ")");
					end
				end
				
				local nAssign = math.floor (nCount / #aSplit);
				if #aAssigned > 0 then
					local aFailedAssign = {};
					local sClass = "item";
					if ItemManager2 and ItemManager2.getItemClass then
						sClass = ItemManager2.getItemClass(vItem);
					end
					for _,vMember in ipairs(aAssigned) do
						local sList = "inventorylist";
						if ItemManager2 and ItemManager2.getCharItemListPath then
							sList = ItemManager2.getCharItemListPath(vMember.node, sClass);
						end
						nodeItem = ItemManager.addItemToList(DB.getPath(vMember.node, sList), sClass, vItem, false, nAssign);
						if nodeItem then
							table.insert(aItemsAssigned, { item = ItemManager.getDisplayName(nodeItem), name = vMember.name });
						else
							table.insert(aFailedAssign, vMember.name);
						end
					end
					
					local sFailedAssign = table.concat(aFailedAssign, ", ");
					DB.setValue(vItem, "assign", "string", sFailedAssign);
					if #aFailedAssign > 0 then
						ChatManager.SystemMessage("[" .. Interface.getString("tag_warning") .. "] " .. Interface.getString("ps_message_itemfailcreate") .. " (" .. sFailedAssign .. ")");
					end
				end
			end
		end
	end
	if nItems == 0 then
		return;
	end
	
	-- Output item assignments and rebuild party inventory
	local msg = {font = "msgfont", icon = "portrait_gm_token"};
	if #aItemsAssigned > 0 then
		msg.text = Interface.getString("ps_message_itemdistributesuccess");
		Comm.deliverChatMessage(msg);

		buildPartyInventory();
	else
		msg.text = Interface.getString("ps_message_itemdistributeempty");
		Comm.addChatMessage(msg);
	end
end

function distributeParcelCoins() 
	-- Determine coins in parcel
	local aParcelCoins = {};
	local nCoinEntries = 0;
	for _,vCoin in pairs(DB.getChildren("partysheet.treasureparcelcoinlist")) do
		local sCoin = DB.getValue(vCoin, "description", ""):upper();
		local nCount = DB.getValue(vCoin, "amount", 0);
		if sCoin ~= "" and nCount > 0 then
			aParcelCoins[sCoin] = (aParcelCoins[sCoin] or 0) + nCount;
			nCoinEntries = nCoinEntries + 1;
		end
	end
	if nCoinEntries == 0 then
		return;
	end
	
	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local rMember = {};
				
				rMember.name = StringManager.trim(DB.getValue(v, "name", ""));
				rMember.node = nodePC;
				rMember.given = {};
				
				table.insert(aParty, rMember);
			end
		end
	end
	if #aParty == 0 then
		return;
	end
	
	-- Add party member split to their character sheet
	for sCoin, nCoin in pairs(aParcelCoins) do
		local nAverageSplit;
		if nCoin >= #aParty then
			nAverageSplit = math.floor(nCoin / #aParty);
		else
			nAverageSplit = 0;
		end
		
		for k,v in ipairs(aParty) do
			local nAmount = nAverageSplit;
			
			if nAmount > 0 then
				-- Add distribution amount to character
				addCoinsToPC(v.node, sCoin, nAmount);
				
				-- Track distribution amount for output message
				v.given[sCoin] = nAmount;
			end
		end
	end
	
	-- Output coin assignments
	local aPartyAmount = {};
	for sCoin, nCoin in pairs(aParcelCoins) do
		local nCoinGiven = nCoin - (nCoin % #aParty);
		table.insert(aPartyAmount, tostring(nCoinGiven) .. " " .. sCoin);
	end

	local msg = {font = "msgfont"};
	
	msg.icon = "coins";
	for _,v in ipairs(aParty) do
		local aMemberAmount = {};
		for sCoin, nCoin in pairs(v.given) do
			table.insert(aMemberAmount, tostring(nCoin) .. " " .. sCoin);
		end
		msg.text = "[" .. table.concat(aMemberAmount, ", ") .. "] -> " .. v.name;
		Comm.deliverChatMessage(msg);
	end
	
	msg.icon = "portrait_gm_token";
	msg.text = Interface.getString("ps_message_coindistributesuccess") .. " [" .. table.concat(aPartyAmount, ", ") .. "]";
	Comm.deliverChatMessage(msg);

	-- Reset parcel and party coin amounts
	for _,vCoin in pairs(DB.getChildren("partysheet.treasureparcelcoinlist")) do
		local nCoin = DB.getValue(vCoin, "amount", 0);
		nCoin = nCoin % #aParty;
		DB.setValue(vCoin, "amount", "number", nCoin);
	end
	buildPartyCoins();
end

--
-- PARTY INVENTORY VIEWING
--

function rebuild()
	buildPartyInventory();
	buildPartyCoins();
end

function buildPartyInventory()
	for _,vItem in pairs(DB.getChildren("partysheet.inventorylist")) do
		vItem.delete();
	end

	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local sName = StringManager.trim(DB.getValue(v, "name", ""));
				table.insert(aParty, { name = sName, node = nodePC } );
			end
		end
	end
	
	-- Build a database of party inventory items
	local aInvDB = {};
	for _,v in ipairs(aParty) do
		local aCharItemListPaths = { "inventorylist" };
		if ItemManager2 and ItemManager2.getCharItemListPaths then
			aCharItemListPaths = ItemManager2.getCharItemListPaths(v.node);
		end
		for _,sListPath in pairs(aCharItemListPaths) do
			for _,nodeItem in pairs(DB.getChildren(v.node, sListPath)) do
				local sItem = ItemManager.getDisplayName(nodeItem, true);
				if sItem ~= "" then
					local nCount = math.max(DB.getValue(nodeItem, "count", 0), 1)
					if aInvDB[sItem] then
						aInvDB[sItem].count = aInvDB[sItem].count + nCount;
					else
						local aItem = {};
						aItem.count = nCount;
						aInvDB[sItem] = aItem;
					end
					
					if not aInvDB[sItem].carriedby then
						aInvDB[sItem].carriedby = {};
					end
					aInvDB[sItem].carriedby[v.name] = ((aInvDB[sItem].carriedby[v.name]) or 0) + nCount;
				end
			end
		end
	end
	
	-- Create party sheet inventory entries
	for sItem, rItem in pairs(aInvDB) do
		local vGroupItem = DB.createChild("partysheet.inventorylist");
		DB.setValue(vGroupItem, "count", "number", rItem.count);
		DB.setValue(vGroupItem, "name", "string", sItem);
		
		local aCarriedBy = {};
		for k,v in pairs(rItem.carriedby) do
			table.insert(aCarriedBy, string.format("%s [%d]", k, math.floor(v)));
		end
		DB.setValue(vGroupItem, "carriedby", "string", table.concat(aCarriedBy, ", "));
	end
end

function buildPartyCoins()
	for _,vCoin in pairs(DB.getChildren("partysheet.coinlist")) do
		vCoin.delete();
	end

	-- Determine members of party
	local aParty = {};
	for _,v in pairs(DB.getChildren("partysheet.partyinformation")) do
		local sClass, sRecord = DB.getValue(v, "link");
		if sClass == "charsheet" and sRecord then
			local nodePC = DB.findNode(sRecord);
			if nodePC then
				local sName = StringManager.trim(DB.getValue(v, "name", ""));
				table.insert(aParty, { name = sName, node = nodePC } );
			end
		end
	end
	
	-- Build a database of party coins
	local aCoinDB = {};
	for _,v in ipairs(aParty) do
		for _,nodeCoin in pairs(DB.getChildren(v.node, "coins")) do
			local sCoin = DB.getValue(nodeCoin, "name", ""):upper();
			if sCoin ~= "" then
				local nCount = DB.getValue(nodeCoin, "amount", 0);
				if nCount > 0 then
					if aCoinDB[sCoin] then
						aCoinDB[sCoin].count = aCoinDB[sCoin].count + nCount;
						aCoinDB[sCoin].carriedby = string.format("%s, %s [%d]", aCoinDB[sCoin].carriedby, v.name, math.floor(nCount));
					else
						local aCoin = {};
						aCoin.count = nCount;
						aCoin.carriedby = string.format("%s [%d]", v.name, math.floor(nCount));
						aCoinDB[sCoin] = aCoin;
					end
				end
			end
		end
	end
	
	-- Create party sheet coin entries
	for sCoin, rCoin in pairs(aCoinDB) do
		local vGroupItem = DB.createChild("partysheet.coinlist");
		DB.setValue(vGroupItem, "amount", "number", rCoin.count);
		DB.setValue(vGroupItem, "name", "string", sCoin);
		DB.setValue(vGroupItem, "carriedby", "string", rCoin.carriedby);
	end
end

--
-- SELL ITEMS
--

function sellItems()
	local nItemTotal = 0;
	local aSellTotal = {};
	local nSellPercentage = DB.getValue("partysheet.sellpercentage");
	
	for _,vItem in pairs(DB.getChildren("partysheet.treasureparcelitemlist")) do
		local sItem = DB.getValue(vItem, "name", "");
		local sAssign = StringManager.trim(DB.getValue(vItem, "assign", ""));
		if sAssign == "" then
			local nCoin = 0;

			local sCost = DB.getValue(vItem, sItemCostField, "");
			local sCoinValue, sCoin = string.match(sCost, "^%s*([%d,]+)%s*([^%d]*)$");
			if not sCoinValue then -- look for currency prefix instead
				sCoin, sCoinValue = string.match(sCost, "^%s*([^%d]+)%s*([%d,]+)%s*$");
			end
			if sCoinValue then
				sCoinValue = string.gsub(sCoinValue, ",", "");
				nCoin = tonumber(sCoinValue) or 0;
				
				sCoin = StringManager.trim(sCoin);
				if sCoin == "" and sItemCostCurrency ~= "" then
					sCoin = sItemCostCurrency;
				end
			end
			
			if nCoin == 0 then
				local msg = {font = "systemfont"};
				msg.text = Interface.getString("ps_message_itemsellcostmissing") .. " [" .. sItem .. "]";
				Comm.addChatMessage(msg);
			else
				local nCount = math.max(DB.getValue(vItem, "count", 1), 1);
				local nItemSellTotal = math.floor(nCount * nCoin * nSellPercentage / 100);
				if nItemSellTotal <= 0 then
					local msg = {font = "systemfont"};
					msg.text = Interface.getString("ps_message_itemsellcostlow") .. " [" .. sItem .. "]";
					Comm.addChatMessage(msg);
				else
					ItemManager.handleCurrency("partysheet", sCoin, nItemSellTotal);
					aSellTotal[sCoin] = (aSellTotal[sCoin] or 0) + nItemSellTotal;
					nItemTotal = nItemTotal + nCount;
					
					vItem.delete();

					local msg = {font = "msgfont"};
					msg.text = Interface.getString("ps_message_itemsellsuccess") .. " [";
					if nCount > 1 then
						msg.text = msg.text .. "(" .. nCount .. "x) ";
					end
					msg.text = msg.text .. sItem .. "] -> [" .. nItemSellTotal;
					if sCoin ~= "" then
						msg.text = msg.text .. " " .. sCoin;
					end
					msg.text = msg.text .. "]";
					
					Comm.deliverChatMessage(msg);
				end
			end
		end
	end

	if nItemTotal > 0 then
		local aTotalOutput = {};
		for k,v in pairs(aSellTotal) do
			table.insert(aTotalOutput, tostring(v) .. " " .. k);
		end
		local msg = {font = "msgfont"};
		msg.icon = "portrait_gm_token";
		msg.text = tostring(nItemTotal) .. " item(s) sold for [" .. table.concat(aTotalOutput, ", ") .. "]";
		Comm.deliverChatMessage(msg);
	end
end

--
-- HELPER
--

function addCoinsToPC(nodeChar, sCoin, nCoin)
	local nodeTarget = nil;
	
	-- Check for existing coin match
	for i = 1,6 do
		local sNodeCoin = "coins.slot" .. i;
		local sCharCoin = DB.getValue(nodeChar, sNodeCoin .. ".name", ""); 
		if sCharCoin:upper() == sCoin:upper() then
			nodeTarget = DB.getChild(nodeChar, sNodeCoin);
			break;
		end
	end
	
	-- If no match to existing coins, then find first empty slot
	if not nodeTarget then
		for i = 1,6 do
			local sNodeCoin = "coins.slot" .. i;
			local sCharCoin = StringManager.trim(DB.getValue(nodeChar, sNodeCoin .. ".name", ""));
			local nCharAmt = DB.getValue(nodeChar, sNodeCoin .. ".amount", 0);
			if sCharCoin == "" and nCharAmt == 0 then
				nodeTarget = DB.getChild(nodeChar, sNodeCoin);
				break;
			end
		end
	end
	
	-- If we have a match or an empty slot, then add the currency
	if nodeTarget then
		local nNewAmount = DB.getValue(nodeTarget, "amount", 0) + nCoin;
		DB.setValue(nodeTarget, "amount", "number", nNewAmount);
		DB.setValue(nodeTarget, "name", "string", sCoin);
	-- Otherwise, add to the other area
	else
		local sCoinOther = DB.getValue(nodeChar, "coinother", "");
		if sCoinOther ~= "" then
			sCoinOther = sCoinOther .. ", ";
		end
		sCoinOther = sCoinOther .. nCoin .. " " .. sCoin;
		DB.setValue(nodeChar, "coinother", "string", sCoinOther);
	end
end
