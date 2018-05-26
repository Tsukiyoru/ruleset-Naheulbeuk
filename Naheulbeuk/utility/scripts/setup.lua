-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local nStep = 1;

function onButtonPrev()
	nStep = math.max(1, math.min(4, nStep - 1));
	if not User.isHost() and (nStep == 3) then
		nStep = 2;
	end
	updateDisplay();
end
function onButtonNext()
	nStep = math.max(1, math.min(4, nStep + 1));
	if not User.isHost() and (nStep == 3) then
		nStep = 4;
	end
	updateDisplay();
end
function updateDisplay()
	local bStep2 = (nStep == 2);
	local bStep3 = (nStep == 3);
	local bStep4 = (nStep == 4);
	local bStep1 = (not bStep2 and not bStep3 and not bStep4);
	
	step1.setVisible(bStep1);
	step2.setVisible(bStep2);
	step3.setVisible(bStep3);
	step4.setVisible(bStep4);
	
	button_prev.setVisible(not bStep1);
	button_next.setVisible(not bStep4);
	button_finish.setVisible(bStep4);
end
