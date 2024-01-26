--- // Services // ---

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local DataStoreService = game:GetService('DataStoreService')
local RunService = game:GetService('RunService')

--- // Folders & Folders Objects // ---

local ConfigurationsFolder = ReplicatedStorage:WaitForChild('Configurations')
local ModulesFolder = ReplicatedStorage:WaitForChild('Modules')
local MapsFolder = ReplicatedStorage:WaitForChild('Maps')
local RemotesFolder = ReplicatedStorage:WaitForChild('Remotes')

local DisplayConfigs = ConfigurationsFolder:WaitForChild('DisplayConfigs')
local GameConfigs = ConfigurationsFolder:WaitForChild('GameConfigs')
local MatchConfigs = ConfigurationsFolder:WaitForChild('MatchConfigs')
local TimerConfigs = ConfigurationsFolder:WaitForChild('TimerConfigs')

local TimeLeft = DisplayConfigs:WaitForChild('TimeLeft')
local Objective = DisplayConfigs:WaitForChild('Objective')

local IsIntermissionCountingDown = GameConfigs:WaitForChild('IsIntermissionCountingDown')
local IsMatchCountingDown = GameConfigs:WaitForChild('IsMatchCountingDown')
local RequirePlayersToStart = GameConfigs:WaitForChild('RequirePlayersToStart')
local IsFinishedCountdown = GameConfigs:WaitForChild('IsFinishedCountdown')

local ChosenMap = MatchConfigs:WaitForChild('ChosenMap')
local ChosenTarget = MatchConfigs:WaitForChild('ChosenTarget')

local IntermissionStartTime = TimerConfigs:WaitForChild('IntermissionStartTime')
local MatchStartTime = TimerConfigs:WaitForChild('MatchStartTime')
local EndTime = TimerConfigs:WaitForChild('EndTime')

local SetupSignal = RemotesFolder:WaitForChild('SetupSignal')
local TransitionSignal = RemotesFolder:WaitForChild('TransitionSignal')

--- // RepStorage Assets // ---

local Tail = ReplicatedStorage:WaitForChild('Tail')

--- // Remotes // ---

local SetupSignal = RemotesFolder:WaitForChild('SetupSignal')

--- // Loaded Modules // ---

local NofiticationManager = require(ModulesFolder:WaitForChild('NofiticationManager'))
local TransitionManager = require(ModulesFolder:WaitForChild('TransitionManager'))

--- // Numbers, Booleans, Strings, Datas, & Tables // ---

local StatsDataStore = DataStoreService:GetDataStore('Store')

local IsPlayerFullyLoaded = false
local CanSetIntermissionTime = true
local CanSetMatchTime = false
local TouchDebounce = false
local IsFinishedTransition = true

local CurrentSpawnPos = nil
local PlayersSpawn = nil

local OutputMark = '[RoundSystem (Server-Side)]: '

--- // Functions, Events, & Setups // ---

Objective.Value = '!~Get ready for the next INTERMISSION~!'

local function CheckToSave()
	if #Players:GetPlayers() == 1 then
		return false
	else
		return true
	end
end

local function SaveData(Plr: Player)
	
	local data = {Plr:WaitForChild('PlayerGameStats')['TotalTailTime(s)'].Value}
	local succ, err = pcall(function()
		StatsDataStore:SetAsync(Plr.UserId, data)
	end)

	if succ then
		print(OutputMark..'Successfully saved data!!')
	else
		warn(OutputMark..'Failed to saved data -> '..tostring(err))
	end
end

