--[[
	Zenith Soul HUB | GUI v9  (ใช้กับเกมของตัวเอง: วางเป็น ModuleScript/LocalScript ฝั่ง Client)
	- v9: แสดงบน PlayerGui | ระบบ Flag/Config (เซฟ-โหลดค่าทุกตัวควบคุม) | ProgressBar | Hook เซฟธีม
	- แถวฟังก์ชันแบบ XT: เรียบ ไม่มีกล่องต่อแถว คั่นด้วยเส้นบางๆ ชื่ออยู่ซ้าย ตัวควบคุมอยู่ขวา
	- Dropdown เปิดเป็น "ตารางเลือกไอเท็ม" 2 คอลัมน์: รูปอยู่ซ้าย ชื่ออยู่ขวา (มีคำอธิบายใต้ชื่อได้) เลื่อนลงได้ไม่จำกัดแถว
	  ตัวเลือกไหนไม่มีรูปก็ไม่เว้นที่ว่าง | เลือกอันเดียวหรือหลายอัน | ไม่มีเครื่องหมายติ๊ก ใช้ขอบสีเน้นแทน
	- หมวด (Group) วางเป็นแถว แถวละ 2 ใบ: ใบที่ 1 ของฝั่ง Left + ใบที่ 1 ของฝั่ง Right = แถวบน, ใบที่ 2 = แถวถัดลงมา ... ความสูงเท่ากันในแถวเดียวกัน

	วิธีใช้ (หลังโหลดจะได้ตัวแปร UI):

		local tab = UI.Tabs.Macro
		local a = tab.Left:Group("Auto Farm", "zap")      -- แถว 1 ซ้าย
		local b = tab.Right:Group("Actions", "play")      -- แถว 1 ขวา (สูงเท่ากับ a)
		local c = tab.Left:Group("Units")                 -- แถว 2 ซ้าย
		local d = tab.Right:Group("Display")              -- แถว 2 ขวา
		tab.Left:Toggle{...}  -- วางตรงๆ ไม่ผ่าน Group ก็ได้ (สร้างการ์ดไม่มีหัวให้เอง)

		a:Toggle{Name = "Auto Start", Help = "คำอธิบายตอนชี้ที่ ?", Default = false, Callback = function(v) end}
		a:Slider{Name = "Delay", Min = 0, Max = 10, Step = 0.5, Default = 2, Suffix = "s", Callback = function(v) end}
		a:Dropdown{Name = "Mode", Options = {"A", "B"}, Default = "A", Callback = function(v) end}
		a:Dropdown{                                        -- ตารางไอเท็ม 2 คอลัมน์
			Name = "Items", Multi = true, Default = {"Bow"},
			Options = {
				{Name = "Bow", Desc = "+20% Range", Image = "rbxassetid://123"},   -- Image/Desc ใส่หรือไม่ก็ได้
				{Name = "Dagger", Desc = "+15% Attack"},                           -- ไม่มี Image = ไม่เว้นที่ว่าง
				"Axe",                                                              -- ใส่เป็นข้อความล้วนก็ได้
			},
			ImageResolver = function(name) return nil end,   -- ฟังก์ชันดึงรูปจากเกมตามชื่อ (คืน nil = ไม่ใส่รูป)
			Callback = function(listOrValue) end,
		}
		a:Input{...} a:Keybind{...} a:ColorPicker{...} a:InfoRow{...} a:Hint{...} a:Button{...} a:ButtonRow{...}
		a:Group("Advanced", nil, {Closed = true})          -- กลุ่มย่อยในการ์ด (หัวข้อแบบเส้น พับได้)

		a:ProgressBar{Name = "Wave", Min = 0, Max = 15, Default = 7}   -- obj.Set(v) อัปเดตค่าได้
		a:Toggle{Name = "X", Flag = "x"}  -- ใส่ Flag กับ Toggle/Slider/Dropdown/Input/Keybind/ColorPicker เพื่อให้เซฟ-โหลดได้
		UI.ExportConfig() -> JSON string ; UI.ImportConfig(str) ; UI.GetConfig() ; UI.SetConfig(tbl) ; UI.Flags["x"].obj.Get()
		CFG.OnThemeChanged = function(name) end ; CFG.SavedTheme = "Winter"  -- เก็บธีมเองผ่าน DataStore/Remote
		UI.Notify{Title = "Hello", Content = "ข้อความ"} ; UI.SetTheme("Winter") ; UI.SetGlass(0.5)
		CFG.ImageResolver ตั้งไว้ตัวเดียวใช้กับทุก Dropdown ก็ได้ (ดูใน CFG ด้านล่าง)
]]

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")
local HttpService = game:GetService("HttpService")
local MarketplaceService = game:GetService("MarketplaceService")

----------------------------------------------------------------
-- CONFIG
----------------------------------------------------------------
local CFG = {
	Title = "ZS",
	Brand = "Zenith Soul HUB",
	Logo = "",
	GameName = nil,
	GameImage = nil,
	ToggleKey = Enum.KeyCode.RightShift,
	AutoScale = true,
	Scale = 1,
	Glass = 0.5,
	Theme = nil,
	SelectedFmt = "%d selected",   -- ภาษาไทย: "เลือกไว้ %d อย่าง"
	SavedTheme = nil,              -- ชื่อธีมที่โหลดมาจากที่เก็บของคุณ (เช่น DataStore) 
	OnThemeChanged = nil,          -- function(name) เรียกเมื่อเปลี่ยนธีม ใช้เซฟเอง
	ImageResolver = nil,           -- function(name) return "rbxassetid://..." or nil end  (ใช้กับทุก Dropdown ที่ไม่ได้ใส่ Image เอง)
	Stats = {Equipped = 8, Units = 359},
	Tabs = {
		{"Home", "home"}, {"Players", "users"}, {"Visuals", "eye"}, {"Macro", "bot"},
		{"Units", "sparkles"}, {"Dungeon", "swords"}, {"Settings", "settings"},
	},
}

----------------------------------------------------------------
-- THEMES
----------------------------------------------------------------
local function rgb(r, g, b) return Color3.fromRGB(r, g, b) end
local THEMES = {
	Zenith = {
		win = rgb(16, 17, 21), winA = rgb(19, 20, 25), winB = rgb(12, 13, 17),
		top = rgb(17, 22, 28), card = rgb(19, 24, 30), cardLine = rgb(40, 51, 58),
		topLine = rgb(30, 42, 50), footLine = rgb(32, 34, 38), tabOn = rgb(27, 31, 40), tabLine = rgb(150, 158, 176),
		text = rgb(246, 248, 252), sub = rgb(164, 169, 181), mute = rgb(124, 132, 146),
		accent = rgb(52, 211, 153), glow = rgb(34, 190, 170), border = rgb(40, 56, 62),
		btn = rgb(26, 32, 43), btnLine = rgb(48, 57, 72), btnHover = rgb(33, 41, 54), btnHoverLine = rgb(84, 96, 118), off = rgb(48, 54, 66),
		logoA = rgb(72, 82, 100), logoB = rgb(30, 35, 46), coverA = rgb(32, 38, 52), coverB = rgb(18, 21, 29),
	},
	Winter = {
		win = rgb(12, 22, 38), winA = rgb(20, 38, 64), winB = rgb(9, 18, 34),
		top = rgb(18, 34, 58), card = rgb(24, 42, 68), cardLine = rgb(78, 114, 156),
		topLine = rgb(92, 130, 174), footLine = rgb(48, 72, 106), tabOn = rgb(38, 64, 102), tabLine = rgb(218, 238, 254),
		text = rgb(246, 251, 255), sub = rgb(178, 202, 230), mute = rgb(132, 158, 188),
		accent = rgb(120, 200, 250), glow = rgb(140, 210, 252), border = rgb(104, 146, 190),
		btn = rgb(34, 56, 90), btnLine = rgb(78, 114, 156), btnHover = rgb(42, 68, 106), btnHoverLine = rgb(144, 194, 238), off = rgb(56, 80, 116),
		logoA = rgb(160, 198, 230), logoB = rgb(44, 70, 104), coverA = rgb(44, 68, 104), coverB = rgb(13, 22, 38),
	},
}
local THEME_META = {Zenith = {"star", "Brand dark"}, Winter = {"snowflake", "Clean frost"}}
local THEME_ORDER = {"Zenith", "Winter"}

local Glass = math.clamp(CFG.Glass, 0, 0.85)
local C = {}
local ThemeName = "Zenith"
local function derive()
	C.badgeBg = C.card:Lerp(C.accent, 0.13)
	C.badgeLine = C.card:Lerp(C.accent, 0.32)
	C.hoverText = C.sub:Lerp(C.text, 0.7)
	C.ok, C.warn, C.bad, C.dotGreen = rgb(52, 211, 153), rgb(251, 158, 11), rgb(241, 69, 67), rgb(26, 178, 129)
	C.winT = Glass
	C.topT = Glass * 0.9
	C.cardT = Glass * 0.8
	C.btnT = Glass * 0.75
end
local function loadPalette(name)
	ThemeName = name
	for k, v in pairs(THEMES[name]) do C[k] = v end
	derive()
end
do
	local saved = CFG.SavedTheme
	loadPalette(THEMES[CFG.Theme or ""] and CFG.Theme or (THEMES[saved or ""] and saved) or "Zenith")
end

local LUCIDE = {
	["home"] = {16898613509, 820, 147}, ["users"] = {16898613869, 967, 98}, ["eye"] = {16898613353, 771, 563},
	["bot"] = {16898612819, 869, 98}, ["sparkles"] = {16898613777, 918, 49}, ["swords"] = {16898613777, 967, 759},
	["settings"] = {16898613777, 771, 257}, ["search"] = {16898613699, 918, 857}, ["gamepad-2"] = {16898613353, 710, 967},
	["chevron-left"] = {16898612819, 404, 967}, ["chevron-right"] = {16898612819, 869, 759},
	["chevron-down"] = {16898612819, 196, 918}, ["chevron-up"] = {16898612819, 710, 918},
	["play"] = {16898613699, 918, 257}, ["zap"] = {16898613869, 918, 906}, ["rotate-ccw"] = {16898613699, 967, 355},
	["sliders-horizontal"] = {16898613777, 820, 355}, ["crosshair"] = {16898613044, 453, 869}, ["shield"] = {16898613777, 869, 0},
	["refresh-cw"] = {16898613699, 404, 869}, ["mouse-pointer-click"] = {16898613613, 771, 710}, ["power"] = {16898613699, 820, 147},
	["target"] = {16898613869, 514, 771}, ["snowflake"] = {16898613777, 771, 661}, ["palette"] = {16898613613, 453, 918},
	["keyboard"] = {16898613509, 453, 820}, ["check"] = {16898612819, 710, 869}, ["x"] = {16898613869, 869, 906},
	["bell"] = {16898612819, 820, 257}, ["info"] = {16898613509, 612, 869}, ["type"] = {16898613869, 967, 257},
	["star"] = {16898613777, 967, 147}, ["circle-help"] = {16898613044, 820, 257}, ["lightbulb"] = {16898613509, 918, 196},
	["list"] = {16898613509, 869, 808}, ["book-open"] = {16898612819, 820, 355},
}

local L = {
	W = 660, H = 420, TOP = 46, NAV = 56, FOOT = 34, PAD = 18, GAP = 14,
	R_WIN = 14, R_CARD = 12, R_TAB = 11, R_COVER = 12,
}
local TOUCH = UIS.TouchEnabled
local ROW = TOUCH and 32 or 28

local W_ = Enum.FontWeight
local function sans(w) return Font.new("rbxasset://fonts/families/BuilderSans.json", w or W_.Medium) end
local function mono(w) return Font.new("rbxasset://fonts/families/RobotoMono.json", w or W_.Regular) end

----------------------------------------------------------------
-- CORE HELPERS
----------------------------------------------------------------
local function getParent()
	return Players.LocalPlayer:WaitForChild("PlayerGui")
end
local old = getParent():FindFirstChild("ZenithSoulGUI")
if old then old:Destroy() end

local function tweenE(o, t, p, style, dir)
	TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), p):Play()
end
local function tween(o, t, p) tweenE(o, t, p) end
local function set(inst, props, instant)
	if instant then for k, v in pairs(props) do inst[k] = v end else tween(inst, 0.25, props) end
end

local reg = {}
local function themed(fn) table.insert(reg, fn); fn(true) end
local function paint(inst, prop, key)
	themed(function(instant)
		if instant or not inst.Parent then inst[prop] = C[key] else tween(inst, 0.25, {[prop] = C[key]}) end
	end)
end

local PAINT = {Bg = "BackgroundColor3", Tx = "TextColor3", Ic = "ImageColor3", Co = "Color", Tr = "BackgroundTransparency"}
local function new(class, props, kids)
	local o = Instance.new(class)
	local parent
	local paints = {}
	for k, v in pairs(props or {}) do
		if k == "Parent" then parent = v
		elseif PAINT[k] then paints[PAINT[k]] = v
		else o[k] = v end
	end
	for prop, key in pairs(paints) do paint(o, prop, key) end
	for _, c in ipairs(kids or {}) do c.Parent = o end
	if parent then o.Parent = parent end
	return o
end
local function round(r) return new("UICorner", {CornerRadius = r == "full" and UDim.new(0.5, 0) or UDim.new(0, r)}) end
local function stroke(col, th, tr)
	local p = {Thickness = th or 1, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border}
	if type(col) == "string" then p.Co = col else p.Color = col end
	return new("UIStroke", p)
