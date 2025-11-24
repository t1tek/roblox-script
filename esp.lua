-- Улучшенный и стабильный Highlight ESP + HP Bar (LocalScript)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Ждём загрузку
if not game:IsLoaded() then game.Loaded:Wait() end
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do task.wait() LocalPlayer = Players.LocalPlayer end

-- Безопасный WaitForChild
local function safeWaitForChild(parent, name, timeout)
    if not parent then return nil end
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout)
    end)
    return ok and result or nil
end

local trackers = {}

---------------------------------------------------------------------
-- УДАЛЕНИЕ СТАРЫХ ХАЙЛАЙТОВ
---------------------------------------------------------------------
local function removeHighlightFromCharacter(character)
    if not character then return end
    for _, v in ipairs(character:GetChildren()) do
        if v:IsA("Highlight") then v:Destroy() end
    end
end

---------------------------------------------------------------------
-- ✨ СОЗДАНИЕ СВЕЧЕНИЯ
---------------------------------------------------------------------
local function createHighlight(character)
    if not character or not character.Parent then return end
    local hrp = character:FindFirstChild("HumanoidRootPart") or safeWaitForChild(character, "HumanoidRootPart", 5)
    if not hrp then return end

    removeHighlightFromCharacter(character)

    local h = Instance.new("Highlight")
    h.Name = "ESP_Highlight"
    h.Parent = character
    h.FillColor = Color3.fromRGB(255, 0, 0)
    h.OutlineColor = Color3.fromRGB(255, 255, 255)
    h.FillTransparency = 0.5
    h.OutlineTransparency = 0
end

---------------------------------------------------------------------
-- ❤️ СОЗДАНИЕ HP-БАРА
---------------------------------------------------------------------
local function createHPBar(character)
    local head = character:FindFirstChild("Head")
    local humanoid = character:FindFirstChild("Humanoid")

    if not head or not humanoid then return end

    -- Удаляем старый HP-бар, если есть
    local old = head:FindFirstChild("HP_UI")
    if old then old:Destroy() end

    -- Billboard GUI
    local bill = Instance.new("BillboardGui")
    bill.Name = "HP_UI"
    bill.Parent = head
    bill.Adornee = head
    bill.AlwaysOnTop = true
    bill.Size = UDim2.new(4, 0, 1.2, 0)
    bill.StudsOffset = Vector3.new(-3, 0.5, 0)

    local bg = Instance.new("Frame")
    bg.Parent = bill
    bg.Size = UDim2.new(1, 0, 0.2, 0)
    bg.Position = UDim2.new(0, 0, 0.4, 0)
    bg.BackgroundColor3 = Color3.fromRGB(0, 0, 0)

    local fill = Instance.new("Frame")
    fill.Parent = bg
    fill.Size = UDim2.new(1, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)

    local function updateHP()
        local ratio = humanoid.Health / humanoid.MaxHealth
        fill.Size = UDim2.new(math.clamp(ratio, 0, 1), 0, 1, 0)
        if ratio < 0.3 then
            fill.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
        elseif ratio < 0.6 then
            fill.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
        else
            fill.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
        end
    end

    humanoid.HealthChanged:Connect(updateHP)
    updateHP()
end

---------------------------------------------------------------------
-- СОБЫТИЕ ДЛЯ НОВОГО ПЕРСОНАЖА
---------------------------------------------------------------------
local function onCharacterAdded(player, character)
    task.wait(0.05)
    pcall(function()
        createHighlight(character)
        createHPBar(character)
    end)
end

---------------------------------------------------------------------
-- ОТСЛЕЖИВАНИЕ ИГРОКА
---------------------------------------------------------------------
local function trackPlayer(player)
    if not player or player == LocalPlayer then return end

    if trackers[player] and trackers[player].charConn then
        trackers[player].charConn:Disconnect()
        trackers[player] = nil
    end

    if player.Character then
        pcall(function()
            createHighlight(player.Character)
            createHPBar(player.Character)
        end)
    end

    local charConn = player.CharacterAdded:Connect(function(char)
        onCharacterAdded(player, char)
    end)

    trackers[player] = { charConn = charConn }
end

---------------------------------------------------------------------
-- УДАЛЕНИЕ ДАННЫХ ЕСЛИ ИГРОК ВЫШЕЛ
---------------------------------------------------------------------
Players.PlayerRemoving:Connect(function(player)
    if trackers[player] then
        if trackers[player].charConn then trackers[player].charConn:Disconnect() end
        trackers[player] = nil
    end
end)

---------------------------------------------------------------------
-- ИНИЦИАЛИЗАЦИЯ
---------------------------------------------------------------------
for _, p in ipairs(Players:GetPlayers()) do
    trackPlayer(p)
end

Players.PlayerAdded:Connect(trackPlayer)

---------------------------------------------------------------------
-- ОБНОВЛЕНИЕ ВСЕГО РАЗ В КАДР ДЛЯ ВСЕХ
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local head = player.Character:FindFirstChild("Head")
            local humanoid = player.Character:FindFirstChild("Humanoid")
            if head and humanoid then
                -- Проверка на наличие HP_UI и создание заново если пропал
                if not head:FindFirstChild("HP_UI") then
                    createHPBar(player.Character)
                end
            end
        end
    end
end)

print("[✔] ESP: свечение + HP бар теперь всегда видим и работает каждый раунд")
