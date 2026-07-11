local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Vide = require(ReplicatedStorage.Packages.Vide)
local Drift = require(ReplicatedStorage.Shared.Drift.Drift)
local Container = require(ReplicatedStorage.Shared.UI.component.Base.Container)
local UIListLayout = require(ReplicatedStorage.Shared.UI.component.Modifier.UIListLayout)
local UISizeRatio = require(ReplicatedStorage.Shared.UI.component.Modifier.UISizeRatio)
local MainGUI = {}

function MainGUI:Init()
	return self:Build()
end

function MainGUI.Build(self: MainGUI)
	self.GUI = Vide.create("ScreenGui")({
		Name = "MainGUI",
		ResetOnSpawn = false,
		ScreenInsets = Enum.ScreenInsets.None,
	})
	self.ShowMainGUI = Vide.source(true)
	self.MenuShown = {}
	self.SelectedMenu = Vide.source(nil)

	self.ScreenShown = {}
	self.SelectedScreen = Vide.source(nil)

	self.Side = {
		["Left"] = Container({
			Position = UDim2.fromScale(0, 0.5),
			AnchorPoint = Vector2.new(0, 0.5),
			Size = UDim2.fromScale(0.2, 1),
		})({}),
		["Center"] = Container({
			Position = UDim2.fromScale(0.52, 0.46),
			Size = UDim2.fromScale(0.7, 0.7),
		})({}),
	}

	for _, gui in self.Side do
		gui.Parent = self.GUI
	end

	self.Side["CenterFrame"] = Container({})({})

	self.Side["CenterFrame"].Parent = self.Side["Center"]

	self:InitBottom()

	self:InitShowEffect()
	self:InitMenuEffect()
	return self
end

function MainGUI.AddComponent(self: MainGUI, component: (any) -> any, side: string)
	Vide.mount(component, self.Side[side])
end

function MainGUI.AddHider(self: MainGUI, source: Vide.Source<boolean>)
	Vide.root(function()
		Vide.effect(function()
			self.ShowMainGUI(not source())
		end)
	end)
end

local HIDDEN_POS = {
	["Left"] = Vector2.new(-0.5, 0.5),
	["BottomMain"] = Vector2.new(0.5, 1.5),
	["Center"] = Vector2.new(0.5, 2),
}

function MainGUI.InitShowEffect(self: MainGUI)
	Vide.root(function()
		for side, component in self.Side do
			if not HIDDEN_POS[side] then
				continue
			end

			local originalPos = component.Position
			local vectorPos = Vector2.new(originalPos.X.Scale, originalPos.Y.Scale)
			local targetPos = Vide.source(vectorPos)

			Vide.effect(function()
				if self.ShowMainGUI() then
					targetPos(vectorPos)
				else
					targetPos(HIDDEN_POS[side])
				end
			end)

			local pos = Vide.spring(targetPos, 0.5, 0.6)

			Vide.effect(function()
				local udimPos = UDim2.fromScale(pos().X, pos().Y)
				component.Position = udimPos
			end)
		end
	end)
end

function MainGUI.InitBottom(self: MainGUI)
	local mainContainer = Container({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.fromScale(0.5, 1),
		Size = UDim2.fromScale(1, 0.17),
		UIListLayout({
			HorizontalAlignment = Enum.HorizontalAlignment.Center,
			Wraps = false,
			VerticalAlignment = Enum.VerticalAlignment.Bottom,
			Padding = UDim.new(0, 12),
		})({}),
	})

	local leftLayout = UIListLayout({
		SortOrder = Enum.SortOrder.Name,
		HorizontalAlignment = Enum.HorizontalAlignment.Right,
	})

	local rightLayout = UIListLayout({
		SortOrder = Enum.SortOrder.Name,
		HorizontalAlignment = Enum.HorizontalAlignment.Left,
	})

	local centerContainer = Container({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromScale(0.2, 1.1),
	})({})

	local centerRatio = UISizeRatio({
		Ratio = 1,
	})

	local leftContainer = Container({
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.fromScale(0, 1),
		Size = UDim2.fromScale(0.4, 0.75),
	})(leftLayout({}))

	local rightContainer = Container({
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.fromScale(1, 1),
		Size = UDim2.fromScale(0.4, 0.75),
	})(rightLayout({}))

	local bottomMain = mainContainer({
		leftContainer,
		centerRatio(centerContainer),
		rightContainer,
	})

	bottomMain.Parent = self.GUI

	self.Side["BottomMain"] = bottomMain
	self.Side["BottomLeft"] = leftContainer
	self.Side["BottomCenter"] = centerContainer
	self.Side["BottomRight"] = rightContainer
end

function MainGUI.AddMenu(self: MainGUI, menuComponent: () -> GuiObject, show: Vide.Source<boolean>)
	local id = {}
	self.MenuShown[id] = show

	Vide.mount(function()
		Vide.effect(function()
			self:HandleMenu(id)
		end)

		return Vide.show(show, function()
			return menuComponent()
		end)
	end, self.Side["CenterFrame"])
end

function MainGUI.HandleMenu(self: MainGUI, selected: {})
	if not self.MenuShown[selected]() then
		local none = true

		for _, show in self.MenuShown do
			if show() then
				none = false
				break
			end
		end

		if none then
			self.SelectedMenu(nil)
		end

		return
	end
	self.SelectedMenu(selected)

	for id, show in self.MenuShown do
		if id == selected then
			continue
		end
		show(false)
	end
end

function MainGUI.InitMenuEffect(self: MainGUI)
	local centerFrame = self.Side["CenterFrame"]
	local originPos = centerFrame.Position
	local offlinePos = UDim2.fromScale(originPos.X.Scale, 3)

	Vide.root(function()
		local goal = Vide.source(offlinePos)

		local pos, tween = Drift.Tween(goal, 0.4, Drift.Easing.sineOut)

		Vide.effect(function()
			local selected = self.SelectedMenu()

			tween:setPosition(offlinePos)
			if not selected then
				goal(offlinePos)
				return
			end

			goal(originPos)
		end)

		Vide.effect(function()
			local GUIShown = self.ShowMainGUI()
			pos()

			if not GUIShown then
				return
			end

			centerFrame.Position = pos()
		end)
	end)
end

function MainGUI.AddScreenComponent(self: MainGUI, component: () -> (), show: Vide.Source<boolean>)
	local id = {}
	self.ScreenShown[id] = show

	Vide.mount(function()
		self:AddHider(show)

		Vide.effect(function()
			show()
			task.defer(function()
				self:HandleScreen(id)
			end)
		end)
		return Vide.show(show, function()
			return component()
		end)
	end, self.GUI)
end

function MainGUI.HandleScreen(self: MainGUI, selected: {})
	if not self.ScreenShown[selected]() then
		local none = true

		for _, show in self.ScreenShown do
			if show() then
				none = false
				break
			end
		end

		if none then
			self.SelectedScreen(nil)
		end

		return
	end
	self.SelectedScreen(selected)

	for id, show in self.ScreenShown do
		if id == selected then
			continue
		end
		show(false)
	end
end

type MainGUI = typeof(MainGUI) & {
	GUI: ScreenGui,
	Side: { [string]: Frame },
	ShowMainGUI: Vide.Source<boolean>,
	MenuShown: { [{}]: Vide.Source<boolean> },
	ScreenShown: { [{}]: Vide.Source<boolean> },
	SelectedMenu: Vide.Source<{}?>,
	SelectedScreen: Vide.Source<{}?>,
}

return MainGUI:Init() :: MainGUI