end
local function measure(text, face, size)
	local ok, res = pcall(function()
		local p = Instance.new("GetTextBoundsParams")
		p.Text, p.Font, p.Size, p.Width = text, face, size, 10000
		return TextService:GetTextBoundsAsync(p).X
	end)
	return ok and res or (#text * size * 0.56)
end
local function T(p)
	local props = {
		BackgroundTransparency = 1, Text = p.t, FontFace = p.f or sans(), TextSize = p.s or 12,
		TextXAlignment = p.xa or Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center,
		Size = p.sz or UDim2.fromScale(1, 1), Position = p.pos or UDim2.new(), AnchorPoint = p.ap or Vector2.new(), Parent = p.p,
	}
	if type(p.c) == "string" then props.Tx = p.c elseif p.c then props.TextColor3 = p.c else props.Tx = "text" end
	return new("TextLabel", props)
end
local function icon(parent, name, size, color, pos)
	local d = LUCIDE[name] or LUCIDE["zap"]
	local props = {
		BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = pos or UDim2.new(),
		Image = "rbxassetid://" .. d[1], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = Vector2.new(d[2], d[3]), Parent = parent,
	}
	if type(color) == "string" then props.Ic = color else props.ImageColor3 = color end
	return new("ImageLabel", props)
end
local function setIcon(img, name)
	local d = LUCIDE[name]
	if d then img.Image = "rbxassetid://" .. d[1]; img.ImageRectOffset = Vector2.new(d[2], d[3]) end
end
local function chevron(parent, xFromRight, open)
	local ic = icon(parent, "chevron-right", 12, "mute")
	ic.AnchorPoint = Vector2.new(0.5, 0.5)
	ic.Position = UDim2.new(1, -xFromRight, 0.5, 0)
	ic.Rotation = open and 90 or 0
	return ic
end
local function hoverStroke(obj, st, fromKey, toKey)
	obj.MouseEnter:Connect(function() tween(st, 0.15, {Color = C[toKey]}) end)
	obj.MouseLeave:Connect(function() tween(st, 0.15, {Color = C[fromKey]}) end)
end
local function isPress(i) return i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch end
local function isMove(i) return i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch end

----------------------------------------------------------------
-- ROOT  (Root > Main[พื้นหลัง+ตัดขอบ] > Inner[ขนาดคงที่])
----------------------------------------------------------------
local Gui = new("ScreenGui", {Name = "ZenithSoulGUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, IgnoreGuiInset = true, DisplayOrder = 999})
Gui.Parent = getParent()

local conns = {}
local function bind(sig, fn) local c = sig:Connect(fn); table.insert(conns, c); return c end
Gui.Destroying:Connect(function() for _, c in ipairs(conns) do c:Disconnect() end end)

local Root = new("Frame", {
	Name = "Root", Size = UDim2.fromOffset(L.W, L.H), AnchorPoint = Vector2.new(0.5, 0.5),
	Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1, Parent = Gui,
})
local Scale = new("UIScale", {Parent = Root})
local function autoScale()
	local cam = workspace.CurrentCamera
	local vp = cam and cam.ViewportSize or Vector2.new(1280, 720)
	local maxS = TOUCH and 1.2 or 1
	return math.clamp(math.min(vp.X * 0.94 / L.W, vp.Y * 0.9 / L.H, maxS) * CFG.Scale, 0.5, 2)
end
Scale.Scale = CFG.AutoScale and autoScale() or CFG.Scale
if CFG.AutoScale and workspace.CurrentCamera then
	bind(workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"), function()
		if CFG.AutoScale then Scale.Scale = autoScale() end
	end)
end
local mirrors = {}
local function mirrorScale(inst)
	local u = new("UIScale", {Scale = Scale.Scale, Parent = inst})
	table.insert(mirrors, u)
	return u
end
Scale:GetPropertyChangedSignal("Scale"):Connect(function() for _, u in ipairs(mirrors) do u.Scale = Scale.Scale end end)

local glowOn = true
local glowRings = {}
for i, tr in ipairs({0.84, 0.91, 0.96}) do
	local g = i * 3
	table.insert(glowRings, new("Frame", {
		Size = UDim2.new(1, g * 2, 1, g * 2), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundTransparency = 1, Parent = Root,
	}, {round(L.R_WIN + g), stroke("glow", 1.5, tr)}))
end
local function ringsVisible(v) for _, g in ipairs(glowRings) do g.Visible = v and glowOn end end

local Main = new("Frame", {
	Name = "Main", Size = UDim2.fromScale(1, 1), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundColor3 = Color3.new(1, 1, 1), Tr = "winT", BorderSizePixel = 0, ClipsDescendants = true, Parent = Root,
}, {round(L.R_WIN)})
do
	local wg = new("UIGradient", {Rotation = 90, Parent = Main})
	themed(function() wg.Color = ColorSequence.new(C.winA, C.winB) end)
end
local Inner = new("Frame", {
	Name = "Inner", Size = UDim2.fromOffset(L.W, L.H), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
	BackgroundTransparency = 1, Parent = Main,
})

----------------------------------------------------------------
-- WINTER (เรียบ สะอาด)
----------------------------------------------------------------
local snowOn, decoOn = true, true
local AuroraLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, Visible = false, Parent = Inner})
local SnowLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 0, Visible = false, Parent = Inner})
local FrostLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 60, Visible = false, Parent = Inner})

local function blob(cx, cy, r, col)
	for i = 1, 5 do
		local d = r * 2 * (1 - (i - 1) * 0.16)
		new("Frame", {
			Size = UDim2.fromOffset(d, d), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromOffset(cx, cy),
			BackgroundColor3 = col, BackgroundTransparency = 0.96, BorderSizePixel = 0, ZIndex = 0, Parent = AuroraLayer,
		}, {round("full")})
	end
end
blob(210, 100, 140, rgb(80, 205, 240))
blob(500, 330, 150, rgb(110, 140, 255))
new("Frame", {Size = UDim2.new(1, 0, 0, 64), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = FrostLayer},
	{round(L.R_WIN), new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(0.94, 1)})})
new("Frame", {Size = UDim2.new(1, -60, 0, 1), Position = UDim2.fromOffset(30, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = FrostLayer},
	{new("UIGradient", {Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.35), NumberSequenceKeypoint.new(1, 1)})})})

local flakes = {}
for i = 1, 18 do
	local near = i > 14
	local sz = near and 4 or math.random(2, 3)
	local f = new("Frame", {
		Size = UDim2.fromOffset(sz, sz), BackgroundColor3 = Color3.new(1, 1, 1),
		BackgroundTransparency = near and 0.78 or 0.5 + math.random() * 0.25, BorderSizePixel = 0, Parent = SnowLayer,
	}, {round("full")})
	flakes[i] = {f = f, x = math.random(0, L.W), y = math.random(0, L.H), v = near and math.random(12, 20) or math.random(6, 12), ph = math.random() * 6, amp = math.random(4, 10)}
end
local function fxUpdate()
	local w = ThemeName == "Winter"
	SnowLayer.Visible = snowOn and w
	AuroraLayer.Visible = decoOn and w
	FrostLayer.Visible = decoOn and w
end
bind(RunService.Heartbeat, function(dt)
	if not SnowLayer.Visible or not Root.Visible then return end
	local t = os.clock()
	for _, s in ipairs(flakes) do
		s.y += s.v * dt
		if s.y > L.H + 6 then s.y = -6; s.x = math.random(0, L.W) end
		s.f.Position = UDim2.fromOffset(s.x + math.sin(t * 0.8 + s.ph) * s.amp, s.y)
	end
end)

----------------------------------------------------------------
-- TOP BAR
----------------------------------------------------------------
local Top = new("Frame", {Name = "Top", Size = UDim2.new(1, 0, 0, L.TOP), Bg = "top", Tr = "topT", BorderSizePixel = 0, Active = true, Parent = Inner}, {round(L.R_WIN)})
local TopFill = new("Frame", {Size = UDim2.new(1, 0, 0, L.R_WIN + 4), Position = UDim2.new(0, 0, 1, -(L.R_WIN + 4)), Bg = "top", Tr = "topT", BorderSizePixel = 0, Parent = Top})
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.new(0, 0, 1, -1), Bg = "topLine", BorderSizePixel = 0, ZIndex = 2, Parent = Top})

local Logo = new("ImageLabel", {
	Size = UDim2.fromOffset(28, 28), Position = UDim2.fromOffset(L.PAD, 9), Bg = "tabOn",
	Image = CFG.Logo, ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0, Parent = Top,
}, {round(8), stroke("btnLine", 1)})
if CFG.Logo == "" then
	local lg = new("UIGradient", {Rotation = 45, Parent = Logo})
	themed(function() lg.Color = ColorSequence.new(C.logoA, C.logoB) end)
	T{p = Logo, t = "Z", f = mono(W_.Bold), s = 15, xa = Enum.TextXAlignment.Center}
end
T{p = Top, t = CFG.Title, f = mono(W_.Bold), s = 16, pos = UDim2.fromOffset(L.PAD + 38, 0), sz = UDim2.fromOffset(60, L.TOP)}

local function dot(fromRight, col)
	return new("TextButton", {
		Size = UDim2.fromOffset(11, 11), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -fromRight, 0.5, 0),
		BackgroundColor3 = col, Text = "", AutoButtonColor = false, Parent = Top,
	}, {round("full")})
end
local BtnGreen = dot(L.PAD + 6, C.dotGreen)
local BtnAmber = dot(L.PAD + 26, C.warn)
local BtnRed = dot(L.PAD + 46, C.bad)

local function iconBtn(fromRight, name)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(28, 28), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(1, -fromRight, 0.5, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = Top,
	}, {round(8)})
	local ic = icon(b, name, 16, "sub", UDim2.fromOffset(6, 6))
	b.MouseEnter:Connect(function() tween(b, 0.12, {BackgroundTransparency = 0.93}); tween(ic, 0.12, {ImageColor3 = C.text}) end)
	b.MouseLeave:Connect(function() tween(b, 0.12, {BackgroundTransparency = 1}); tween(ic, 0.12, {ImageColor3 = C.sub}) end)
	return b
end
local BtnGear = iconBtn(L.PAD + 84, "settings")
local BtnSearch = iconBtn(L.PAD + 116, "search")

local SearchBox = new("TextBox", {
	Size = UDim2.fromOffset(0, 24), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -(L.PAD + 116 + 20), 0.5, 0),
	Bg = "win", Tx = "text", Text = "", PlaceholderText = "Search...", ClearTextOnFocus = false,
	FontFace = sans(W_.Medium), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true,
	BorderSizePixel = 0, Visible = false, Parent = Top,
}, {round(8), stroke("btnLine", 1), new("UIPadding", {PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8)})})
paint(SearchBox, "PlaceholderColor3", "mute")

----------------------------------------------------------------
-- NAV
----------------------------------------------------------------
local NavHolder = new("Frame", {
	Size = UDim2.new(1, -L.PAD * 2, 0, 42), Position = UDim2.fromOffset(L.PAD, L.TOP + 7), BackgroundTransparency = 1, Parent = Inner,
})
local NavScroll = new("ScrollingFrame", {
	Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.X, ScrollBarThickness = 0, ScrollingDirection = Enum.ScrollingDirection.X,
	ElasticBehavior = Enum.ElasticBehavior.Never, Parent = NavHolder,
}, {
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
	new("UIPadding", {PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2)}),
})
local function navMax() return math.max(NavScroll.AbsoluteCanvasSize.X - NavScroll.AbsoluteWindowSize.X, 0) end

local function arrow(side)
	local left = side == "L"
	local f = new("Frame", {
		Size = UDim2.new(0, 38, 1, 0), AnchorPoint = Vector2.new(left and 0 or 1, 0), Position = UDim2.fromScale(left and 0 or 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1), Tr = "winT", BorderSizePixel = 0, ZIndex = 5, Visible = false, Parent = NavHolder,
	}, {new("UIGradient", {Rotation = left and 0 or 180, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.55, 0.1), NumberSequenceKeypoint.new(1, 1),
	})})})
	themed(function() f.BackgroundColor3 = C.winA end)
	local b = new("TextButton", {
		Size = UDim2.fromOffset(26, 26), AnchorPoint = Vector2.new(left and 0 or 1, 0.5), Position = UDim2.new(left and 0 or 1, left and 2 or -2, 0.5, 0),
		Bg = "tabOn", Text = "", AutoButtonColor = false, ZIndex = 6, Parent = f,
	}, {round(8), stroke("btnLine", 1)})
	local ic = icon(b, left and "chevron-left" or "chevron-right", 14, "text", UDim2.fromOffset(6, 6))
	ic.ZIndex = 7
	b.MouseButton1Click:Connect(function()
		local step = NavScroll.AbsoluteWindowSize.X * 0.6 * (left and -1 or 1)
		tweenE(NavScroll, 0.35, {CanvasPosition = Vector2.new(math.clamp(NavScroll.CanvasPosition.X + step, 0, navMax()), 0)}, Enum.EasingStyle.Quint)
	end)
	return f
end
local ArrowL, ArrowR = arrow("L"), arrow("R")
local function updateArrows()
	local x, m = NavScroll.CanvasPosition.X, navMax()
	ArrowL.Visible = x > 3
	ArrowR.Visible = x < m - 3
end
NavScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(updateArrows)
NavScroll:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateArrows)
NavScroll:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateArrows)

bind(UIS.InputChanged, function(i)
	if i.UserInputType ~= Enum.UserInputType.MouseWheel then return end
	local m, p, s = UIS:GetMouseLocation(), NavHolder.AbsolutePosition, NavHolder.AbsoluteSize
	if m.X >= p.X and m.X <= p.X + s.X and m.Y >= p.Y and m.Y <= p.Y + s.Y then
		NavScroll.CanvasPosition = Vector2.new(math.clamp(NavScroll.CanvasPosition.X - i.Position.Z * 80, 0, navMax()), 0)
	end
end)

