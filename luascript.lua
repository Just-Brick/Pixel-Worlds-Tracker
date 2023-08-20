--Stuff You can change
autoTrack = false --Start Tracking automatically when attached
url = "" --paste your discord webhook here

--Global variables&pointer addresses
pnt_pdata = "GameAssembly.dll+026AA2A0"
pnt_world = "GameAssembly.dll+026AA230"

isTracking = false
hasVBS = false
playerName = "-"
worldName = "-"
---------------

function getAttachedProcessName()
    local m = enumModules();
    if (#m > 0) then
        return m[1].Name;
    end
    return nil;
end

function attach()
    OpenProcess("PixelWorlds.exe")
    local process = getAttachedProcessName()
    if process == "PixelWorlds.exe" then
        isAttached = true
        if autoTrack then
            startTracking()
        end
    else
        MessageDialog("PW not found", mtError, mbOK)
    end
end

function createAndSend(message)
    sdir = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Temp\\"
    sfile = sdir.."sender.bat"
    local file = assert(io.open(sfile, "w"))
    file:write("@echo off", "\n")
    file:write("set wk="..url, "\n")
    file:write("set message= " .. msg, "\n")
    file:write('curl -X POST -H "Content-type: application/json" --data "{\\"content\\": \\"%message%\\"}" %wk%', "\n")
    file:write("cls", "\n")
    file:close()
    shellExecute(vfile)
end

function updateUserInfo()
    if isAttached then
        playerName = readString("[[[GameAssembly.dll+026ED330]+B8]+98]+14", 128, true)
        worldName = readString("[[[[["..pnt_world.."]+B8]+38]+30]+D8]+14", 128, true)
    end
end


function startTracking()
    if url ~= "" and isAttached and isTracking == false then
        isTracking = true
        if hasVBS == false then
            --creating vbs script to hide console on sender run
		    vdir = os.getenv("USERPROFILE") .. "\\AppData\\Local\\Temp\\"
		    vfile = vdir.."runsender.vbs"
		    local file = assert(io.open(vfile, "w"))
		    file:write('Set WshShell = CreateObject("WScript.Shell") ', "\n")
		    file:write('WshShell.Run chr(34) & "%userprofile%\\AppData\\Local\\Temp\\sender.bat" & Chr(34), 0', "\n")
		    file:write("Set WshShell = Nothing", "\n")
		    file:close()
            hasVBS = true
        end
        updateUserInfo()
        prevName = playerName
        prevWorld = worldName
        msg = "^*^*:spy: TRACKING STARTED^*^*\\nPlayer: "..playerName..", Last seen at: "..worldName
        createAndSend(msg)
        updateTimer = createTimer(MainForm)
        updateTimer.Interval = 3000
        updateTimer.OnTimer = function()
        updateUserInfo()
            if prevName ~= playerName or prevWorld ~= worldName then
                msg = playerName.." just entered "..worldName
                createAndSend(msg)
                prevName = playerName
                prevWorld = worldName
            end
        end
    end
end
