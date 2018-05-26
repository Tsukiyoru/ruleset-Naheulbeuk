-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function checkData()
	if label.getValue() ~= DB.getValue(getDatabaseNode(), "label", "") then
		label.setValue(label.getValue());
	end
end

function actionDrag(draginfo)
	checkData();
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	if not rEffect or (rEffect.sName or "") == "" then
		return true;
	end
	return ActionEffect.performRoll(draginfo, nil, rEffect);
end

function action()
	checkData();
	local rEffect = EffectManager.getEffect(getDatabaseNode());
	if not rEffect or (rEffect.sName or "") == "" then
		return true;
	end
	local rRoll = ActionEffect.getRoll(nil, nil, rEffect);
	if not rRoll then
		return true;
	end
	
	rRoll.sType = "effect";

	local rTarget = nil;
	if User.isHost() then
		rTarget = ActorManager.getActorFromCT(CombatManager.getActiveCT());
	else
		rTarget = ActorManager.getActor("pc", CombatManager.getCTFromNode("charsheet." .. User.getCurrentIdentity()));
	end
	
	ActionsManager.resolveAction(nil, rTarget, rRoll);
	return true;
end

function onGainFocus()
	window.setFrame("rowshade");
end

function onLoseFocus()
	window.setFrame(nil);
end