----------------------------------------------------------------
-- CONTENT + FOOTER
----------------------------------------------------------------
local CONTENT_Y = L.TOP + L.NAV
local Content = new("Frame", {
	Name = "Content", Size = UDim2.new(1, 0, 1, -(CONTENT_Y + L.FOOT)), Position = UDim2.fromOffset(0, CONTENT_Y),
	BackgroundTransparency = 1, ClipsDescendants = true, Parent = Inner,
})
local Foot = new("Frame", {Size = UDim2.new(1, 0, 0, L.FOOT), Position = UDim2.new(0, 0, 1, -L.FOOT), BackgroundTransparency = 1, Parent = Inner})
new("Frame", {Size = UDim2.new(1, 0, 0, 1), Bg = "footLine", BorderSizePixel = 0, Parent = Foot})
T{p = Foot, t = CFG.Title, f = mono(W_.Bold), s = 12, pos = UDim2.fromOffset(L.PAD, 0), sz = UDim2.fromOffset(60, L.FOOT)}
T{p = Foot, t = CFG.Brand, f = sans(W_.Medium), s = 11, c = "mute", xa = Enum.TextXAlignment.Right, pos = UDim2.new(1, -L.PAD, 0, 0), ap = Vector2.new(1, 0), sz = UDim2.fromOffset(240, L.FOOT)}

----------------------------------------------------------------
-- TOOLTIP (?)
----------------------------------------------------------------
local Tip = new("Frame", {
	Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, Bg = "card", BorderSizePixel = 0, ZIndex = 400, Visible = false, Parent = Gui,
}, {round(8), stroke("btnHoverLine", 1), new("UIPadding", {PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 7), PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9)})})
mirrorScale(Tip)
local TipText = new("TextLabel", {
	Size = UDim2.fromOffset(0, 0), AutomaticSize = Enum.AutomaticSize.XY, BackgroundTransparency = 1, Text = "", FontFace = sans(W_.Regular),
	TextSize = 11, Tx = "sub", TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, Parent = Tip,
}, {new("UISizeConstraint", {MaxSize = Vector2.new(210, math.huge)})})
local tipToken = 0
local function hideTip() tipToken += 1; Tip.Visible = false end
local function showTip(anchor, text)
	tipToken += 1
	local my = tipToken
	TipText.Text = text
	Tip.Position = UDim2.fromOffset(-500, -500)
	Tip.Visible = true
	task.spawn(function()
		RunService.Heartbeat:Wait()
		if my ~= tipToken then return end
		local vp = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1280, 720)
		local sz, p = Tip.AbsoluteSize, anchor.AbsolutePosition
		local x = math.clamp(p.X - 8, 6, math.max(vp.X - sz.X - 6, 6))
		local y = p.Y + anchor.AbsoluteSize.Y + 6
		if y + sz.Y > vp.Y - 6 then y = p.Y - sz.Y - 6 end
		Tip.Position = UDim2.fromOffset(x, y)
	end)
end
local function helpIcon(parent, text, x, cy)
	local d = LUCIDE["circle-help"]
	local b = new("ImageButton", {
		Size = UDim2.fromOffset(12, 12), Position = UDim2.new(0, x, 0, cy - 6), BackgroundTransparency = 1, AutoButtonColor = false,
		Image = "rbxassetid://" .. d[1], ImageRectSize = Vector2.new(48, 48), ImageRectOffset = Vector2.new(d[2], d[3]), Ic = "mute", Parent = parent,
	})
	b.MouseEnter:Connect(function() showTip(b, text); tween(b, 0.1, {ImageColor3 = C.text}) end)
	b.MouseLeave:Connect(function() hideTip(); tween(b, 0.1, {ImageColor3 = C.mute}) end)
	b.MouseButton1Click:Connect(function()
		showTip(b, text)
		local t = tipToken
		task.delay(2.5, function() if t == tipToken then hideTip() end end)
	end)
	return b
end
local function nameLabel(row, name, help, x, y, h)
	local w = math.ceil(measure(name, sans(W_.Medium), 12)) + 2
	T{p = row, t = name, f = sans(W_.Medium), s = 12, pos = UDim2.fromOffset(x, y), sz = UDim2.fromOffset(w, h)}
	local ex = x + w
	if help then helpIcon(row, help, ex + 5, y + h / 2); ex += 19 end
	return ex
end

----------------------------------------------------------------
-- ITEM GRID PICKER (แผงกลางหน้าต่าง: ตาราง 2 คอลัมน์ รูปซ้าย ชื่อขวา)
----------------------------------------------------------------
local ModalLayer = new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 150, Visible = false, Parent = Inner})
local ModalBack = new("TextButton", {
	Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = ModalLayer,
}, {round(L.R_WIN)})
local ModalPanel, ModalCb

local function closeModal(instant)
	if not ModalLayer.Visible then return end
	local panel, cb = ModalPanel, ModalCb
	ModalPanel, ModalCb = nil, nil
	if instant or not panel then
		if panel then panel:Destroy() end
		ModalLayer.Visible = false
		ModalBack.BackgroundTransparency = 1
	else
		tween(ModalBack, 0.18, {BackgroundTransparency = 1})
		tween(panel, 0.18, {GroupTransparency = 1})
		local us = panel:FindFirstChildOfClass("UIScale")
		if us then tween(us, 0.18, {Scale = 0.95}) end
		task.delay(0.2, function()
			panel:Destroy()
			if not ModalPanel then ModalLayer.Visible = false end
		end)
	end
	if cb then cb() end
end
ModalBack.MouseButton1Click:Connect(function() closeModal() end)

