local Players = game:GetService("Players")
return function()
    repeat
        task.wait()
    until #Players:GetPlayers() >= 1

    return true
end
