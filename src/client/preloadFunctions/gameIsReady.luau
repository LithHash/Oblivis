return function()
    repeat
        task.wait()
    until game:IsLoaded() == true

    return true
end