-- cfg.options = { {name=, value=, desc=?, image=?}, ... }
local function openModal(cfg)
	closeModal(true)
	hideTip()
	local opts, multi = cfg.options, cfg.multi
	local cellH, gap = 46, 8
	local pw = math.min(L.W - 60, 540)
	local y0 = 46
	local listY = y0 + (cfg.search and 42 or 0)
	local footStep = multi and 54 or 10
	local avail = L.H - 24 - (listY + footStep)
	local maxRows = math.max(math.floor((avail - 8) / (cellH + gap)), 2)
	local needRows = math.ceil(math.max(#opts, 1) / 2)
	local rows = math.min(needRows, maxRows)
	local listH = rows * (cellH + gap) + 8
	local ph = listY + listH + footStep

	ModalLayer.Visible = true
	local scaleObj = new("UIScale", {Scale = 0.94})
	local panel = new("CanvasGroup", {
		Size = UDim2.fromOffset(pw, ph), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5),
		BackgroundColor3 = C.card, BorderSizePixel = 0, GroupTransparency = 1, Active = true, Parent = ModalLayer,
	}, {round(16), stroke(C.btnHoverLine, 1.5), scaleObj})
	ModalPanel, ModalCb = panel, cfg.onClose

	local title = cfg.title or "Select"
	local tw = measure(title, sans(W_.SemiBold), 16)
	T{p = panel, t = title, f = sans(W_.SemiBold), s = 16, c = C.text, pos = UDim2.fromOffset(18, 0), sz = UDim2.fromOffset(tw + 4, y0)}
	local countLbl = T{p = panel, t = "", f = sans(W_.Medium), s = 12, c = C.accent, pos = UDim2.fromOffset(18 + tw + 12, 0), sz = UDim2.fromOffset(140, y0)}
	local closeBtn = new("TextButton", {
		Size = UDim2.fromOffset(30, 30), Position = UDim2.new(1, -40, 0, 8), BackgroundColor3 = C.btn, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = panel,
	}, {round(9)})
	icon(closeBtn, "x", 16, C.sub, UDim2.fromOffset(7, 7))
	closeBtn.MouseButton1Click:Connect(function() closeModal() end)

	local items = {}
	local function refresh()
		for _, it in ipairs(items) do
			local on = cfg.isSel(it.value)
			it.btn.BackgroundColor3 = on and C.card:Lerp(C.accent, 0.22) or C.btn
			it.st.Color = on and C.accent or C.btnLine
			it.st.Thickness = on and 1.6 or 1
			it.lbl.TextColor3 = on and C.accent or C.text
		end
		if cfg.count then countLbl.Text = cfg.count() or "" end
	end

	if multi then
		local function ghost(label, w, xFromRight, cb)
			local b = new("TextButton", {
				Size = UDim2.fromOffset(w, 26), Position = UDim2.new(1, -xFromRight, 0, 10), BackgroundColor3 = C.btn, Text = label, TextColor3 = C.sub,
				FontFace = sans(W_.Medium), TextSize = 12, AutoButtonColor = false, BorderSizePixel = 0, Parent = panel,
			}, {round(8), stroke(C.btnLine, 1)})
			b.MouseEnter:Connect(function() tween(b, 0.1, {TextColor3 = C.text}) end)
			b.MouseLeave:Connect(function() tween(b, 0.1, {TextColor3 = C.sub}) end)
			b.MouseButton1Click:Connect(function() cb(); refresh() end)
		end
		ghost("Clear", 56, 40 + 8 + 56, cfg.onNone)
		ghost("Select all", 78, 40 + 8 + 56 + 6 + 78, cfg.onAll)
	end

	local searchBox
	if cfg.search then
		searchBox = new("TextBox", {
			Size = UDim2.new(1, -28, 0, 32), Position = UDim2.fromOffset(14, y0 + 2), BackgroundColor3 = C.win, TextColor3 = C.text, PlaceholderColor3 = C.mute,
			PlaceholderText = "Search...", Text = "", ClearTextOnFocus = false, FontFace = sans(W_.Medium), TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left, BorderSizePixel = 0, Parent = panel,
		}, {round(9), stroke(C.btnLine, 1), new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)})})
	end

	local list = new("ScrollingFrame", {
		Size = UDim2.fromOffset(pw, listH), Position = UDim2.fromOffset(0, listY), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3, ScrollBarImageColor3 = C.btnLine, Parent = panel,
	}, {
		new("UIPadding", {PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4)}),
		new("UIGridLayout", {
			CellSize = UDim2.new(0.5, -gap / 2, 0, cellH), CellPadding = UDim2.fromOffset(gap, gap),
			FillDirectionMaxCells = 2, SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Left,
		}),
	})
	for i, opt in ipairs(opts) do
		local st = stroke(C.btnLine, 1)
		local b = new("TextButton", {LayoutOrder = i, BackgroundColor3 = C.btn, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = list}, {round(10), st})
		local x = 12
		if opt.image then
			new("ImageLabel", {
				Size = UDim2.fromOffset(34, 34), Position = UDim2.new(0, 6, 0.5, -17), BackgroundColor3 = C.win, BackgroundTransparency = 0.4,
				Image = opt.image, ScaleType = Enum.ScaleType.Fit, BorderSizePixel = 0, Parent = b,
			}, {round(8)})
			x = 48
		end
		local hasDesc = opt.desc ~= nil
		local lb = T{p = b, t = opt.name, f = sans(W_.Medium), s = 13, c = C.text, pos = UDim2.fromOffset(x, hasDesc and 5 or 0), sz = UDim2.new(1, -x - 8, 0, hasDesc and 20 or cellH)}
		lb.TextTruncate = Enum.TextTruncate.AtEnd
		if hasDesc then
			local dl = T{p = b, t = opt.desc, f = sans(W_.Regular), s = 10, c = C.mute, pos = UDim2.fromOffset(x, 25), sz = UDim2.new(1, -x - 8, 0, 14)}
			dl.TextTruncate = Enum.TextTruncate.AtEnd
		end
		items[i] = {btn = b, lbl = lb, st = st, value = opt.value, name = opt.name:lower(), desc = (opt.desc or ""):lower()}
		b.MouseEnter:Connect(function() if not cfg.isSel(opt.value) then tween(b, 0.1, {BackgroundColor3 = C.btnHover}) end end)
		b.MouseLeave:Connect(function() if not cfg.isSel(opt.value) then tween(b, 0.1, {BackgroundColor3 = C.btn}) end end)
		b.MouseButton1Click:Connect(function()
			cfg.onPick(opt.value)
			if multi then refresh() else closeModal() end
		end)
	end
	if multi then
		local done = new("TextButton", {
			Size = UDim2.new(1, -28, 0, 38), Position = UDim2.new(0, 14, 1, -48), BackgroundColor3 = C.card:Lerp(C.accent, 0.2), Text = "Done", TextColor3 = C.accent,
			FontFace = sans(W_.SemiBold), TextSize = 14, AutoButtonColor = false, BorderSizePixel = 0, Parent = panel,
		}, {round(11), stroke(C.card:Lerp(C.accent, 0.55), 1)})
		done.MouseButton1Click:Connect(function() closeModal() end)
	end
	refresh()
	if searchBox then
		searchBox:GetPropertyChangedSignal("Text"):Connect(function()
			local q = searchBox.Text:lower()
			for _, it in ipairs(items) do
				it.btn.Visible = q == "" or it.name:find(q, 1, true) ~= nil or it.desc:find(q, 1, true) ~= nil
			end
		end)
	end

	tween(ModalBack, 0.22, {BackgroundTransparency = 0.5})
	tweenE(panel, 0.26, {GroupTransparency = 0}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	tweenE(scaleObj, 0.32, {Scale = 1}, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
end

----------------------------------------------------------------
-- COMPONENT SYSTEM
----------------------------------------------------------------
local SearchQuery = ""
local Listening = false
local setTheme -- forward

local function pal(style)
	if style == "primary" then
		return {bg = C.card:Lerp(C.accent, 0.16), line = C.card:Lerp(C.accent, 0.45), fg = C.accent, hbg = C.card:Lerp(C.accent, 0.26), hline = C.card:Lerp(C.accent, 0.75)}
	elseif style == "danger" then
		return {bg = rgb(48, 22, 26), line = rgb(116, 40, 46), fg = rgb(248, 113, 113), hbg = rgb(62, 27, 32), hline = rgb(160, 56, 62)}
	end
	return {bg = C.btn, line = C.btnLine, fg = C.text, hbg = C.btnHover, hline = C.btnHoverLine}
end

-- กล่องพับ/กางแบบนุ่ม
local function collapse(parent, order, open, body)
	local clip = new("Frame", {
		LayoutOrder = order, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
		ClipsDescendants = true, Visible = open, Parent = parent,
	})
	body.Parent = clip
	local token = 0
	local function setOpen(v, instant)
		token += 1
		local my = token
		if instant then
			clip.AutomaticSize = Enum.AutomaticSize.Y
			clip.Size = UDim2.new(1, 0, 0, 0)
			clip.Visible = v
			return
		end
		if v then
			clip.AutomaticSize = Enum.AutomaticSize.None
			clip.Size = UDim2.new(1, 0, 0, 0)
			clip.Visible = true
			task.spawn(function()
				RunService.Heartbeat:Wait()
				if my ~= token then return end
				local h = body.AbsoluteSize.Y / Scale.Scale
				tweenE(clip, 0.28, {Size = UDim2.new(1, 0, 0, h)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
				task.wait(0.3)
				if my == token then clip.AutomaticSize = Enum.AutomaticSize.Y; clip.Size = UDim2.new(1, 0, 0, 0) end
			end)
		else
			local h = clip.AbsoluteSize.Y / Scale.Scale
			clip.AutomaticSize = Enum.AutomaticSize.None
			clip.Size = UDim2.new(1, 0, 0, h)
			tweenE(clip, 0.24, {Size = UDim2.new(1, 0, 0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
			task.delay(0.26, function() if my == token then clip.Visible = false end end)
		end
	end
	return clip, setOpen
end

local function buildButton(parent, o, size, order, center)
	local style = o.Style or "default"
	local bh = o.Description and 38 or ROW
	local st = stroke(C.btnLine, 1)
	local b = new("TextButton", {
		LayoutOrder = order or 0, Size = size or UDim2.new(1, 0, 0, bh), BackgroundColor3 = C.btn, Text = "", AutoButtonColor = false,
		BorderSizePixel = 0, Parent = parent,
	}, {round(8), st})
	local sc = new("UIScale", {Parent = b})
	local x, ico = 10, nil
	if o.Icon and LUCIDE[o.Icon] then
		ico = icon(b, o.Icon, 14, C.text, o.Description and UDim2.new(0, 10, 0, 12) or UDim2.new(0, 10, 0.5, -7)); x = 30
	end
	local lbl = T{p = b, t = o.Name or "Button", f = sans(W_.Medium), s = 12, c = C.text,
		pos = UDim2.fromOffset(x, o.Description and 4 or 0), sz = UDim2.new(1, -x - 8, o.Description and 0 or 1, o.Description and 16 or 0),
		xa = (center and not o.Icon) and Enum.TextXAlignment.Center or Enum.TextXAlignment.Left}
	if o.Description then
		T{p = b, t = o.Description, f = sans(W_.Regular), s = 10, c = "mute", pos = UDim2.fromOffset(x, 21), sz = UDim2.new(1, -x - 8, 0, 13)}
	end
	themed(function(instant)
		local p = pal(style)
		set(b, {BackgroundColor3 = p.bg, BackgroundTransparency = C.btnT}, instant); set(st, {Color = p.line}, instant)
		lbl.TextColor3 = p.fg
		if ico then ico.ImageColor3 = p.fg end
	end)
	b.MouseEnter:Connect(function() local p = pal(style); tween(b, 0.12, {BackgroundColor3 = p.hbg}); tween(st, 0.12, {Color = p.hline}) end)
	b.MouseLeave:Connect(function() local p = pal(style); tween(b, 0.12, {BackgroundColor3 = p.bg}); tween(st, 0.12, {Color = p.line}); tween(sc, 0.1, {Scale = 1}) end)
	b.MouseButton1Down:Connect(function() tween(sc, 0.08, {Scale = 0.97}) end)
	b.MouseButton1Up:Connect(function() tweenE(sc, 0.18, {Scale = 1}, Enum.EasingStyle.Back) end)
	local obj = {Instance = b}
	function obj.Fire() if o.Callback then task.spawn(pcall, o.Callback) end end
	function obj.SetText(t) lbl.Text = t end
	b.MouseButton1Click:Connect(obj.Fire)
	return obj
end

-- แปลงตัวเลือก (ข้อความล้วน หรือ {Name, Value, Desc, Image}) ให้เป็นรูปแบบเดียวกัน
local function normOpts(list, resolver)
	local out = {}
	for _, o in ipairs(list or {}) do
		local name, value, desc, image
		if type(o) == "table" then
			name = tostring(o.Name or o[1] or "?")
			value = o.Value
			if value == nil then value = name end
			desc, image = o.Desc, o.Image
		else
			name = tostring(o); value = o
		end
		if image == nil and resolver then local ok, r = pcall(resolver, name); if ok then image = r end end
		if image == nil and CFG.ImageResolver then local ok, r = pcall(CFG.ImageResolver, name); if ok then image = r end end
		if type(image) == "number" then image = "rbxassetid://" .. image end
		if image == "" then image = nil end
		table.insert(out, {name = name, value = value, desc = desc, image = image})
	end
	return out
end

local Flags = {}
local LOOSE = {"Button", "ButtonRow", "Toggle", "Slider", "Dropdown", "Input", "Keybind", "ColorPicker", "InfoRow", "ProgressBar", "Hint", "ThemePicker", "Label", "Paragraph", "Section", "Divider"}

local function Container(host, onAdd, scope, factory)
	local self = {Frame = host}
	local order = 0
	local function nextOrder() order += 1; return order end
	local function added() if onAdd then onAdd() end end
	local function track(name, frame)
		if scope then
			table.insert(scope.items, {name = type(name) == "function" and name or tostring(name or ""):lower(), frame = frame})
		end
	end
	-- แถวเรียบแบบ XT: โปร่งใส มีเส้นคั่นบางๆ ด้านบน (ยกเว้นแถวแรก)
	local function flatRow(class, h)
		local first = order == 0
		local f = new(class, {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, h), BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1, BorderSizePixel = 0, Parent = host})
		if class == "TextButton" then
			f.Text = ""; f.AutoButtonColor = false
			f.MouseEnter:Connect(function() tween(f, 0.12, {BackgroundTransparency = 0.94}) end)
			f.MouseLeave:Connect(function() tween(f, 0.12, {BackgroundTransparency = 1}) end)
		end
		if not first then new("Frame", {Size = UDim2.new(1, 0, 0, 1), Bg = "cardLine", BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = f}) end
		return f
	end
	local function lineIf(first, parent)
		if not first then new("Frame", {Size = UDim2.new(1, 0, 0, 1), Bg = "cardLine", BackgroundTransparency = 0.45, BorderSizePixel = 0, ZIndex = 2, Parent = parent}) end
	end
	-- ช่องเล็กด้านขวาของแถว (dropdown / input / keybind)
	local function field(parent, w, h)
		return new("Frame", {AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), Size = w, Bg = "btn", Tr = "btnT", BorderSizePixel = 0, Parent = parent},
			{round(8), stroke("btnLine", 1)})
	end

	function self:Button(o)
		added()
		local h = o.Description and 38 or ROW
		local wrap = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, h + 10), BackgroundTransparency = 1, Parent = host})
		local obj = buildButton(wrap, o, UDim2.new(1, 0, 0, h), 0, false)
		obj.Instance.Position = UDim2.fromOffset(0, 5)
		track(o.Name, wrap)
		return obj
	end

	function self:ButtonRow(list)
		added()
		local n, gap = #list, 6
		local wrap = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, ROW + 10), BackgroundTransparency = 1, Parent = host})
		local row = new("Frame", {Size = UDim2.new(1, 0, 0, ROW), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1, Parent = wrap},
			{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, gap), SortOrder = Enum.SortOrder.LayoutOrder})})
		local objs, names = {}, {}
		for i, o in ipairs(list) do
			objs[i] = buildButton(row, o, UDim2.new(1 / n, -gap * (n - 1) / n, 1, 0), i, true)
			names[i] = o.Name or ""
		end
		track(table.concat(names, " "), wrap)
		return objs
	end

	function self:Toggle(o)
		added()
		local state = o.Default == true
		local h = o.Description and 40 or ROW + 2
		local row = flatRow("TextButton", h)
		nameLabel(row, o.Name or "Toggle", o.Help, 2, o.Description and 4 or 0, o.Description and 18 or h)
		if o.Description then
			T{p = row, t = o.Description, f = sans(W_.Regular), s = 10, c = "mute", pos = UDim2.fromOffset(2, 22), sz = UDim2.new(1, -56, 0, 13)}
		end
		local tr = new("Frame", {Size = UDim2.fromOffset(32, 18), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), BackgroundColor3 = C.off, BorderSizePixel = 0, Parent = row}, {round("full")})
		local knob = new("Frame", {Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 2, 0.5, 0), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = tr}, {round("full")})
		local function apply(instant)
			set(tr, {BackgroundColor3 = state and C.accent or C.off}, instant)
			if instant then knob.Position = UDim2.new(0, state and 16 or 2, 0.5, 0)
			else tweenE(knob, 0.22, {Position = UDim2.new(0, state and 16 or 2, 0.5, 0)}, Enum.EasingStyle.Back) end
		end
		themed(apply)
		local obj = {Instance = row}
		function obj.Get() return state end
		function obj.Set(v, silent)
			state = v and true or false
			apply(false)
			if not silent and o.Callback then task.spawn(pcall, o.Callback, state) end
		end
		row.MouseButton1Click:Connect(function() obj.Set(not state) end)
		track(o.Name, row)
		return obj
	end

	function self:Slider(o)
		added()
		local min, max, step = o.Min or 0, o.Max or 100, o.Step or 1
		local dec = (tostring(step):match("%.(%d+)") or ""):len()
		local val = math.clamp(o.Default or min, min, max)
		local row = flatRow("Frame", ROW + 18)
		nameLabel(row, o.Name or "Slider", o.Help, 2, 4, 20)
		local box = new("TextBox", {
			AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -2, 0, 4), Size = UDim2.fromOffset(74, 20), BackgroundTransparency = 1, Tx = "accent",
			Text = "", ClearTextOnFocus = false, FontFace = mono(W_.Medium), TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, BorderSizePixel = 0, Parent = row,
		})
		local tr = new("Frame", {Size = UDim2.new(1, -4, 0, 4), Position = UDim2.fromOffset(2, ROW + 6), Bg = "off", BorderSizePixel = 0, Parent = row}, {round("full")})
		local fill = new("Frame", {Size = UDim2.fromScale(0, 1), Bg = "accent", BorderSizePixel = 0, Parent = tr}, {round("full")})
		local knob = new("Frame", {Size = UDim2.fromOffset(11, 11), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, ZIndex = 2, Parent = tr}, {round("full")})
		local hit = new("TextButton", {Size = UDim2.new(1, 0, 0, 24), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundTransparency = 1, Text = "", ZIndex = 3, Parent = tr})
		local function render()
			local pct = (val - min) / (max - min)
			fill.Size = UDim2.fromScale(pct, 1)
			knob.Position = UDim2.fromScale(pct, 0.5)
			box.Text = string.format("%." .. dec .. "f", val) .. (o.Suffix or "")
		end
		render()
		local obj = {Instance = row}
		local function setVal(v, silent)
			v = math.clamp(math.floor((v - min) / step + 0.5) * step + min, min, max)
			v = tonumber(string.format("%." .. dec .. "f", v))
			if v == val then return end
			val = v; render()
			if not silent and o.Callback then task.spawn(pcall, o.Callback, val) end
		end
		function obj.Get() return val end
		function obj.Set(v) setVal(v, true); render() end
		box.FocusLost:Connect(function()
			local n = tonumber(box.Text:match("-?%d+%.?%d*"))
			if n then setVal(n) end
			render()
		end)
		local dragging = false
		local function fromX(x) setVal(min + math.clamp((x - tr.AbsolutePosition.X) / tr.AbsoluteSize.X, 0, 1) * (max - min)) end
		hit.InputBegan:Connect(function(i) if isPress(i) then dragging = true; fromX(i.Position.X); tween(knob, 0.1, {Size = UDim2.fromOffset(14, 14)}) end end)
		bind(UIS.InputChanged, function(i) if dragging and isMove(i) then fromX(i.Position.X) end end)
		bind(UIS.InputEnded, function(i) if isPress(i) and dragging then dragging = false; tween(knob, 0.12, {Size = UDim2.fromOffset(11, 11)}) end end)
		track(o.Name, row)
		return obj
	end

	function self:Dropdown(o)
		added()
		local multi = o.Multi == true
		local opts = normOpts(o.Options, o.ImageResolver)
		local nameOf = {}
		for _, x in ipairs(opts) do nameOf[x.value] = x.name end
		local sel, single = {}, nil
		if multi then
			for _, v in ipairs(o.Default or {}) do
				for _, x in ipairs(opts) do if x.value == v or x.name == v then sel[x.value] = true end end
			end
		else
			single = o.Default
			for _, x in ipairs(opts) do if x.name == o.Default then single = x.value end end
		end
		local row = flatRow("TextButton", ROW + 2)
		local ex = nameLabel(row, o.Name or "Dropdown", o.Help, 2, 0, ROW + 2)
		local fb = field(row, UDim2.new(0.44, 0, 0, ROW - 4))
		local valLbl = T{p = fb, t = "", f = sans(W_.Medium), s = 11, c = "sub", pos = UDim2.fromOffset(10, 0), sz = UDim2.new(1, -30, 1, 0)}
		valLbl.TextTruncate = Enum.TextTruncate.AtEnd
		icon(fb, "chevron-down", 12, "mute", UDim2.new(1, -20, 0.5, -6))
		local function selectedList()
			local r = {}
			for _, x in ipairs(opts) do if sel[x.value] then table.insert(r, x.value) end end
			return r
		end
		local function summary()
			if multi then
				local l = selectedList()
				if #l == 0 then valLbl.Text = "None"; valLbl.TextColor3 = C.mute
				else
					valLbl.TextColor3 = C.accent
					if #l <= 2 then
						local names = {}
						for _, v in ipairs(l) do table.insert(names, nameOf[v] or tostring(v)) end
						valLbl.Text = table.concat(names, ", ")
					else valLbl.Text = string.format(CFG.SelectedFmt, #l) end
				end
			else
				if single ~= nil then valLbl.Text = nameOf[single] or tostring(single); valLbl.TextColor3 = C.text
				else valLbl.Text = "Select"; valLbl.TextColor3 = C.mute end
			end
		end
		summary()
		themed(function() summary() end)
		local function fire()
			if not o.Callback then return end
			task.spawn(pcall, o.Callback, multi and selectedList() or single)
		end
		row.MouseButton1Click:Connect(function()
			openModal({
				title = o.Name or "Select", options = opts, multi = multi,
				search = multi or (o.Search ~= false and #opts > 6),
				isSel = function(v) if multi then return sel[v] == true end return single == v end,
				onPick = function(v)
					if multi then sel[v] = (not sel[v]) or nil else single = v end
					summary(); fire()
				end,
				onAll = function() for _, x in ipairs(opts) do sel[x.value] = true end summary(); fire() end,
				onNone = function() sel = {}; summary(); fire() end,
				count = function() if multi then return string.format(CFG.SelectedFmt, #selectedList()) end end,
			})
		end)
		local obj = {Instance = row}
		function obj.Get() if multi then return selectedList() end return single end
		function obj.Set(v)
			if multi then sel = {}; for _, x in ipairs(v or {}) do sel[x] = true end else single = v end
			summary()
		end
		function obj.Refresh(newOpts)
			opts = normOpts(newOpts, o.ImageResolver)
			nameOf = {}
			for _, x in ipairs(opts) do nameOf[x.value] = x.name end
			summary()
		end
		track(o.Name, row)
		return obj
	end

	function self:Input(o)
		added()
		local row = flatRow("Frame", ROW + 2)
		nameLabel(row, o.Name or "Input", o.Help, 2, 0, ROW + 2)
		local fb = field(row, UDim2.new(0.44, 0, 0, ROW - 4))
		local box = new("TextBox", {
			Size = UDim2.new(1, -16, 1, 0), Position = UDim2.fromOffset(8, 0), BackgroundTransparency = 1, Tx = "text", Text = tostring(o.Default or ""),
			PlaceholderText = o.Placeholder or "Type...", ClearTextOnFocus = false, FontFace = mono(W_.Regular), TextSize = 11,
			TextXAlignment = Enum.TextXAlignment.Left, ClipsDescendants = true, BorderSizePixel = 0, Parent = fb,
		})
		paint(box, "PlaceholderColor3", "mute")
		local last = box.Text
		local obj = {Instance = row}
		function obj.Get() return o.Numeric and tonumber(box.Text) or box.Text end
		function obj.Set(v) box.Text = tostring(v); last = box.Text end
		box.FocusLost:Connect(function()
			local t = box.Text
			if o.Numeric then
				local n = tonumber(t)
				if not n then box.Text = last; return end
				if o.Min then n = math.max(n, o.Min) end
				if o.Max then n = math.min(n, o.Max) end
				box.Text = tostring(n); last = box.Text
				if o.Callback then task.spawn(pcall, o.Callback, n) end
			else
				last = t
				if o.Callback then task.spawn(pcall, o.Callback, t) end
			end
		end)
		track(o.Name, row)
		return obj
	end

	function self:Keybind(o)
		added()
		local key = o.Default
		local listening = false
		local row = flatRow("Frame", ROW + 2)
		nameLabel(row, o.Name or "Keybind", o.Help, 2, 0, ROW + 2)
		local fb = field(row, UDim2.fromOffset(74, ROW - 4))
		local btn = new("TextButton", {
			Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Tx = "accent", Text = key and key.Name or "None",
			FontFace = mono(W_.Medium), TextSize = 11, AutoButtonColor = false, BorderSizePixel = 0, Parent = fb,
		})
		local obj = {Instance = row}
		function obj.Get() return key end
		function obj.Set(k) key = k; btn.Text = key and key.Name or "None" end
		btn.MouseButton1Click:Connect(function() listening = true; Listening = true; btn.Text = "..." end)
		bind(UIS.InputBegan, function(i, gp)
			if listening then
				if i.UserInputType == Enum.UserInputType.Keyboard then
					if i.KeyCode == Enum.KeyCode.Backspace then key = nil
					elseif i.KeyCode ~= Enum.KeyCode.Escape then key = i.KeyCode end
					listening = false
					btn.Text = key and key.Name or "None"
					if o.OnChange then task.spawn(pcall, o.OnChange, key) end
					task.delay(0.15, function() Listening = false end)
				end
				return
			end
			if not gp and key and i.KeyCode == key and o.Callback then task.spawn(pcall, o.Callback) end
		end)
		track(o.Name, row)
		return obj
	end

	function self:ColorPicker(o)
		added()
		local first = order == 0
		local col = o.Default or Color3.fromRGB(255, 255, 255)
		local h, s, v = col:ToHSV()
		local frame = new("Frame", {
			LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = host,
		}, {new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
		local head = new("TextButton", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, ROW + 2), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame})
		lineIf(first, head)
		nameLabel(head, o.Name or "Color", o.Help, 2, 0, ROW + 2)
		local sw = new("Frame", {Size = UDim2.fromOffset(30, 16), AnchorPoint = Vector2.new(1, 0.5), Position = UDim2.new(1, -2, 0.5, 0), BackgroundColor3 = col, BorderSizePixel = 0, Parent = head},
			{round(5), stroke(Color3.new(1, 1, 1), 1, 0.7)})
		local panelBody = new("Frame", {Size = UDim2.new(1, 0, 0, 100), BackgroundTransparency = 1})
		local sv = new("Frame", {Position = UDim2.fromOffset(2, 2), Size = UDim2.new(1, -4, 0, 70), BackgroundColor3 = Color3.fromHSV(h, 1, 1), BorderSizePixel = 0, Parent = panelBody}, {round(6)})
		new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = sv},
			{round(6), new("UIGradient", {Transparency = NumberSequence.new(0, 1)})})
		new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = sv},
			{round(6), new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new(1, 0)})})
		local svc = new("Frame", {Size = UDim2.fromOffset(8, 8), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(s, 1 - v), BackgroundTransparency = 1, ZIndex = 3, Parent = sv},
			{round("full"), stroke(Color3.new(1, 1, 1), 1.5)})
		local svHit = new("TextButton", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = sv})
		local hue = new("Frame", {Position = UDim2.fromOffset(2, 78), Size = UDim2.new(1, -4, 0, 10), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = panelBody}, {
			round("full"),
			new("UIGradient", {Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, rgb(255, 0, 0)), ColorSequenceKeypoint.new(1 / 6, rgb(255, 255, 0)), ColorSequenceKeypoint.new(2 / 6, rgb(0, 255, 0)),
				ColorSequenceKeypoint.new(3 / 6, rgb(0, 255, 255)), ColorSequenceKeypoint.new(4 / 6, rgb(0, 0, 255)), ColorSequenceKeypoint.new(5 / 6, rgb(255, 0, 255)),
				ColorSequenceKeypoint.new(1, rgb(255, 0, 0)),
			})}),
		})
		local huec = new("Frame", {Size = UDim2.fromOffset(6, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(h, 0.5), BackgroundTransparency = 1, ZIndex = 3, Parent = hue},
			{round(3), stroke(Color3.new(1, 1, 1), 1.5)})
		local hueHit = new("TextButton", {Size = UDim2.new(1, 0, 0, 22), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.fromScale(0, 0.5), BackgroundTransparency = 1, Text = "", ZIndex = 4, Parent = hue})
		local _, setPanel = collapse(frame, 2, false, panelBody)
		local function upd(fire)
			col = Color3.fromHSV(h, s, v)
			sw.BackgroundColor3 = col
			sv.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
			svc.Position = UDim2.fromScale(s, 1 - v)
			huec.Position = UDim2.fromScale(h, 0.5)
			if fire and o.Callback then task.spawn(pcall, o.Callback, col) end
		end
		local mode
		local function pick(x, y)
			if mode == "sv" then
				s = math.clamp((x - sv.AbsolutePosition.X) / sv.AbsoluteSize.X, 0, 1)
				v = 1 - math.clamp((y - sv.AbsolutePosition.Y) / sv.AbsoluteSize.Y, 0, 1)
			elseif mode == "hue" then
				h = math.clamp((x - hue.AbsolutePosition.X) / hue.AbsoluteSize.X, 0, 1)
			end
			upd(true)
		end
		svHit.InputBegan:Connect(function(i) if isPress(i) then mode = "sv"; pick(i.Position.X, i.Position.Y) end end)
		hueHit.InputBegan:Connect(function(i) if isPress(i) then mode = "hue"; pick(i.Position.X, i.Position.Y) end end)
		bind(UIS.InputChanged, function(i) if mode and isMove(i) then pick(i.Position.X, i.Position.Y) end end)
		bind(UIS.InputEnded, function(i) if isPress(i) then mode = nil end end)
		local open = false
		head.MouseButton1Click:Connect(function() open = not open; setPanel(open) end)
		local obj = {Instance = frame}
		function obj.Get() return col end
		function obj.Set(c) h, s, v = c:ToHSV(); upd(false) end
		track(o.Name, frame)
		return obj
	end

	function self:InfoRow(o)
		added()
		local row = flatRow("Frame", ROW)
		T{p = row, t = o.Name or "", f = sans(W_.Medium), s = 12, c = "sub", pos = UDim2.fromOffset(2, 0), sz = UDim2.new(0.5, -2, 1, 0)}
		local vl = T{p = row, t = tostring(o.Value or ""), f = mono(W_.Medium), s = 11, c = "text", xa = Enum.TextXAlignment.Right,
			pos = UDim2.new(1, -2, 0, 0), ap = Vector2.new(1, 0), sz = UDim2.new(0.5, -2, 1, 0)}
		local obj = {Instance = row}
		function obj.Set(v) vl.Text = tostring(v) end
		function obj.Get() return vl.Text end
		track(o.Name, row)
		return obj
	end

	function self:ProgressBar(o)
		added()
		local min, max = o.Min or 0, o.Max or 100
		local val = math.clamp(o.Default or min, min, max)
		local row = flatRow("Frame", ROW + 12)
		nameLabel(row, o.Name or "Progress", o.Help, 2, 2, 20)
		local vl = T{p = row, t = "", f = mono(W_.Medium), s = 11, c = "accent", xa = Enum.TextXAlignment.Right,
			pos = UDim2.new(1, -2, 0, 2), ap = Vector2.new(1, 0), sz = UDim2.new(0.5, -2, 0, 20)}
		local tr = new("Frame", {Size = UDim2.new(1, -4, 0, 6), Position = UDim2.new(0, 2, 0, ROW + 2), Bg = "off", BorderSizePixel = 0, Parent = row}, {round("full")})
		local fill = new("Frame", {Size = UDim2.fromScale(0, 1), Bg = "accent", BorderSizePixel = 0, Parent = tr}, {round("full")})
		local function render(instant)
			local a = max > min and math.clamp((val - min) / (max - min), 0, 1) or 0
			if instant then fill.Size = UDim2.fromScale(a, 1) else tweenE(fill, 0.25, {Size = UDim2.fromScale(a, 1)}) end
			vl.Text = o.Format and o.Format(val, max) or string.format("%g / %g", val, max)
		end
		render(true)
		local obj = {Instance = row}
		function obj.Get() return val end
		function obj.Set(v) val = math.clamp(v, min, max); render(false) end
		function obj.SetMax(m) max = m; val = math.clamp(val, min, max); render(false) end
		track(o.Name, row)
		return obj
	end

	function self:Hint(o)
		added()
		local first = order == 0
		local open = false
		local frame = new("Frame", {
			LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = host,
		}, {new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
		local head = new("TextButton", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, ROW + 2), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = frame})
		lineIf(first, head)
		icon(head, "info", 14, "accent", UDim2.new(0, 2, 0.5, -7))
		T{p = head, t = o.Title or "How it works", f = sans(W_.Medium), s = 12, c = "accent", pos = UDim2.fromOffset(24, 0), sz = UDim2.new(0.5, 0, 1, 0)}
		T{p = head, t = "Tap to read", f = sans(W_.Regular), s = 10, c = "mute", xa = Enum.TextXAlignment.Right, pos = UDim2.new(1, -24, 0, 0), ap = Vector2.new(1, 0), sz = UDim2.new(0.4, 0, 1, 0)}
		local chev = chevron(head, 10, false)
		local body = new("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = o.Content or "", FontFace = sans(W_.Regular), TextSize = 11, Tx = "sub", TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top,
		}, {new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingBottom = UDim.new(0, 8)})})
		local _, setBody = collapse(frame, 2, false, body)
		head.MouseButton1Click:Connect(function()
			open = not open
			setBody(open)
			tweenE(chev, 0.26, {Rotation = open and 90 or 0}, Enum.EasingStyle.Quint)
		end)
		track((o.Title or "") .. " " .. (o.Content or ""), frame)
		return frame
	end

	function self:ThemePicker(o)
		o = o or {}
		added()
		local wrap = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 62), BackgroundTransparency = 1, Parent = host})
		local row = new("Frame", {Size = UDim2.new(1, 0, 0, 52), Position = UDim2.fromOffset(0, 5), BackgroundTransparency = 1, Parent = wrap},
			{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder})})
		for i, name in ipairs(THEME_ORDER) do
			local th, meta = THEMES[name], THEME_META[name]
			local st = stroke(C.btnLine, 1)
			local b = new("TextButton", {
				LayoutOrder = i, Size = UDim2.new(1 / #THEME_ORDER, -6 * (#THEME_ORDER - 1) / #THEME_ORDER, 1, 0), Bg = "btn", Tr = "btnT",
				Text = "", AutoButtonColor = false, BorderSizePixel = 0, Parent = row,
			}, {round(8), st})
			local sw = new("Frame", {Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(8, 9), BackgroundColor3 = Color3.new(1, 1, 1), BorderSizePixel = 0, Parent = b},
				{round(8), stroke(th.border, 1), new("UIGradient", {Rotation = 90, Color = ColorSequence.new(th.winA, th.winB)})})
			icon(sw, meta[1], 16, th.accent, UDim2.fromOffset(9, 9))
			T{p = b, t = name, f = sans(W_.SemiBold), s = 12, pos = UDim2.fromOffset(50, 9), sz = UDim2.new(1, -54, 0, 16)}
			T{p = b, t = meta[2], f = sans(W_.Regular), s = 10, c = "mute", pos = UDim2.fromOffset(50, 26), sz = UDim2.new(1, -54, 0, 14)}
			themed(function(instant)
				local on = ThemeName == name
				set(st, {Color = on and C.accent or C.btnLine, Thickness = on and 1.5 or 1}, instant)
			end)
			b.MouseButton1Click:Connect(function() setTheme(name); if o.Callback then task.spawn(pcall, o.Callback, name) end end)
		end
		track("theme appearance", wrap)
		return wrap
	end

	function self:Label(text)
		added()
		local l = new("TextLabel", {
			LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1,
			Text = text, FontFace = sans(W_.Regular), TextSize = 11, Tx = "mute", TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = host,
		}, {new("UIPadding", {PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 2), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 4)})})
		track(text, l)
		return l
	end

	function self:Paragraph(o)
		added()
		local wrap = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = host},
			{new("UIPadding", {PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5)})})
		local box = new("Frame", {
			Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, Bg = "btn", Tr = "btnT", BorderSizePixel = 0, Parent = wrap,
		}, {
			round(8), stroke("btnLine", 1),
			new("UIPadding", {PaddingTop = UDim.new(0, 7), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10)}),
			new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
		})
		new("TextLabel", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = o.Title or "", FontFace = sans(W_.SemiBold), TextSize = 12, Tx = "text", TextXAlignment = Enum.TextXAlignment.Left, Parent = box})
		new("TextLabel", {LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = o.Content or "", FontFace = sans(W_.Regular), TextSize = 11, Tx = "mute", TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = box})
		track((o.Title or "") .. " " .. (o.Content or ""), wrap)
		return wrap
	end

	function self:Section(title)
		added()
		local row = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = host})
		local w = measure(string.upper(title), sans(W_.SemiBold), 10) + 8
		T{p = row, t = string.upper(title), f = sans(W_.SemiBold), s = 10, c = "mute", pos = UDim2.fromOffset(2, 6), sz = UDim2.new(0, w, 0, 18)}
		new("Frame", {Size = UDim2.new(1, -w - 8, 0, 1), Position = UDim2.new(0, w + 6, 0, 15), Bg = "cardLine", BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = row})
		track(title, row)
		return row
	end

	function self:Divider()
		added()
		local row = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 9), BackgroundTransparency = 1, Parent = host})
		new("Frame", {Size = UDim2.new(1, 0, 0, 1), Position = UDim2.fromOffset(0, 4), Bg = "cardLine", BackgroundTransparency = 0.45, BorderSizePixel = 0, Parent = row})
		return row
	end

	-- การ์ดดิบ (ขนาดตายตัว) ใช้กับหน้า Home ฯลฯ  -> คืน card, inner, stroke
	function self:Raw(height)
		added()
		return factory(height)
	end

	-- หมวด: ระดับหน้า = การ์ดคู่แถวละ 2 ใบ | ซ้อนในการ์ด = หัวข้อแบบเส้นพับได้
	function self:Group(title, iconName, opts)
		added()
		opts = opts or {}
		local nested = not factory
		local gscope = {items = {}}
		local headless = opts.Headless == true
		local gt = {title = tostring(title or ""):lower(), scope = gscope, open = headless or not opts.Closed}
		local card, content, head, body, chev

		if nested then
			card = new("Frame", {LayoutOrder = nextOrder(), Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = host},
				{new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
			content = card
			head = new("TextButton", {LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = content})
			local up = string.upper(title or "")
			local w = measure(up, sans(W_.SemiBold), 10) + 8
			T{p = head, t = up, f = sans(W_.SemiBold), s = 10, c = "sub", pos = UDim2.fromOffset(2, 2), sz = UDim2.new(0, w, 1, -2)}
			new("Frame", {Size = UDim2.new(1, -(w + 34), 0, 1), Position = UDim2.new(0, w + 6, 0.5, 1), Bg = "cardLine", BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = head})
			chev = chevron(head, 8, gt.open)
			body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1},
				{new("UIPadding", {PaddingBottom = UDim.new(0, 4)}), new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
		else
			card, content = factory()
			if not headless then
				head = new("TextButton", {LayoutOrder = 0, Size = UDim2.new(1, 0, 0, ROW + 8), BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = content})
				new("Frame", {Size = UDim2.fromOffset(3, 14), AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 12, 0.5, 0), Bg = "accent", BorderSizePixel = 0, Parent = head}, {round("full")})
				local tx = 24
				if iconName and LUCIDE[iconName] then icon(head, iconName, 14, "sub", UDim2.new(0, 24, 0.5, -7)); tx = 44 end
				T{p = head, t = title or "", f = sans(W_.SemiBold), s = 13, pos = UDim2.fromOffset(tx, 0), sz = UDim2.new(1, -tx - 28, 1, 0)}
				chev = chevron(head, 16, gt.open)
			end
			body = new("Frame", {Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1}, {
				new("UIPadding", {PaddingTop = UDim.new(0, headless and 8 or 0), PaddingBottom = UDim.new(0, 8), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14)}),
				new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder}),
			})
		end

		local setOpen = function() end
		if headless then
			body.LayoutOrder = 1
			body.Parent = content
		else
			local _, so = collapse(content, 1, gt.open, body)
			setOpen = so
		end
		gt.frame = card
		function gt.refresh()
			setOpen(gt.open or SearchQuery ~= "", true)
			if chev then chev.Rotation = gt.open and 90 or 0 end
		end
		if head then
			head.MouseButton1Click:Connect(function()
				gt.open = not gt.open
				setOpen(gt.open or SearchQuery ~= "")
				tweenE(chev, 0.26, {Rotation = gt.open and 90 or 0}, Enum.EasingStyle.Quint)
			end)
		end
		if scope and scope.groups and not nested then
			table.insert(scope.groups, gt)
		else
			track(function()
				local t = gt.title
				for _, it in ipairs(gscope.items) do t = t .. " " .. (type(it.name) == "function" and it.name() or it.name) end
				return t
			end, card)
		end
		local g = Container(body, onAdd, gscope)
		g.Card = card
		function g.SetOpen(v) gt.open = v; gt.refresh() end
		return g
	end

	-- Flag: ใส่ Flag = "ชื่อ" ในตัวควบคุมเพื่อให้ระบบ Config เซฟ/โหลดได้
	for _, m in ipairs({"Toggle", "Slider", "Dropdown", "Input", "Keybind", "ColorPicker"}) do
		local orig = self[m]
		self[m] = function(s, o, ...)
			local obj = orig(s, o, ...)
			if type(o) == "table" and o.Flag and obj then Flags[o.Flag] = {obj = obj, opts = o, kind = m} end
			return obj
		end
	end

	-- ฝั่งของหน้า (Left/Right): ถ้าเรียกคอมโพเนนต์ตรงๆ ให้ใส่ในการ์ดไม่มีหัวอัตโนมัติ
	if factory then
		local implicit
		local origGroup = self.Group
		for _, m in ipairs(LOOSE) do
			self[m] = function(_, ...)
				if not implicit then implicit = origGroup(self, nil, nil, {Headless = true}) end
				return implicit[m](implicit, ...)
			end
		end
		self.Group = function(s, ...) implicit = nil; return origGroup(s, ...) end
	end

	return self