local function GetRandomPlayerAndMap(GetType: string)
	print(OutputMark..'Called GetRandomPlayerAndMap function!!')
	GetType = string.lower(GetType)

	local Maps = MapsFolder:GetChildren()
	local PlayersInGame = Players:GetPlayers()

	local ChosenMap = nil
	local ChosenPlayer = nil

	if GetType == 'get_map' then
		ChosenMap = Maps[math.random(#Maps)]
		return ChosenMap
	elseif GetType == 'get_player' then
		if #PlayersInGame < 1 then
			warn(OutputMark..'Cannot get player since there are no player(s) in-game!!')
			return
		end
		ChosenPlayer = PlayersInGame[math.random(#PlayersInGame)]
		return ChosenPlayer
	elseif GetType == 'get_both' then
		if #PlayersInGame < 1 then
			warn(OutputMark..'Cannot get player since there are no player(s) in-game!!')
			return
		end
		ChosenPlayer = PlayersInGame[math.random(#PlayersInGame)]
		ChosenMap = Maps[math.random(#Maps)]
		return ChosenMap, ChosenPlayer
	end
end

local function SetupGame(Plr: Player, SetupType: string)
	SetupType = string.lower(SetupType)
	
	print(OutputMark..'Successfully called setup function. Setup type is: '..tostring(SetupType))
	
	local PlrChar = Plr.Character or Plr.CharacterAdded:Wait()
	local PlrHrp = PlrChar:WaitForChild('HumanoidRootPart') or PlrChar.PrimaryPart
	
	if SetupType == 'setup_match' then
		local RandomMap, RandomTarget = GetRandomPlayerAndMap('get_both')
		
		if RandomMap and RandomTarget and Plr then
			local RandomTargetChar = RandomTarget.Character or RandomTarget.CharacterAdded:Wait()
			
			local RandomTargetHrp = RandomTargetChar:WaitForChild('HumanoidRootPart') or RandomTargetChar.PrimaryPart
			
			if PlrChar and RandomTargetChar and PlrHrp and RandomTargetHrp then
				local ClonedMap = RandomMap:Clone()
				ClonedMap.Parent = workspace

				if ClonedMap:FindFirstChild('Spawns') then
					local MapSpawns = ClonedMap:WaitForChild('Spawns'):GetChildren()
					local RSG = math.random(#MapSpawns)
					local ChosenTargetSpawn = MapSpawns[math.clamp(math.random(RSG + 1), math.clamp(RSG + 1, 1, #MapSpawns), #MapSpawns)]
					
					PlayersSpawn = MapSpawns[RSG]
					
					PlrHrp.CFrame = PlayersSpawn.CFrame
					RandomTargetHrp.CFrame = ChosenTargetSpawn.CFrame

					print(OutputMark..'Successfully found the spawns and set the target and players spawn!!')
				else
					warn(OutputMark..'Cannot set the target and players spawn because there are no spawns in map!!')
				end

				Tail:Clone().Parent = RandomTargetChar

				local NewHighlight = Instance.new('Highlight', RandomTargetChar)
				NewHighlight.Name = 'TargetHighlighter'
				
				task.spawn(function()
					NofiticationManager.SendNofitication(RandomTarget, "You're lucky! Save that tail!", Color3.fromRGB(255, 255, 0), true)
				end)
				
				repeat task.wait()
					ChosenMap.Value = ClonedMap
					ChosenTarget.Value = RandomTarget.Name
				until ChosenMap.Value ~= nil and ChosenTarget.Value ~= '' or nil
				print(OutputMark..'Successfully finished yield to set match status values!!')
			else
				warn(OutputMark..'PlrChar, RandomTargetChar, PlrHrp, or RandomTargetHrp is nil? -> PlrChar: '..tostring(PlrChar)..', RandomTargetChar: '..tostring(RandomTargetChar)..', PlrHrp: '..tostring(PlrHrp)..', RandomTargetHrp: '..tostring(RandomTargetHrp))
			end
		else
			warn(OutputMark..'Chosen map or chosen player is nil -> RandomMap: '..tostring(RandomMap)..', RandomPlr: '..tostring(RandomTarget))
		end
	elseif SetupType == 'setup_intermission' then
		if ChosenMap.Value ~= nil and ChosenTarget.Value ~= '' then
			ChosenMap.Value:Destroy()
			ChosenTarget.Value = ''
		end
		
		for _, ObjToDestroy in workspace:GetDescendants() do
			if ObjToDestroy:IsA('Accessory') and ObjToDestroy.Name == 'Tail' then
				ObjToDestroy:Destroy()
			elseif ObjToDestroy:IsA('Highlight') and ObjToDestroy.Name == 'TargetHighlighter' then
				ObjToDestroy:Destroy()
			end
		end
		print(OutputMark..'Successfully destroyed highlighter, chosen target tail, and map!!')
		
		repeat task.wait()
			ChosenMap.Value = nil
			ChosenTarget.Value = ''
		until ChosenMap.Value == nil and ChosenTarget.Value == ''
		print(OutputMark..'Successfully yield to set map status to default!!')
		
		if CurrentSpawnPos ~= nil then
			PlrHrp.CFrame = CurrentSpawnPos
		end
	end
end

TransitionSignal.OnServerEvent:Connect(function(Plr: Player, TransitionStatus: boolean)
	IsFinishedTransition = TransitionStatus
end)

SetupSignal.OnServerEvent:Connect(function(Plr: Player, SetupType: string)
	SetupType = string.lower(SetupType)
	print(OutputMark..'Recieved signal from client to server!!')
	if Plr and type(SetupType) == 'string' then
		SetupGame(Plr, SetupType)
	else
		warn(OutputMark..'Something went wrong when recieved signal from client -> Player: '..tostring(Plr)..', SetupType: '..tostring(SetupType))
	end
end)

Players.PlayerAdded:Connect(function(Plr: Player)
	Plr.CharacterAppearanceLoaded:Connect(function()
		IsPlayerFullyLoaded = true
	end)
	
	Plr.CharacterAdded:Connect(function(Char: Model)
		task.wait()
		if Char then
			print(OutputMark..'Successfully get the player character on character added!!')
			
			local Hum = Char:WaitForChild('Humanoid') or Char:FindFirstChildWhichIsA('Humanoid')
			local Hrp = Char:WaitForChild('HumanoidRootPart') or Char.PrimaryPart
			
			if Hum and Hrp then
				print(OutputMark..'Successfully get the player Hum and Hrp!!')
				CurrentSpawnPos = Hrp.CFrame
				
				Hum.Touched:Connect(function(hitPart: BasePart)
					
					if TouchDebounce ~= false then
						TouchDebounce = false
					end
					
					if TouchDebounce == false then
						TouchDebounce = true
						local Self = Players:GetPlayerFromCharacter(Hum.Parent)
						local Target = Players:GetPlayerFromCharacter(hitPart.Parent)

						if Self and Target and IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
							local SelfChar = Hum.Parent
							local TargetChar = hitPart.Parent

							if SelfChar and TargetChar and hitPart.Parent.Name ~= Hum.Parent.Name then
								if ChosenTarget and ChosenTarget.Value ~= '' then
									if TargetChar:FindFirstChild('Tail') and Target:FindFirstChild('TargetHighlighter') and ChosenTarget.Value == TargetChar.Name then
										local TargetTail = TargetChar:FindFirstChild('Tail')
										local TargetHighlighter = Target:FindFirstChild('TargetHighlighter')

										TargetTail.Parent = SelfChar
										ChosenTarget.Value = SelfChar.Name
										TargetHighlighter:Destroy()
										local NewHighlight = Instance.new('Highlight', SelfChar)
										NewHighlight.Name = 'TargetHighlighter'

										task.spawn(function()
											NofiticationManager.SendNofitication(Self, 'Good job! Now save that tail!', Color3.fromRGB(255, 255, 0), true)
										end)

										task.spawn(function()
											NofiticationManager.SendNofitication(Target, "Don't worry, get it back again! Never give up!", Color3.fromRGB(255, 0, 0), true)
										end)

									end
								end
							end
						end
						TouchDebounce = false
					end
				end)
				
				if PlayersSpawn ~= nil and PlayersSpawn:IsA('BasePart') then
					if ChosenTarget and ChosenTarget.Value ~= '' then
						if Char:FindFirstChild('Tail') and Char.Name == ChosenTarget.Value then
							
							local NewRandomTarget = GetRandomPlayerAndMap('get_player')
							
							if NewRandomTarget and NewRandomTarget:IsA('Player') then
								print(OutputMark..'Successfully get the new target!!')
								
								local NewRandomTargetChar = NewRandomTarget.Character or NewRandomTarget.CharacterAdded:Wait()
								
								if NewRandomTargetChar then
									print(OutputMark..'Successfully get the new target char!!')
									
									Tail:Clone().Parent = NewRandomTargetChar
									
									local NewHighlight = Instance.new('Highlight', NewRandomTargetChar)
									NewHighlight.Name = 'TargetHighlighter'
									
									repeat task.wait()
										ChosenTarget.Value = NewRandomTarget.Name
									until ChosenTarget.Value ~= Char.Name
								else
									warn(OutputMark..'Failed to get new random target char -> NewRandomTargetChar: '..tostring(NewRandomTargetChar))
								end
							else
								warn(OutputMark..'new target is not a player -> NewRandomTarget'..tostring(NewRandomTarget))
							end
							
						end
					end
					
					Hrp.CFrame = PlayersSpawn.CFrame
				end
			else
				warn(OutputMark..'Failed to get the player Hum and Hrp!!')
			end
		else
			warn(OutputMark..'Failed to get the player character on character added!!')
		end
	end)
	
	local PlayerStats = Instance.new('Folder', Plr)
	PlayerStats.Name = 'PlayerGameStats'
	
	local CurrentTailTime = Instance.new('IntValue', PlayerStats)
	CurrentTailTime.Name = 'CurrentTailTime(s)'
	CurrentTailTime.Value = 0
	
	local TotalTailTime = Instance.new('IntValue', PlayerStats)
	TotalTailTime.Name = 'TotalTailTime(s)'
	TotalTailTime.Value = 0
	
	task.spawn(function()
		while task.wait() do
			for _, tail in workspace:GetDescendants() do
				if tail:IsA('Accessory') and tail.Name == 'Tail' and IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
					local TailOwner = Players:GetPlayerFromCharacter(tail.Parent)
					
					if TailOwner then
						
						local StatsFolder = TailOwner:WaitForChild('PlayerGameStats')
						
						if StatsFolder and StatsFolder:IsA('Folder') then
							
							local PlrCurrentTailTime = StatsFolder:WaitForChild('CurrentTailTime(s)')
							local PlrTotalTailTime = StatsFolder:WaitForChild('TotalTailTime(s)')
							
							task.wait(1)
							if PlrTotalTailTime and PlrCurrentTailTime and PlrTotalTailTime:IsA('IntValue') and PlrCurrentTailTime:IsA('IntValue') then
								PlrTotalTailTime.Value += 1
								PlrCurrentTailTime.Value += 1
							end
						end
					end
				end
			end
		end
	end)
	
	local data
	local succ, err = pcall(function()
		data = StatsDataStore:GetAsync(Plr.UserId)
	end)
	
	if succ then
		if data ~= nil then
			TotalTailTime.Value = data[1]
		end
	end
end)

Players.PlayerRemoving:Connect(function(Plr: Player)
	Plr.CharacterRemoving:Connect(function(Char: Model)
		
		if IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
			if Char:FindFirstChild('Tail') and Char.Name == ChosenTarget.Value and #Players:GetPlayers() >= RequirePlayersToStart.Value then
				local NewRandomTarget = GetRandomPlayerAndMap('get_player')

				if NewRandomTarget and NewRandomTarget:IsA('Player') then
					print(OutputMark..'Successfully get the new target!!')

					local NewRandomTargetChar = NewRandomTarget.Character or NewRandomTarget.CharacterAdded:Wait()

					if NewRandomTargetChar then
						print(OutputMark..'Successfully get the new target char!!')

						if Char:FindFirstChild('Tail') then
							print(OutputMark..'Insert tail through the old target char!!')
							Char:FindFirstChild('Tail').Parent = NewRandomTargetChar
						else
							print(OutputMark..'Insert tail through the RepStorage!!')
							Tail:Clone().Parent = NewRandomTargetChar
						end

						local NewHighlight = Instance.new('Highlight', NewRandomTargetChar)
						NewHighlight.Name = 'TargetHighlighter'

						repeat task.wait()
							ChosenTarget.Value = NewRandomTarget.Name
						until ChosenTarget.Value ~= Char.Name
					else
						warn(OutputMark..'Failed to get new random target char -> NewRandomTargetChar: '..tostring(NewRandomTargetChar))
					end
				else
					warn(OutputMark..'new target is not a player -> NewRandomTarget'..tostring(NewRandomTarget))
				end
			end
		end
	end)
	
	if CheckToSave() == true then
		SaveData(Plr)
	end
end)

game:BindToClose(function()
	print(OutputMark..'Run bind to close function for emergency data save!!')
	for _, player in Players:GetPlayers() do
		SaveData(player)
	end
end)

repeat task.wait() until IsPlayerFullyLoaded == true

while IsIntermissionCountingDown.Value == true or IsMatchCountingDown.Value == true do
	local PlayersInGame = #Players:GetPlayers()
	
	if PlayersInGame >= RequirePlayersToStart.Value then

		if IsIntermissionCountingDown.Value == true and IsMatchCountingDown.Value == false then
			if CanSetIntermissionTime == true then
				print(OutputMark..'Setting display for intermission!!')
				TimeLeft.Value = IntermissionStartTime.Value
				IsFinishedCountdown.Value = false
				CanSetMatchTime = true
				CanSetIntermissionTime = false
			end

			Objective.Value = '!~Get ready for the next INTERMISSION~!'

		elseif IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
			if CanSetMatchTime == true then
				print(OutputMark..'Setting display for match!!')
				TimeLeft.Value = MatchStartTime.Value
				IsFinishedCountdown.Value = false
				CanSetIntermissionTime = true
				CanSetMatchTime = false
			end

			if MatchStartTime.Value > 60 then
				Objective.Value = 'Catch the player with the tail within '..(MatchStartTime.Value / 60)..' minute(s) !!'
			elseif MatchStartTime.Value < 60 then
				Objective.Value = 'Catch the player with the tail within '..MatchStartTime.Value..' second(s) !!'
			elseif MatchStartTime.Value > 3600 then
				Objective.Value = 'Catch the player with the tail within '..((MatchStartTime.Value / 60) / 60)..' hour(s) !!'
			end

		end

		task.wait(1)

		if IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true and PlayersInGame < RequirePlayersToStart.Value then
			for _, player in Players:GetPlayers() do
				SetupGame(player, 'setup_intermission')
			end
		end
		
		if TimeLeft.Value <= EndTime.Value then
			IsFinishedCountdown.Value = true
			if IsIntermissionCountingDown.Value == true and IsMatchCountingDown.Value == false then
				IsIntermissionCountingDown.Value = false
				IsMatchCountingDown.Value = true
			elseif IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
				IsIntermissionCountingDown.Value = true
				IsMatchCountingDown.Value = false
			end
		end
		
		if IsFinishedTransition == true then
			TimeLeft.Value -= 1
		end

	elseif PlayersInGame < RequirePlayersToStart.Value then
		CanSetIntermissionTime = true
		CanSetMatchTime = true
		Objective.Value = '⚠️ The game need at least '..tostring(RequirePlayersToStart.Value)..' player(s) to start ⚠️'
		TimeLeft.Value = 9999999999
	end
	task.wait()
end
