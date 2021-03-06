--GMGram
util.AddNetworkString("GMGramClientTookPicture")
util.AddNetworkString("GMGramOpenClientMenu")
util.AddNetworkString("GMGramKillNotification")
util.AddNetworkString("GMGramClientNotify")

local GMGramVersion = "1.1.0"

GMGramErrorTable = {
	{"ID WRONG/NOT FOUND SERVER", "Server not found/The ID is wrong. (please report this message to a server administrator)", false},
	{"BANNED.", "You are banned from posting.", false},
	{"Found Server", "This isnt an error.", false},
	{"ALREADY EXISTING BABE", "Cannot send a photo due to an exisiting photo is already pending.", false},
	{"FAQ", "DB Failed. (please report this message to a server administrator)", false},
	{"PASS WRONG", "Password is wrong (please report this message to a server administrator)", false},
	{"Works lol", "Success! Your photo has been posted please verify your photo now!", true}
}

hook.Add( "InitPostEntity", "GMGramInitPostEntity", function()
	timer.Simple(10, function()
		MsgC(Color(255,0,0), "[", Color(255,255,255), "GMGram", Color(255,0,0), "] ", Color(0,255,0), "GMGram stat running\n")
		http.Post("http://xxlmm13xxgaming.com/addons/data/serveradd.php",{sid = "gmgram", sip = game.GetIPAddress(), sdate=tostring(os.time()), soid = "nil"},function(body)
			MsgC(Color(255,0,0), "[", Color(255,255,255), "GMGram", Color(255,0,0), "] ", Color(0,255,0), body.."\n")
		end,function(error)
			print(error)
		end)
		MsgC(Color(255,0,0), "[", Color(255,255,255), "GMGram", Color(255,0,0), "] ", Color(0,255,0), "GMGram checking version...\n")
		http.Fetch("https://raw.githubusercontent.com/XxLMM13xXgaming/gmgram/master/version.txt", function(body, len, headers, code, ply)
			if (string.Trim(body) ~= GMGramVersion) then
				MsgC(Color(255,0,0), "[", Color(255,255,255), "GMGram", Color(255,0,0), "] ", Color(0,255,0), "You are using an outdated version! Please update here: https://github.com/XxLMM13xXgaming/gmgram\n")
			else
				MsgC(Color(255,0,0), "[", Color(255,255,255), "GMGram", Color(255,0,0), "] ", Color(0,255,0), "You are using the updated version!\n")
			end
		end,function()
			-- SHhh
		end)
	end)
end)

function net.ReceiveGMGramChunk(id, func, callback) -- Thanks to Author. (STEAM_0:0:58068155) for these chunk functions :D
	local chunks = chunks or {}
	local counted = false
	local count

	net.Receive(id, function(len, server)
		if not counted then
			count = net.ReadInt(32)
			if count then
				counted = true
				return
			end
		end

		local chunk = net.ReadData(( len - 1 ) / 8)
		local last_chunk = net.ReadBit() == 1

		if callback then
			callback(count, #chunks+1)
		end

		table.insert(chunks, chunk)

		if last_chunk then
			local data = table.concat(chunks)
			func(data, server)

			chunks = {}
			counted = false
			count = nil
		end
	end)
end

function GMGramNotify(ply, type, message)
  if ply == "*" then
    net.Start("GMGramClientNotify")
      net.WriteFloat(type)
      net.WriteString(message)
    net.Broadcast()
  else
    net.Start("GMGramClientNotify")
      net.WriteFloat(type)
      net.WriteString(message)
    net.Send(ply)
  end
end

-- When a person says !gmgram
hook.Add("PlayerSay", "GMGramAddonCommands", function(ply, text)
  local text = string.lower(text)
  if text:lower():match('[!/:.]gmgram') then
    net.Start("GMGramOpenClientMenu")
      net.WriteBool(GMGramConfig.TakeCodeFromInternet)
    net.Send(ply)
    return ''
  end
end)

-- When the person takes a picture
net.ReceiveGMGramChunk("GMGramClientTookPicture",function(data, ply)
  local gmgrampic = data

  if ply.GMGramPlayerOnCooldown then
    GMGramNotify(ply, 3, "You are on cool down please wait "..GMGramConfig.CooldownTime.." minute(s)!")
    return
  end
 
  http.Post ("https://gmgram.com/auth/auth32.php", {picture=gmgrampic, pass=GMGramConfig.Password, steamid64=ply:SteamID64(), IDs=GMGramConfig.ServerID},function( body, len, headers, code)
    ply.GMGramPlayerOnCooldown = true
    timer.Simple(GMGramConfig.CooldownTime, function()
      ply.GMGramPlayerOnCooldown = false
    end)

		local msgfound = false
		for k, v in pairs(GMGramErrorTable) do
			if body == v[1] then
				msgfound = true
				if v[3] then
					GMGramNotify(ply, 2, v[2])
		      ply:SendLua( "gui.OpenURL( 'http://gmgram.com/confirm' )" )
				else
					GMGramNotify(ply, 3, v[2])
					if GMGramConfig.DevMode then
		          MsgC(GMGramClientConfig.ErrorColor, "GMGram Error body printing...\n\n")
		            print(body)
		          Msg("\n")
		          MsgC(GMGramClientConfig.ErrorColor, "GMGram Error body printed...\n\n")
		      end
				end
			end
		end

		if !msgfound then
			GMGramNotify(ply, 3, "An unknown error has occured. Please report this message to an administrator... (nomsgfound)")
      if GMGramConfig.DevMode then
        MsgC(GMGramClientConfig.ErrorColor, "GMGram Error body printing...\n\n")
          print(body)
        MsgC("\n", GMGramClientConfig.ErrorColor, "GMGram Error body printed...\n\n")
      end
		end
  end, function()
		GMGramNotify(ply, 3, "An unknown error has occured. Please report this message to an administrator... (webfunctionerror)")
		MsgC(GMGramClientConfig.ErrorColor, "GMGram Error body printing...\n\n")
			print(error)
		MsgC("\n", GMGramClientConfig.ErrorColor, "GMGram Error body printed...\n\n")
  end)
end)

-- Timer to advert the addon and get people to upload pictures!
timer.Create("GMGramRunningOnServer",1800,0,function()
  GMGramNotify("*", 2, "This server is running GMGram")
end)