end

----------------------------------------------------------------
-- PAGES (หมวดเป็นแถว แถวละ 2 ใบ สูงเท่ากัน) + TABS + SEARCH
----------------------------------------------------------------
local Tabs, Pages, TabOrder, Current = {}, {}, {}, nil

local function syncRow(row)
	local h = 0
	for _, key in ipairs({"L", "R"}) do
		local s = row[key]
		if s and s.card.Visible then h = math.max(h, s.inner.AbsoluteSize.Y / Scale.Scale) end
	end
	row.frame.Size = UDim2.new(1, 0, 0, h)
end

local function makePage(name, iconName)
	local holder = new("CanvasGroup", {Name = name, Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Visible = false, Parent = Content})
	local scroller = new("ScrollingFrame", {
		Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, BorderSizePixel = 0,
		CanvasSize = UDim2.new(), AutomaticCanvasSize = Enum.AutomaticSize.Y, ScrollBarThickness = 3,
		ScrollBarImageColor3 = Color3.fromRGB(80, 92, 110), ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never, Parent = holder,
	}, {
		new("UIPadding", {PaddingLeft = UDim.new(0, L.PAD), PaddingRight = UDim.new(0, L.PAD), PaddingTop = UDim.new(0, 14), PaddingBottom = UDim.new(0, 18)}),
		new("UIListLayout", {FillDirection = Enum.FillDirection.Vertical, Padding = UDim.new(0, L.GAP), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	local empty
	if name ~= "Home" then
		empty = new("Frame", {LayoutOrder = 999, Size = UDim2.new(1, 0, 0, 190), BackgroundTransparency = 1, Parent = scroller})
		icon(empty, iconName, 30, rgb(80, 92, 110), UDim2.new(0.5, -15, 0, 50))
		T{p = empty, t = name, f = sans(W_.SemiBold), s = 16, c = "sub", pos = UDim2.fromOffset(0, 92), sz = UDim2.new(1, 0, 0, 24), xa = Enum.TextXAlignment.Center}
		T{p = empty, t = "Coming soon", f = sans(W_.Medium), s = 12, c = "mute", pos = UDim2.fromOffset(0, 116), sz = UDim2.new(1, 0, 0, 20), xa = Enum.TextXAlignment.Center}
	end
	local function onAdd() if empty then empty.Visible = false end end

	local scope = {items = {}, groups = {}}
	local page = {Name = name, Holder = holder, Frame = scroller, Scope = scope, Rows = {}}

	-- slot = การ์ดหนึ่งใบในแถวที่ k ฝั่ง which
	local function makeSlot(k, which, fixedH)
		local row = page.Rows[k]
		if not row then
			row = {frame = new("Frame", {Name = "Row" .. k, LayoutOrder = k, Size = UDim2.new(1, 0, 0, 0), BackgroundTransparency = 1, Parent = scroller})}
			page.Rows[k] = row
		end
		local left = which == "L"
		local st = stroke("cardLine", 1.2)
		local card = new("Frame", {
			Size = UDim2.new(0.5, -L.GAP / 2, 1, 0), Position = UDim2.new(left and 0 or 0.5, left and 0 or L.GAP / 2, 0, 0),
			Bg = "card", Tr = "cardT", BorderSizePixel = 0, Parent = row.frame,
		}, {round(L.R_CARD), st})
		local inner = new("Frame", {
			Size = UDim2.new(1, 0, 0, fixedH or 0), AutomaticSize = fixedH and Enum.AutomaticSize.None or Enum.AutomaticSize.Y, BackgroundTransparency = 1, Parent = card,
		}, {new("UIListLayout", {SortOrder = Enum.SortOrder.LayoutOrder})})
		row[which] = {card = card, inner = inner}
		inner:GetPropertyChangedSignal("AbsoluteSize"):Connect(function() syncRow(row) end)
		card:GetPropertyChangedSignal("Visible"):Connect(function() syncRow(row) end)
		task.defer(function() syncRow(row) end)
		return card, inner, st
	end
	local function sideFactory(which)
		local count = 0
		return function(fixedH) count += 1; return makeSlot(count, which, fixedH) end
	end
	page.Left = Container(nil, onAdd, scope, sideFactory("L"))
	page.Right = Container(nil, onAdd, scope, sideFactory("R"))
	Pages[name] = page
	return page
end

local function nm(it) return type(it.name) == "function" and it.name() or it.name end
local function filterPage(page, q)
	q = (q or ""):lower()
	local searching = q ~= ""
	local function match(s) return s:find(q, 1, true) ~= nil end
	for _, it in ipairs(page.Scope.items) do it.frame.Visible = (not searching) or match(nm(it)) end
	for _, g in ipairs(page.Scope.groups) do
		local any, titleHit = false, searching and g.title ~= "" and match(g.title)
		for _, it in ipairs(g.scope.items) do
			local vis = (not searching) or titleHit or match(nm(it))
			it.frame.Visible = vis
			any = any or vis
		end
		g.frame.Visible = (not searching) or titleHit or any
		g.refresh()
	end
	task.defer(function() for _, row in pairs(page.Rows) do syncRow(row) end end)
end

local function paintTabs(instant)
	local d = instant and 0 or 0.2
	for n, t in pairs(Tabs) do
		local on = n == Current
		tween(t.btn, d, {BackgroundTransparency = on and 0 or 1, BackgroundColor3 = C.tabOn})
		tween(t.lbl, d, {TextColor3 = on and C.text or C.sub})
		tween(t.ico, d, {ImageColor3 = on and C.text or C.sub})
		t.line.Color = C.tabLine
		t.line.Enabled = on
	end
end
themed(function(instant) paintTabs(instant) end)

local function reveal(btn)
	task.defer(function()
		local w = NavScroll.AbsoluteWindowSize.X
		local left = btn.AbsolutePosition.X - NavScroll.AbsolutePosition.X + NavScroll.CanvasPosition.X
		local target = left - (w - btn.AbsoluteSize.X) / 2
		tweenE(NavScroll, 0.4, {CanvasPosition = Vector2.new(math.clamp(target, 0, navMax()), 0)}, Enum.EasingStyle.Quint)
	end)
end

local function select_(name)
	if Current == name or not Tabs[name] then return end
	local prev = Current
	Current = name
	closeModal(true)
	if prev and Pages[prev] then filterPage(Pages[prev], "") end
	for n in pairs(Tabs) do Pages[n].Holder.Visible = (n == name) end
	paintTabs(false)
	local h = Pages[name].Holder
	h.GroupTransparency = 1
	h.Position = UDim2.fromOffset(0, 10)
	tweenE(h, 0.3, {GroupTransparency = 0, Position = UDim2.fromOffset(0, 0)}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
	if SearchBox.Visible and SearchBox.Text ~= "" then filterPage(Pages[name], SearchBox.Text) end
	reveal(Tabs[name].btn)
end

local function addTab(name, ic)
	local tw = measure(name, sans(W_.Medium), 13)
	local btn = new("TextButton", {
		Name = name, LayoutOrder = #TabOrder + 1, Size = UDim2.fromOffset(math.ceil(tw) + 52, 34),
		BackgroundColor3 = C.tabOn, BackgroundTransparency = 1, Text = "", AutoButtonColor = false, Parent = NavScroll,
	}, {round(L.R_TAB)})
	local line = stroke(C.tabLine, 1.5); line.Enabled = false; line.Parent = btn
	local ico = icon(btn, ic, 16, C.sub, UDim2.new(0, 14, 0.5, -8))
	local lbl = T{p = btn, t = name, f = sans(W_.Medium), s = 13, c = C.sub, pos = UDim2.fromOffset(38, 0), sz = UDim2.new(1, -38, 1, 0)}
	Tabs[name] = {btn = btn, lbl = lbl, ico = ico, line = line}
	table.insert(TabOrder, name)
	local page = makePage(name, ic)
	btn.MouseButton1Click:Connect(function() select_(name) end)
	btn.MouseEnter:Connect(function() if Current ~= name then tween(lbl, 0.1, {TextColor3 = C.hoverText}); tween(ico, 0.1, {ImageColor3 = C.hoverText}) end end)
	btn.MouseLeave:Connect(function() if Current ~= name then tween(lbl, 0.1, {TextColor3 = C.sub}); tween(ico, 0.1, {ImageColor3 = C.sub}) end end)
	paintTabs(true)
	return page
end
for _, def in ipairs(CFG.Tabs) do addTab(def[1], def[2]) end

local searchOpen = false
local function setSearch(open)
	searchOpen = open
	if open then
		SearchBox.Visible = true
		tweenE(SearchBox, 0.28, {Size = UDim2.fromOffset(150, 24)}, Enum.EasingStyle.Quint)
		SearchBox:CaptureFocus()
	else
		SearchBox.Text = ""
		tweenE(SearchBox, 0.2, {Size = UDim2.fromOffset(0, 24)}, Enum.EasingStyle.Quint)
		task.delay(0.22, function() if not searchOpen then SearchBox.Visible = false end end)
	end
end
BtnSearch.MouseButton1Click:Connect(function() setSearch(not searchOpen) end)
SearchBox:GetPropertyChangedSignal("Text"):Connect(function()
	SearchQuery = SearchBox.Text
	if Current then filterPage(Pages[Current], SearchQuery) end
end)
SearchBox.FocusLost:Connect(function() if SearchBox.Text == "" then setSearch(false) end end)

----------------------------------------------------------------
-- HOME
----------------------------------------------------------------
local Home = Pages.Home
local StatsRow = new("Frame", {LayoutOrder = 0, Size = UDim2.new(1, 0, 0, 76), BackgroundTransparency = 1, Parent = Home.Frame},
	{new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, L.GAP)})})

local StatLabels = {}
local function statCard(key, caption, value, o)
	o = o or {}
	local st = stroke("cardLine", 1.2)
	local card = new("Frame", {Size = UDim2.new(0.25, -L.GAP * 3 / 4, 1, 0), Bg = "card", Tr = "cardT", BorderSizePixel = 0, Active = true, Parent = StatsRow}, {round(L.R_CARD), st})
	hoverStroke(card, st, "cardLine", "btnHoverLine")
	T{p = card, t = caption, f = sans(W_.Medium), s = 11, c = "mute", pos = UDim2.fromOffset(14, 11), sz = UDim2.new(1, -20, 0, 14)}
	local x, dotObj = 14, nil
	if o.dot then
		dotObj = new("Frame", {Size = UDim2.fromOffset(8, 8), Position = UDim2.fromOffset(14, 45), Bg = "accent", BorderSizePixel = 0, Parent = card}, {round("full")})
		x = 31
	end
	local face = o.mono and mono(W_.Bold) or sans(W_.Bold)
	local v = T{p = card, t = value, f = face, s = 24, c = o.green and "accent" or "text", pos = UDim2.fromOffset(x, 33), sz = UDim2.new(1, -x - 8, 0, 32)}
	local tag
	local function place() if tag then tag.Position = UDim2.fromOffset(x + measure(v.Text, face, 24) + 8, 44) end end
	if o.tag then
		tag = T{p = card, t = o.tag, f = sans(W_.Medium), s = 10, c = "accent", sz = UDim2.fromOffset(60, 14)}
		place()
	end
	StatLabels[key] = {label = v, dot = dotObj, place = place}
end
statCard("Session", "Session Time", "00:00:00", {mono = true})
statCard("Equipped", "Equipped", tostring(CFG.Stats.Equipped))
statCard("Units", "Units", tostring(CFG.Stats.Units), {tag = "Unlocked"})
statCard("Ping", "Ping", "--", {green = true, dot = true})

-- การ์ด Current Game อยู่แถวที่ 1 ฝั่งซ้าย (ขนาดตายตัว 218)
local GameSlot, GameCard, gcLine = Home.Left:Raw(218)
hoverStroke(GameSlot, gcLine, "cardLine", "btnHoverLine")
icon(GameCard, "gamepad-2", 16, "sub", UDim2.fromOffset(14, 18))
T{p = GameCard, t = "Current Game", f = sans(W_.SemiBold), s = 13, pos = UDim2.fromOffset(38, 14), sz = UDim2.fromOffset(150, 24)}

local Badge = new("Frame", {Size = UDim2.fromOffset(86, 22), AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -14, 0, 15), Bg = "badgeBg", BorderSizePixel = 0, Parent = GameCard},
	{round("full"), stroke("badgeLine", 1)})
local BDot = new("Frame", {Size = UDim2.fromOffset(6, 6), Position = UDim2.fromOffset(12, 8), Bg = "accent", BorderSizePixel = 0, Parent = Badge}, {round("full")})
T{p = Badge, t = "Attached", f = mono(W_.Medium), s = 11, c = "accent", pos = UDim2.fromOffset(25, 0), sz = UDim2.new(1, -28, 1, 0)}
task.spawn(function()
	while BDot.Parent do
		tween(BDot, 1, {BackgroundTransparency = 0.65}); task.wait(1)
		tween(BDot, 1, {BackgroundTransparency = 0}); task.wait(1)
	end
end)

local Cover = new("ImageLabel", {
	Size = UDim2.new(1, -28, 0, 156), Position = UDim2.fromOffset(14, 48), BackgroundColor3 = Color3.new(1, 1, 1),
	Image = CFG.GameImage or ("rbxthumb://type=GameIcon&id=" .. tostring(game.GameId) .. "&w=512&h=512"),
	ScaleType = Enum.ScaleType.Crop, BorderSizePixel = 0, ClipsDescendants = true, Parent = GameCard,
}, {round(L.R_COVER)})
do
	local cg = new("UIGradient", {Rotation = 90, Parent = Cover})
	themed(function() cg.Color = ColorSequence.new(C.coverA, C.coverB) end)
end
new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.new(0, 0, 0), BorderSizePixel = 0, Parent = Cover},
	{new("UIGradient", {Rotation = 90, Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.42, 0.88), NumberSequenceKeypoint.new(1, 0.1),
	})})})
