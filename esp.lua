-- Улучшенный и стабильный Highlight ESP (LocalScript)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

-- Ждём, пока игра и LocalPlayer загрузятся
if not game:IsLoaded() then
    game.Loaded:Wait()
end
local LocalPlayer = Players.LocalPlayer
while not LocalPlayer do
    task.wait()
    LocalPlayer = Players.LocalPlayer
end

-- Утилитарная функция безопасного ожидания
local function safeWaitForChild(parent, name, timeout)
    if not parent then return nil end
    local ok, result = pcall(function()
        return parent:WaitForChild(name, timeout)
    end)
    if ok then
        return result
    end
    return nil
end

local trackers = {} -- player -> { charConn = Disconnectable, cleanup = function() }

local function removeHighlightFromCharacter(character)
    if not character then return end
    for _, v in ipairs(character:GetChildren()) do
        if v:IsA("Highlight") then
            v:Destroy()
        end
    end
end

local function createHighlight(character)
    if not character or not character.Parent then return end
    -- Ждём HRP, но безопасно
    local hrp = character:FindFirstChild("HumanoidRootPart") or safeWaitForChild(character, "HumanoidRootPart", 5)
    if not hrp then return end

    -- Удалим старые, если есть
    removeHighlightFromCharacter(character)

    local highlight = Instance.new("Highlight")
    highlight.Name = "ESP_Highlight"
    highlight.Parent = character
    highlight.FillColor = Color3.fromRGB(255, 0, 0)
    highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
end

local function onCharacterAdded(player, character)
    -- небольшая задержка, чтобы модель успела инициализироваться
    task.wait(0.05)
    -- защита pcall на случай, если что-то внутри character сломано
    local ok = pcall(function()
        createHighlight(character)
    end)
    if not ok then
        -- ничего критичного — просто пропускаем
    end
end

local function trackPlayer(player)
    if not player or player == LocalPlayer then return end

    -- очистка предыдущих подписок (если были)
    if trackers[player] and trackers[player].charConn then
        trackers[player].charConn:Disconnect()
        trackers[player] = nil
    end

    -- если персонаж уже есть — применим сразу
    if player.Character then
        -- pcall на всякий случай
        pcall(function() createHighlight(player.Character) end)
    end

    -- подписываемся на CharacterAdded
    local charConn = player.CharacterAdded:Connect(function(character)
        onCharacterAdded(player, character)
    end)

    -- подписываемся на удаление игрока, чтобы очистить ресурсы
    local function cleanup()
        if trackers[player] then
            if trackers[player].charConn then
                trackers[player].charConn:Disconnect()
            end
            trackers[player] = nil
        end
    end

    trackers[player] = { charConn = charConn, cleanup = cleanup }
end

-- Очистка при уходе игрока
Players.PlayerRemoving:Connect(function(player)
    if trackers[player] and trackers[player].cleanup then
        trackers[player].cleanup()
    end
end)

-- Инициализация для уже подключенных игроков
for _, p in ipairs(Players:GetPlayers()) do
    trackPlayer(p)
end

-- Подключаем новых игроков
Players.PlayerAdded:Connect(function(p)
    trackPlayer(p)
end)

print("[✔] ESP: исправленный и стабильный скрипт запущен")
