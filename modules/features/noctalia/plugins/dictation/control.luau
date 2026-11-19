--!nonstrict

function onIpc(event, payload)
	if event == "text" then
		noctalia.state.set("text", payload)
		noctalia.layer.show("transcript")
	elseif event == "hide" then
		noctalia.layer.hide("transcript")
	end
end