local Tag = new("Frame", {Size = UDim2.fromOffset(56, 18), Position = UDim2.fromOffset(12, 96), BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = Cover},
	{round(5), stroke(Color3.new(1, 1, 1), 1, 0.9)})
T{p = Tag, t = "ROBLOX", f = mono(W_.Medium), s = 10, c = rgb(232, 235, 242), xa = Enum.TextXAlignment.Center}
local GameTitle = T{p = Cover, t = CFG.GameName or "Loading...", f = sans(W_.Bold), s = 20, c = Color3.new(1, 1, 1), pos = UDim2.fromOffset(12, 118), sz = UDim2.new(1, -24, 0, 28)}
task.spawn(function()
	if CFG.GameName then return end
	local ok, info = pcall(function() return MarketplaceService:GetProductInfo(game.PlaceId) end)
	GameTitle.Text = (ok and info and info.Name) or "Unknown Game"
end)

----------------------------------------------------------------
-- NOTIFY
----------------------------------------------------------------
local ToastHost = new("Frame", {
	Size = UDim2.fromOffset(240, 0), AutomaticSize = Enum.AutomaticSize.Y, AnchorPoint = Vector2.new(1, 1),
	Position = UDim2.new(1, -16, 1, -16), BackgroundTransparency = 1, Parent = Gui,
}, {new("UIListLayout", {Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Bottom})})
local toastN = 0
local function notify(o)
	toastN += 1
	local g = new("CanvasGroup", {
		LayoutOrder = toastN, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = C.card,
		BorderSizePixel = 0, GroupTransparency = 1, Parent = ToastHost,
	}, {
		round(10), stroke(C.cardLine, 1),
		new("UIPadding", {PaddingTop = UDim.new(0, 9), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 12)}),
		new("UIListLayout", {Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder}),
	})
	new("TextLabel", {LayoutOrder = 1, Size = UDim2.new(1, 0, 0, 16), BackgroundTransparency = 1, Text = o.Title or "Zenith", FontFace = sans(W_.SemiBold), TextSize = 12, TextColor3 = C.accent, TextXAlignment = Enum.TextXAlignment.Left, Parent = g})
	if o.Content then
		new("TextLabel", {LayoutOrder = 2, Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundTransparency = 1, Text = o.Content, FontFace = sans(W_.Regular), TextSize = 11, TextColor3 = C.sub, TextWrapped = true, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Top, Parent = g})
	end
	tweenE(g, 0.3, {GroupTransparency = 0}, Enum.EasingStyle.Quint)
	task.delay(o.Duration or 3, function()
		if not g.Parent then return end
		tween(g, 0.3, {GroupTransparency = 1})
		task.wait(0.35)
		g:Destroy()
	end)
