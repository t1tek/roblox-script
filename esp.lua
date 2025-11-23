local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local function addESP(character)
    if not character then return end

    -- Ждём HumanoidRootPart, т.к. он может появиться позже
    local hrp = character:WaitForChild("HumanoidRootPart", 10)
    if not hrp then return end

    -- Удаляем старые хайлайты
    for _, v in ipairs(character:GetChildren()) do
        if v:IsA("Highlight") then
            v:Destroy()
        end
    end

    local highlight = Instance.new("Highlight")
    highlight.FillColor = Color3.new(1, 0, 0)
    highlight.OutlineColor = Color3.new(1, 1, 1)
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.Parent = character
end

local function trackPlayer(player)
    if player == LocalPlayer then return end

    -- Функция, которая будет постоянно мониторить Character
    task.spawn(function()
        while true do
            local character = player.Character
            if character then
                -- Проверяем: нет ли Highlight → создаём
                if not character:FindFirstChildOfClass("Highlight") then
                    addESP(character)
                end
            end
            task.wait(1) -- Проверяем каждые 1 секунду (можно 0.5)
        end
    end)
end

-- Подключаем всех игроков
for _, plr in pairs(Players:GetPlayers()) do
    trackPlayer(plr)
end

Players.PlayerAdded:Connect(trackPlayer)

print("[✔] ESP работает стабильно на всех раундах")
