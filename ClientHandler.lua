--- // Services // ---

local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local TweenService = game:GetService('TweenService')
local RunService = game:GetService('RunService')
local StarterGui = game:GetService('StarterGui')

--- // Player Variables // ---

local Plr = Players.LocalPlayer
local PlayerGui = Plr:WaitForChild('PlayerGui')

--- // Folders & Folders Objects // ---

local ConfigurationsFolder = ReplicatedStorage:WaitForChild('Configurations')
local RemotesFolder = ReplicatedStorage:WaitForChild('Remotes')
local ModulesFolder = ReplicatedStorage:WaitForChild('Modules')

local GameConfigs = ConfigurationsFolder:WaitForChild('GameConfigs')
local TimerConfigs = ConfigurationsFolder:WaitForChild('TimerConfigs')
local DisplayConfigs = ConfigurationsFolder:WaitForChild('DisplayConfigs')
local MatchConfigs = ConfigurationsFolder:WaitForChild('MatchConfigs')

local TimeLeft = DisplayConfigs:WaitForChild('TimeLeft')
local Objective = DisplayConfigs:WaitForChild('Objective')

local IsIntermissionCountingDown = GameConfigs:WaitForChild('IsIntermissionCountingDown')
local IsMatchCountingDown = GameConfigs:WaitForChild('IsMatchCountingDown')
local IsFinishedCountdown = GameConfigs:WaitForChild('IsFinishedCountdown')

local EndTime = TimerConfigs:WaitForChild('EndTime')

local ChosenMap = MatchConfigs:WaitForChild('ChosenMap')
local ChosenTarget = MatchConfigs:WaitForChild('ChosenTarget')

local SetupSignal = RemotesFolder:WaitForChild('SetupSignal')

--- // Loaded Modules // ---

local NofiticationManager = require(ModulesFolder:WaitForChild('NofiticationManager'))
local TransitionManager = require(ModulesFolder:WaitForChild('TransitionManager'))

--- // GUI Objects // ---

local DisplayUI = PlayerGui:WaitForChild('DisplayUI')
local TransitionUI = PlayerGui:WaitForChild('TransitionUI')

local ObjectiveDisplay = DisplayUI:WaitForChild('Objective')
local TimerDisplay = DisplayUI:WaitForChild('Timer')
local TransitionFrame = TransitionUI:WaitForChild('TransitionFrame')

--- // Numbers, Booleans, Strings, Datas, & Tables // ---

local Info = TweenInfo.new(
	.15,
	Enum.EasingStyle.Sine,
	Enum.EasingDirection.Out,
	0,
	false,
	0
)

local OutputMark = '[ClientHandler (Client-Side)]: '

local TransitionDebounce = false

local SoundID = nil
local ChosenPlayer = nil

local AnimationIntensity = 2

local UpAnim = TweenService:Create(TimerDisplay, Info, {Position = UDim2.fromScale(TimerDisplay.Position.X.Scale, TimerDisplay.Position.Y.Scale + (AnimationIntensity / 1000))})
local DownAnim = TweenService:Create(TimerDisplay, Info, {Position = UDim2.fromScale(TimerDisplay.Position.X.Scale, TimerDisplay.Position.Y.Scale - (AnimationIntensity / 1000))})

--- // Functions, Events, & Setups // ---

StarterGui:SetCore('ResetButtonCallback', false)

local function CreateCountdownSound(Id: number)
	if type(Id) ~= 'number' then
		warn(OutputMark..'Cannot player sound because id is not a number: '..tostring(type(Id)))
		return
	end

	if string.len(tostring(Id)) ~= 10 then
		warn(OutputMark..'Cannot play sound because id is not a valid id!!')
		return
	end

	local CountdownSFX = Instance.new('Sound', workspace)
	CountdownSFX.Name = 'CountdownSFX'
	CountdownSFX.Looped = false
	CountdownSFX.Volume = .5
	CountdownSFX.SoundId = 'rbxassetid://'..Id
	CountdownSFX:Play()
	CountdownSFX.Ended:Connect(function()
		CountdownSFX:Destroy()
	end)
end

task.spawn(function()
	while task.wait() do
		if IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
			for _, highlight in workspace:GetDescendants() do
				if ChosenTarget and ChosenTarget.Value ~= '' then
					if highlight:IsA('Highlight') and highlight.Name == 'TargetHighlighter' and Plr.Name == ChosenTarget.Value then
						highlight:Destroy()
					end
				end
			end
		end
	end
end)

TimerDisplay:GetPropertyChangedSignal('Text'):Connect(function()
	if IsIntermissionCountingDown.Value == true or IsMatchCountingDown.Value == true then
		coroutine.wrap(CreateCountdownSound)(SoundID)
		UpAnim:Play()
		task.delay(Info.Time, function()
			DownAnim:Play()
		end)
	end
end)

while task.wait() do
	local MUnit = TimeLeft.Value / 60
	local HUnit = TimeLeft.Value / 3600

	if IsIntermissionCountingDown.Value == true and IsMatchCountingDown.Value == false then
		TimerDisplay.Text = '⏰ INTERMISSION STARTS IN: '..string.format("%02d:%02d:%02d", HUnit, MUnit % 60, TimeLeft.Value % 60)..'  ⏰'
	elseif IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true then
		TimerDisplay.Text = '⏰ GAME ENDS IN: '..string.format("%02d:%02d:%02d", HUnit, MUnit % 60, TimeLeft.Value % 60)..'  ⏰'
	end
	
	TransitionManager.UpdateTransitionStatus()
	
	if TimeLeft.Value <= EndTime.Value then
		if IsIntermissionCountingDown.Value == false and IsMatchCountingDown.Value == true and TransitionDebounce == false then
			print('match')

			DisplayUI.Enabled = false
			TransitionManager.ToggleTransition(TransitionFrame, true, true)
			SetupSignal:FireServer('setup_match')
			TransitionManager.ToggleTransition(TransitionFrame, false, true)
			DisplayUI.Enabled = true

			TransitionDebounce = true
		elseif IsIntermissionCountingDown.Value == true and IsMatchCountingDown.Value == false and TransitionDebounce == true then
			print('intermission')

			DisplayUI.Enabled = false
			TransitionManager.ToggleTransition(TransitionFrame, true, true)
			SetupSignal:FireServer('setup_intermission')
			TransitionManager.ToggleTransition(TransitionFrame, false, true)
			DisplayUI.Enabled = true

			TransitionDebounce = false
		end
	end
	
	if TimeLeft.Value <= 10 then
		SoundID = 2610939724
	elseif TimeLeft.Value > 10 then
		SoundID = 6042053626
	end

	ObjectiveDisplay.Text = Objective.Value
end