end

----------------------------------------------------------------
-- DEMO: MACRO  (แถว 1: Auto Farm | Actions   แถว 2: Items | Display) -- แก้ Callback เป็นของคุณ
----------------------------------------------------------------
do
	local macro = Pages.Macro
	local farm = macro.Left:Group("Auto Farm", "zap")
	farm:Toggle{Name = "Auto Start", Help = "เริ่มอัตโนมัติเมื่อเข้าด่าน", Default = false, Callback = function(v) print("[Zenith] Auto Start", v) end}
	farm:Slider{Name = "Stop after losses", Min = 0, Max = 10, Step = 1, Default = 0, Callback = function(v) print("[Zenith] Stop after", v) end}
	farm:Toggle{Name = "Auto Replay", Help = "เล่นซ้ำเองเมื่อจบรอบ", Default = true, Callback = function(v) print("[Zenith] Auto Replay", v) end}
	farm:Dropdown{Name = "Mode", Options = {"Normal", "Fast", "Safe"}, Default = "Normal", Callback = function(v) print("[Zenith] Mode", v) end}
	farm:InfoRow{Name = "Wave", Value = "7 / 15"}
	farm:Hint{Title = "How it works", Content = "กล่องคำอธิบายแบบพับได้ ใช้อธิบายวิธีใช้ฟีเจอร์ให้ผู้เล่นอ่านเมื่อกด Tap to read"}

	local act = macro.Right:Group("Actions", "play")
	act:ButtonRow{
		{Name = "Start", Icon = "play", Style = "primary", Callback = function() print("[Zenith] Start") end},
		{Name = "Stop", Icon = "power", Style = "danger", Callback = function() print("[Zenith] Stop") end},
	}
	act:Input{Name = "Wave Limit", Numeric = true, Default = "50", Min = 1, Max = 999, Callback = function(n) print("[Zenith] Wave", n) end}
	act:Keybind{Name = "Start Key", Default = Enum.KeyCode.F, Callback = function() print("[Zenith] Start key pressed") end}
	local adv = act:Group("Advanced", nil, {Closed = true})
	adv:Toggle{Name = "Smart retry", Default = false, Callback = function(v) print("[Zenith] Smart retry", v) end}
	adv:Slider{Name = "Retry limit", Min = 1, Max = 10, Step = 1, Default = 3, Callback = function(v) print("[Zenith] Retry", v) end}

	-- ตัวอย่างตารางไอเท็ม 2 คอลัมน์ 24 รายการ (ชื่อ + คำอธิบาย) ใส่ Image = "rbxassetid://..." ให้ตัวที่มีรูปได้
	local items = {
		{Name = "Bow", Desc = "+20% Range"}, {Name = "Dagger", Desc = "+15% Attack"}, {Name = "Nimble Cloak", Desc = "-7% Attack Cooldown"},
		{Name = "Treasure Chest", Desc = "+1 Treasure Chest (Instant)"}, {Name = "Axe", Desc = "+50% Phys Crit Chance"}, {Name = "Fishhook", Desc = "+20% Chest Luck"},
		{Name = "Golden Branch", Desc = "-15% Placement/Upgrade Cost"}, {Name = "Ice Dagger", Desc = "-20% Enemy Speed"},
	}
	for _, n in ipairs({"Shield", "Spear", "Staff", "Lantern", "Compass", "Ring", "Amulet", "Crown", "Boots", "Gloves", "Helmet", "Cape", "Orb", "Scroll", "Potion", "Key"}) do
		table.insert(items, {Name = n, Desc = "+10% Bonus"})
	end
	local loot = macro.Left:Group("Items", "list")
	loot:Dropdown{Name = "Buy items", Help = "ตารางเลือก 2 คอลัมน์ เลือกได้หลายอัน", Options = items, Multi = true, Default = {"Bow", "Axe"},
		Callback = function(l) print("[Zenith] Buy", table.concat(l, ",")) end}
	loot:Dropdown{Name = "Best pick", Options = items, Default = "Dagger", Callback = function(v) print("[Zenith] Best pick", v) end}

	local disp = macro.Right:Group("Display", "palette")
	disp:ColorPicker{Name = "Marker Color", Default = Color3.fromRGB(52, 211, 153), Callback = function(c) print("[Zenith] Color", c) end}
	disp:Toggle{Name = "Show markers", Default = true, Callback = function(v) print("[Zenith] Markers", v) end}
end

----------------------------------------------------------------
-- SETTINGS (ใช้งานได้จริง)
----------------------------------------------------------------
function setTheme(name)
	if not THEMES[name] then return end
	closeModal(true)
	loadPalette(name)
	for _, f in ipairs(reg) do pcall(f, false) end
	fxUpdate()
	if CFG.OnThemeChanged then task.spawn(pcall, CFG.OnThemeChanged, name) end
end
local function setGlass(g)
	Glass = math.clamp(g, 0, 0.85)
	derive()
	for _, f in ipairs(reg) do pcall(f, true) end
end

-- CONFIG (เซฟ/โหลดค่าของทุกตัวควบคุมที่ใส่ Flag)
local function ser(v)
	local t = typeof(v)
	if t == "Color3" then return {__t = "c3", r = v.R, g = v.G, b = v.B} end
	if t == "EnumItem" then return {__t = "key", name = v.Name} end
	return v
end
local function de(v)
	if type(v) == "table" and v.__t == "c3" then return Color3.new(v.r, v.g, v.b) end
	if type(v) == "table" and v.__t == "key" then
		local ok, k = pcall(function() return Enum.KeyCode[v.name] end)
		return ok and k or nil
	end
	return v
end
local function getConfig()
	local out = {theme = ThemeName, flags = {}}
	for name, f in pairs(Flags) do
		local ok, v = pcall(f.obj.Get)
		if ok and v ~= nil then out.flags[name] = ser(v) end
	end
	return out
end
local function setConfig(cfg)
	if type(cfg) ~= "table" then return false end
	if type(cfg.theme) == "string" and THEMES[cfg.theme] then setTheme(cfg.theme) end
	for name, raw in pairs(cfg.flags or {}) do
		local f = Flags[name]
		local v = de(raw)
		if f and v ~= nil then
			pcall(function()
				f.obj.Set(v)
				local o = f.opts
				if f.kind == "Keybind" then
					if o.OnChange then task.spawn(pcall, o.OnChange, v) end
				elseif f.kind ~= "Toggle" and o.Callback then
					task.spawn(pcall, o.Callback, f.obj.Get())
				end
			end)
		end
	end
	return true
end
local function exportConfig() return HttpService:JSONEncode(getConfig()) end
local function importConfig(str)
	local ok, data = pcall(HttpService.JSONDecode, HttpService, tostring(str))
	return ok and setConfig(data) or false
end

do
	local st = Pages.Settings
	local ap = st.Left:Group("Appearance", "palette")
	ap:ThemePicker()
	ap:Slider{Name = "Transparency", Help = "ความโปร่งของพื้นหลัง การ์ด และปุ่ม", Min = 0, Max = 80, Step = 5, Default = math.floor(Glass * 100 + 0.5), Suffix = "%", Flag = "ui_transparency",
		Callback = function(v) setGlass(v / 100) end}
	ap:Toggle{Name = "Snowfall", Flag = "ui_snow", Help = "หิมะตกช้าๆ (เฉพาะธีม Winter)", Default = true, Callback = function(v) snowOn = v; fxUpdate() end}
	ap:Toggle{Name = "Frost effects", Flag = "ui_frost", Help = "แสงออโรร่าและขอบกระจก (เฉพาะธีม Winter)", Default = true, Callback = function(v) decoOn = v; fxUpdate() end}
	ap:Toggle{Name = "Window glow", Flag = "ui_glow", Default = true, Callback = function(v) glowOn = v; ringsVisible(true) end}

	local win = st.Right:Group("Window", "sliders-horizontal")
	win:Slider{Name = "UI Scale", Min = 0.6, Max = 1.5, Step = 0.05, Default = math.floor(Scale.Scale * 20 + 0.5) / 20,
		Callback = function(v) CFG.AutoScale = false; Scale.Scale = v end}
	win:Keybind{Name = "Toggle key", Help = "ปุ่มซ่อน/แสดงหน้าต่าง", Default = CFG.ToggleKey, OnChange = function(k) if k then CFG.ToggleKey = k end end}
	win:ButtonRow{
		{Name = "Reset position", Icon = "rotate-ccw", Callback = function() Root.Position = UDim2.fromScale(0.5, 0.5) end},
		{Name = "Unload", Icon = "power", Style = "danger", Callback = function() Gui:Destroy() end},
	}

	local cf = st.Left:Group("Config", "book-open")
	local cfgBox = cf:Input{Name = "Config", Placeholder = "Export แล้ววางที่นี่"}
	cf:ButtonRow{
		{Name = "Export", Icon = "check", Callback = function() cfgBox.Set(exportConfig()) end},
		{Name = "Import", Icon = "refresh-cw", Callback = function()
			notify{Title = "Config", Content = importConfig(cfgBox.Get()) and "โหลดค่าสำเร็จ" or "ข้อมูล Config ไม่ถูกต้อง"}
		end},
	}
end
fxUpdate()
select_("Home")

----------------------------------------------------------------
-- LIVE DATA
----------------------------------------------------------------
local function setStat(key, text)
	local s = StatLabels[key]
	if not s then return end
	s.label.Text = tostring(text)
	s.place()
end
local t0 = os.clock()
task.spawn(function()
	while Gui.Parent do
		local sec = math.floor(os.clock() - t0)
		setStat("Session", string.format("%02d:%02d:%02d", sec // 3600, (sec // 60) % 60, sec % 60))
		task.wait(1)
	end
end)
task.spawn(function()
	while Gui.Parent do
		local ok, ping = pcall(function() return game:GetService("Stats").Network.ServerStatsItem["Data Ping"]:GetValue() end)
		if ok and ping then
			ping = math.floor(ping + 0.5)
			local col = ping < 80 and C.ok or (ping < 160 and C.warn or C.bad)
			local s = StatLabels.Ping
			s.label.Text = tostring(ping); s.label.TextColor3 = col; s.dot.BackgroundColor3 = col
		end
		task.wait(1)
	end
end)

----------------------------------------------------------------
-- MINIMIZE PILL / FOLD (กระดาษหุบ) / SHADE / CLOSE
----------------------------------------------------------------
local Pill = new("TextButton", {
	Size = UDim2.new(0, 0, 0, 26), AutomaticSize = Enum.AutomaticSize.X, AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 8),
	Bg = "top", BackgroundTransparency = 0.4, Text = "", AutoButtonColor = false, BorderSizePixel = 0, Visible = false, Parent = Gui,
}, {
	round("full"), stroke("cardLine", 1),
	new("UIPadding", {PaddingLeft = UDim.new(0, 12), PaddingRight = UDim.new(0, 14)}),
	new("UIListLayout", {FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 7), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder}),
})
local PillLabel
do
	new("Frame", {LayoutOrder = 1, Size = UDim2.fromOffset(7, 7), Bg = "accent", BorderSizePixel = 0, Parent = Pill}, {round("full")})
	PillLabel = new("TextLabel", {
		LayoutOrder = 2, Size = UDim2.new(0, 0, 1, 0), AutomaticSize = Enum.AutomaticSize.X, BackgroundTransparency = 1, Text = CFG.Brand,
		FontFace = sans(W_.SemiBold), TextSize = 12, Tx = "text", TextTransparency = 0.25, Parent = Pill,
	})
	Pill.MouseEnter:Connect(function() tween(Pill, 0.15, {BackgroundTransparency = 0.05}); tween(PillLabel, 0.15, {TextTransparency = 0}) end)
	Pill.MouseLeave:Connect(function() tween(Pill, 0.15, {BackgroundTransparency = 0.4}); tween(PillLabel, 0.15, {TextTransparency = 0.25}) end)
end
local function pillShow(v)
	if v then
		Pill.Visible = true
		Pill.BackgroundTransparency = 1
		PillLabel.TextTransparency = 1
		Pill.Position = UDim2.new(0.5, 0, 0, -6)
		tweenE(Pill, 0.35, {BackgroundTransparency = 0.4, Position = UDim2.new(0.5, 0, 0, 8)}, Enum.EasingStyle.Quint)
		tween(PillLabel, 0.35, {TextTransparency = 0.25})
	else
		Pill.Visible = false
	end
end

local shaded = false
local SHADE_OFF = (L.H - L.TOP) / 2
local function setShade(v, instant)
	if shaded == v then return end
	shaded = v
	closeModal(true)
	TopFill.Visible = not v
	ringsVisible(not v)
	local gm = {Size = v and UDim2.new(1, 0, 0, L.TOP) or UDim2.fromScale(1, 1), Position = UDim2.new(0.5, 0, 0.5, v and -SHADE_OFF or 0)}
	local gi = {Position = UDim2.new(0.5, 0, 0.5, v and SHADE_OFF or 0)}
	if instant then
		for k, val in pairs(gm) do Main[k] = val end
		for k, val in pairs(gi) do Inner[k] = val end
	else
		tweenE(Main, 0.4, gm, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
		tweenE(Inner, 0.4, gi, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut)
	end
end

local folding = false
local function foldClose(toPill)
	if folding or not Root.Visible then return end
	folding = true
	closeModal(true); hideTip()
	if shaded then setShade(false, true) end
	ringsVisible(false)
	local t1 = TweenService:Create(Main, TweenInfo.new(0.36, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut), {Size = UDim2.new(1, 0, 0, 2)})
	t1:Play(); t1.Completed:Wait()
	local t2 = TweenService:Create(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 2)})
	t2:Play(); t2.Completed:Wait()
	Root.Visible = false
	if toPill then pillShow(true) end
	folding = false
end
local function foldOpen()
	if folding or Root.Visible then return end
	folding = true
	pillShow(false)
	Main.Size = UDim2.new(0, 0, 0, 2)
	Root.Visible = true
	local t1 = TweenService:Create(Main, TweenInfo.new(0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = UDim2.new(1, 0, 0, 2)})
	t1:Play(); t1.Completed:Wait()
	local t2 = TweenService:Create(Main, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {Size = UDim2.fromScale(1, 1)})
	t2:Play(); t2.Completed:Wait()
	ringsVisible(true)
	folding = false
end
Pill.MouseButton1Click:Connect(function() task.spawn(foldOpen) end)

BtnRed.MouseButton1Click:Connect(function()
	task.spawn(function() foldClose(false); Gui:Destroy() end)
end)
BtnAmber.MouseButton1Click:Connect(function() task.spawn(foldClose, true) end)
BtnGreen.MouseButton1Click:Connect(function() setShade(not shaded) end)
BtnGear.MouseButton1Click:Connect(function() select_("Settings") end)

bind(UIS.InputBegan, function(i, gp)
	if gp or Listening or i.UserInputType ~= Enum.UserInputType.Keyboard or i.KeyCode ~= CFG.ToggleKey then return end
	if Root.Visible then task.spawn(foldClose, false) else task.spawn(foldOpen) end
end)

do
	local dragging, start, startPos
	bind(Top.InputBegan, function(i)
		if not isPress(i) then return end
		if SearchBox.Visible then
			local p, s = SearchBox.AbsolutePosition, SearchBox.AbsoluteSize
			if i.Position.X >= p.X and i.Position.X <= p.X + s.X and i.Position.Y >= p.Y and i.Position.Y <= p.Y + s.Y then return end
		end
		dragging, start, startPos = true, i.Position, Root.Position
	end)
	bind(UIS.InputEnded, function(i) if isPress(i) then dragging = false end end)
	bind(UIS.InputChanged, function(i)
		if dragging and isMove(i) then
			local d = i.Position - start
			Root.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
end

new("Frame", {Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, ZIndex = 100, Parent = Main}, {round(L.R_WIN), stroke("border", 1)})

-- เปิดตัวแบบนุ่มๆ: หน้าต่างกางออกจากกึ่งกลาง
task.spawn(function()
	Root.Visible = false
	task.wait(0.05)
	foldOpen()
end)

----------------------------------------------------------------
-- PUBLIC API
----------------------------------------------------------------
return {
	Gui = Gui, Root = Root, Tabs = Pages, Colors = C, Icons = LUCIDE, Themes = THEMES, Config = CFG,
	Select = select_, SetStat = setStat, AddTab = addTab, SetTheme = setTheme, SetGlass = setGlass, Notify = notify,
	Hide = function() task.spawn(foldClose, false) end, Show = function() task.spawn(foldOpen) end,
	Flags = Flags, GetConfig = getConfig, SetConfig = setConfig, ExportConfig = exportConfig, ImportConfig = importConfig,
	SetScale = function(s) CFG.AutoScale = false; Scale.Scale = s end,
	Destroy = function() Gui:Destroy() end,
}
