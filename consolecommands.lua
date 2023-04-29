

local function Spawn(prefab)
    --TheSim:LoadPrefabs({prefab})
    return SpawnPrefab(prefab)
end

function ConsoleWorldEntityUnderMouse()
    if TheInput.overridepos == nil then
        return TheInput:GetWorldEntityUnderMouse()
    else
        local x, y, z = TheInput.overridepos:Get()
        local ents = TheSim:FindEntities(x, y, z, 1)
        for i, v in ipairs(ents) do
            if v.entity:IsVisible() then
                return v
            end
        end
    end
end

function ConsoleWorldPosition()
    return TheInput.overridepos or TheInput:GetWorldPosition()
end

---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------
-- Console Functions -- These are simple helpers made to be typed at the console.
---------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------


function c_repeatlastcommand()
    local history = GetConsoleHistory()
    if #history > 0 then
        if history[#history] == "c_repeatlastcommand()" then
            -- top command is this one, so we want the second last command
            history[#history] = nil
        end
        ExecuteConsoleCommand(history[#history])
    end
end

-- Spawn At Cursor and select the new ent
-- Has a gimpy short name so it's easier to type from the console
function c_spawn(prefab, count)
    count = count or 1
    local inst = nil
    for i=1,count do
        inst = DebugSpawn(prefab)
        inst.Transform:SetPosition(TheInput:GetWorldPosition():Get())
    end
    SetDebugEntity(inst)
    SuUsed("c_spawn_" .. prefab , true)
    return inst
end

-- Get the currently selected entity, so it can be modified etc.
-- Has a gimpy short name so it's easier to type from the console
function c_sel()
    return GetDebugEntity()
end

function c_select(inst, noselect)
    if not inst then
        inst = ConsoleWorldEntityUnderMouse()
    end
    
    if not noselect then
        print("Selected "..tostring(inst or "<nil>") )
        SetDebugEntity(inst)
    end

    return inst
end

-- Print the (visual) tile under the cursor
function c_tile()
    local s = ""

    local ground = GetWorld()
    local mx, my, mz = TheInput:GetWorldPosition():Get()
    local tx, ty = ground.Map:GetTileCoordsAtPoint(mx,my,mz)
    s = s..string.format("\nWorld Pos: (%f, %f, %f])\nTile Coords: (%d, %d)\n", mx,my,mz, tx,ty)

    local tile = ground.Map:GetTileAtPoint(TheInput:GetWorldPosition():Get())
    for k,v in pairs(GROUND) do
        if v == tile then
            s = s..string.format("Tile Type: %s\n", k)
            break
        end
    end
    
    print(s)
end

-- Apply a scenario script to the selection and run it.
function c_doscenario(scenario)
    local inst = GetDebugEntity()
    if not inst then
        print("Need to select an entity to apply the scenario to.")
        return
    end
    if inst.components.scenariorunner then
        inst.components.scenariorunner:ClearScenario()
    end

    -- force reload the script -- this is for testing after all!
    package.loaded["scenarios/"..scenario] = nil

    inst:AddComponent("scenariorunner")
    inst.components.scenariorunner:SetScript(scenario)
    inst.components.scenariorunner:Run()
    SuUsed("c_doscenario_"..scenario, true)
end


-- Some helper shortcut functions
function c_season() return GetWorld().components.seasonmanager end

function c_sel_health()
    if c_sel() then
        local health = c_sel().components.health
        if health then
            return health
        else
            print("Gah! Selection doesn't have a health component!")
            return
        end
    else
        print("Gah! Need to select something to access it's components!")
    end
end

function c_sethealth(n)
    SuUsed("c_sethealth", true)
    GetPlayer().components.health:SetPercent(n)
end

function c_setminhealth(n)
    SuUsed("c_minhealth", true)
    GetPlayer().components.health:SetMinHealth(n)
end

function c_setsanity(n)
    SuUsed("c_setsanity", true)
    GetPlayer().components.sanity:SetPercent(n)
end

function c_sethunger(n)
    SuUsed("c_sethunger", true)
    GetPlayer().components.hunger:SetPercent(n)
end

function c_setmoisture(n)
    SuUsed("c_setmoisture", true)
    local wet = GetPlayer().components.moisture
    if wet then wet:SetMoistureLevel(n) end
end

-- Put an item(s) in the player's inventory
function c_give(prefab, count)
    count = count or 1

    local MainCharacter = GetPlayer()
    
    if MainCharacter then
        for i=1,count do
            local inst = Spawn(prefab)
            if inst then
                MainCharacter.components.inventory:GiveItem(inst)
                SuUsed("c_give_" .. inst.prefab)
            end
        end
    end
end

function c_mat(recname)
    local player = GetPlayer()
    local recipe = GetRecipe(recname)
    if player.components.inventory and recipe then
      for ik, iv in pairs(recipe.ingredients) do
            for i = 1, iv.amount do
                local item = SpawnPrefab(iv.type)
                player.components.inventory:GiveItem(item)
                SuUsed("c_mat_" .. iv.type , true)
            end
        end
    end
end

c_mats, c_material, c_materials = c_mat, c_mat, c_mat

function c_pos(inst)
    return inst and Point(inst.Transform:GetWorldPosition())
end

function c_printpos(inst)
    print(c_pos(inst))
end

function c_teleport(x, y, z, inst)
    inst = inst or GetPlayer()
    inst.Transform:SetPosition(x, y, z)
    SuUsed("c_teleport", true)
end

function c_move(inst)
    inst = inst or c_sel()
    inst.Transform:SetPosition(TheInput:GetWorldPosition():Get())
    SuUsed("c_move", true)
end

function c_goto(dest, inst)
    inst = inst or GetPlayer()
    inst.Transform:SetPosition(dest.Transform:GetWorldPosition())
    TheCamera:Snap()
    SuUsed("c_goto", true)
end

function c_inst(guid)
    return Ents[guid]
end

function c_list(prefab)
    local x,y,z = GetPlayer().Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 9001)
    for k,v in pairs(ents) do
        if v.prefab == prefab then
            print(string.format("%s {%2.2f, %2.2f, %2.2f}", tostring(v), v.Transform:GetWorldPosition()))
        end
    end
end

function c_listtag(tag)
    local tags = {tag}
    local x,y,z = GetPlayer().Transform:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, 9001, tags)
    for k,v in pairs(ents) do
        print(string.format("%s {%2.2f, %2.2f, %2.2f}", tostring(v), v.Transform:GetWorldPosition()))
    end
end

local lastfound = -1
function c_findnext(prefab, radius, inst)
    inst = inst or GetPlayer()
    radius = radius or 9001

    local trans = inst.Transform
    local found = nil
    local foundlowestid = nil
    local reallowest = nil
    local reallowestid = nil

    print("Finding a ",prefab)

    local x,y,z = trans:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, radius)
    for k,v in pairs(ents) do
        if v ~= inst and v.prefab == prefab then
            print(v.GUID,lastfound,foundlowestid )
            if v.GUID > lastfound and (foundlowestid == nil or v.GUID < foundlowestid) then
                found = v
                foundlowestid = v.GUID
            end
            if not reallowestid or v.GUID < reallowestid then
                reallowest = v
                reallowestid = v.GUID
            end
        end
    end
    if not found then
        found = reallowest
    end
    lastfound = found.GUID
    return found
end

local godmode = false
function c_godmode()
    if GetPlayer() then
        godmode = not godmode
        GetPlayer().components.health:SetInvincible(godmode)
        SuUsed("c_godmode", true)
        print("God mode: ",godmode) 
    end
end

function c_find(prefab, radius, inst)
    inst = inst or GetPlayer()
    radius = radius or 9001

    local trans = inst.Transform
    local found = nil
    local founddistsq = nil

    local x,y,z = trans:GetWorldPosition()
    local ents = TheSim:FindEntities(x,y,z, radius)
    for k,v in pairs(ents) do
        if v ~= inst and v.prefab == prefab then
            if not founddistsq or inst:GetDistanceSqToInst(v) < founddistsq then 
                found = v
                founddistsq = inst:GetDistanceSqToInst(v)
            end
        end
    end
    return found
end

function c_findtag(tag, radius, inst)
    return GetClosestInstWithTag(tag, inst or GetPlayer(), radius or 1000)
end

function c_gonext(name)
    c_goto(c_findnext(name))
end

function c_printtextureinfo( filename )
    TheSim:PrintTextureInfo( filename )
end

function c_simphase(phase)
    GetWorld():PushEvent("phasechange", {newphase = phase})
end

function c_anim(animname, loop)
    if GetDebugEntity() then
        GetDebugEntity().AnimState:PlayAnimation(animname, loop or false)
    else
        print("No DebugEntity selected")
    end
end

function c_light(c1, c2, c3)
    TheSim:SetAmbientColour(c1, c2 or c1, c3 or c1)
end

function c_spawn_ds(prefab, scenario)
    local inst = c_spawn(prefab)
    if not inst then
        print("Need to select an entity to apply the scenario to.")
        return
    end

    if inst.components.scenariorunner then
        inst.components.scenariorunner:ClearScenario()
    end

    -- force reload the script -- this is for testing after all!
    package.loaded["scenarios/"..scenario] = nil

    inst:AddComponent("scenariorunner")
    inst.components.scenariorunner:SetScript(scenario)
    inst.components.scenariorunner:Run()
end


function c_countprefabs(prefab, noprint)
    local count = 0
    for k,v in pairs(Ents) do
        if v.prefab == prefab then
            count = count + 1
        end
    end
    if not noprint then
        print("There are ", count, prefab.."s in the world.")
    end
    return count
end

function c_countallprefabs()
    local counted = {}
    for k,v in pairs(Ents) do
        if v.prefab and not table.findfield(counted, v.prefab) then 
            local num = c_countprefabs(v.prefab, true)
            counted[v.prefab] = num
        end
    end

    local function pairsByKeys (t, f)
      local a = {}
      for n in pairs(t) do table.insert(a, n) end
      table.sort(a, f)
      local i = 0      -- iterator variable
      local iter = function ()   -- iterator function
        i = i + 1
        if a[i] == nil then return nil
        else return a[i], t[a[i]]
        end
      end
      return iter
    end

    for k,v in pairsByKeys(counted) do
        print(k, v)
    end

    print("There are ", GetTableSize(counted), " different prefabs in the world.")
end

function c_speed(speed)
    GetPlayer().components.locomotor.bonusspeed = speed
end

function c_forcecrash(unique)
    local path = "a"
    if unique then
        path = string.random(10, "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUV")
    end

    if GetWorld() then
        GetWorld():DoTaskInTime(0,function() _G[path].b = 0 end)
    elseif TheFrontEnd then
        TheFrontEnd.screenroot.inst:DoTaskInTime(0,function() _G[path].b = 0 end)
    end
end

function c_testruins()
    GetPlayer().components.builder:UnlockRecipesForTech({SCIENCE = 2, MAGIC = 2})
    c_give("log", 20)
    c_give("flint", 20)
    c_give("twigs", 20)
    c_give("cutgrass", 20)
    c_give("lightbulb", 5)
    c_give("healingsalve", 5)
    c_give("batbat")
    c_give("icestaff")
    c_give("firestaff")
    c_give("tentaclespike")
    c_give("slurtlehat")
    c_give("armorwood")
    c_give("minerhat")
    c_give("lantern")
    c_give("backpack")
end


function c_teststate(state)
    c_sel().sg:GoToState(state)
end

function c_sounddebug ( filter )
    if not package.loaded["debugsounds"] then
        require "debugsounds"
    end

    SOUNDDEBUG_ENABLED = true
    TheSim:SetDebugRenderEnabled(true)

    SetSoundDebug()

    if filter then
        SetEventSoundFilter(filter)
    end
end

-- CS stands for sounddebug
function cs_on(filter)
    c_sounddebug(filter)
end

function cs_off()
    SOUNDDEBUG_ENABLED = false
    ResetSoundDebug()
end

function cs_toggle()
    if SOUNDDEBUG_ENABLED then
        cs_off()
    else
        cs_on()
    end
end

function cs_prefab ( prefab )
    SetPrefabSoundFilter( prefab )
end

function cs_filter (filter)
    SetEventSoundFilter( filter )
end

function cs_entity (guid)
    SetEntitySoundFilter(guid)
end

function cs_sel()
    if c_sel() then
        cs_entity(c_sel().entity:GetGUID())
    end
end

-- Nuke any controller mappings, for when people get in a hairy situation with a controller mapping that is totally busted.
function ResetControllersAndQuitGame()
    print("ResetControllersAndQuitGame requested")
    if not InGamePlay() then
    -- Nuke any controller configurations from our profile
    -- and clear the setting in the ini file
    TheSim:SetSetting("misc", "controller_popup", tostring(nil))
    Profile:SetValue("controller_popup",nil)
    Profile:SetValue("controls",{})
    Profile:Save()
    -- And quit the game, we want a restart
    RequestShutdown()	
    else
    print("ResetControllersAndQuitGame can only be called from the frontend")
    end
end

-- Removes all PREFAB from the world.
-- prefab (string): prefab name
function c_removeall(prefab)
    local count = 0
    for _, ent in pairs(Ents) do
        if ent.prefab and ent.prefab == prefab then
            ent:Remove()
            count = count + 1
        end
    end
    print(count, " entities removed.")
end

function c_revealmap()
    GetWorld().minimap.MiniMap:ShowArea(0,0,0,10000)
end

-- Spawns the PREFAB on a RADIUS radius circle around the cursor.
-- prefab (string): prefab name
-- radius (number): circle radius
-- itemdensity (number): item density
function c_circle(prefab, radius, itemdensity)
    local pt = ConsoleWorldPosition()
    local theta = math.random() * 2 * math.pi
    local itemdensity = itemdensity or 0.5 --(X items per unit)
    
    local circ = 2*math.pi*radius
    local numitems = circ * itemdensity

    for i = 1, numitems do
        local offset = Vector3(radius * math.cos( theta ), 0, -radius * math.sin( theta ))
        local wander_point = pt + offset
        local spawn = SpawnPrefab(prefab or "blueprint")
        spawn.Transform:SetPosition( wander_point.x, wander_point.y, wander_point.z )    
        theta = theta - (2 * math.pi / numitems)
    end
end

-- Skips NUM days.
function c_skip(num)
    num = num or 1
    LongUpdate(TUNING.TOTAL_DAY_TIME * num)
end

function c_supergodmode()
    local components = GetPlayer().components
    
    c_sethunger(1)
    c_sethealth(1)
    c_setsanity(1)
    c_setmoisture(0)

    components.temperature:SetTemperature(25)
    
    c_godmode()
end

-- Save the game.
function c_save()
    if not GetPlayer() then return end
    GetPlayer().components.autosaver:DoSave()
end

-- Regenerates the current world.
function c_regeneratecurrentworld()
    if not GetPlayer() then return end

    GetPlayer().profile:Save(function()
        SaveGameIndex:EraseCurrent(function() 
            scheduler:ExecuteInTime(0.1, function()
                local function OnProfileSaved()
                    TheFrontEnd:Fade(false, 0.5, function () 
                        StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = SaveGameIndex:GetCurrentSaveSlot()})
                    end )
                end
                
                -- Record the start of a new game
                Profile:Save(OnProfileSaved)
            end)
        end, false)
    end)
end

-- Regenerates all worlds in the saveslot.
function c_regenerateallworlds()
    if not GetPlayer() then return end

    GetPlayer().profile:Save(function()
        SaveGameIndex:EraseCurrent(function() 
            scheduler:ExecuteInTime(0.1, function()
                local function OnProfileSaved()
                    local slot = SaveGameIndex:GetCurrentSaveSlot()
                    SaveGameIndex:DeleteSlot(slot, function() 
                        TheFrontEnd:Fade(false, 0.5, function () 
                            StartNextInstance({reset_action=RESET_ACTION.LOAD_SLOT, save_slot = slot or SaveGameIndex:GetCurrentSaveSlot()})
                        end )
                    end, true)
                end
                
                -- Record the start of a new game
                Profile:Save(OnProfileSaved)
            end)
        end)
    end)
end

function c_regeneratecave()
    local entrance = c_select(nil, true)
    
    if not (entrance and entrance.cavenum ~= nil) then print(">> You need to hover the cave entrance.") return end

    local num = entrance.cavenum

    SaveGameIndex:ResetCave(num)
end

-- Rollback to the last save / reloads frontend
function c_reset()
    TheFrontEnd:HideConsoleLog()
    TheSim:SetDebugRenderEnabled(false)

    -- Not in game.
    if not GetPlayer() then
        TheFrontEnd:Fade(false, 1, function()
            EnableAllDLC()
            StartNextInstance()
        end)
    end

    GetPlayer().HUD:Hide()

    TheFrontEnd:Fade(false, 1, function()
        StartNextInstance(
            {
                reset_action=RESET_ACTION.LOAD_SLOT,
                save_slot = SaveGameIndex:GetCurrentSaveSlot()
            },
            true
        )
    end)
end

function c_reload()
    c_save()
    GetPlayer():DoTaskInTime(3, c_reset)
end

function c_freecrafting()
    GetPlayer().components.builder:GiveAllRecipes()
end

function c_domesticatedbeefalo(tendency)
    tendency = tendency or TENDENCY.RIDER

    local saddle = c_spawn("saddle_race")
    local beef = c_spawn("beefalo")

    beef.components.hunger:DoDelta(400);
    beef.components.domesticatable:DeltaTendency(tendency, 1)
    beef:SetTendency()

    beef.components.domesticatable.domestication = 1
    beef.components.domesticatable:BecomeDomesticated()

    beef.components.rideable:SetSaddleable(true)
    beef.components.rideable:SetSaddle(GetPlayer(), saddle)
end

function c_swapcharacter(character, no_reload)
    if table.contains(GetActiveCharacterList(), character) then
        GetPlayer().prefab = character

        if not no_reload then
            c_reload()
        end
    else
        nolineprint(string.format('>> Character "%s" isn\'t valid...', character))
    end
end

function c_testteleportato()
    local current_mode = SaveGameIndex.data.slots[SaveGameIndex.current_slot].current_mode

    local base
    if current_mode == "adventure" then 
        c_give("diviningrod")

        base = c_findnext("teleportato_base")
        c_goto(base)
    else
        base = c_spawn("teleportato_base")
    end

    base:OnLoad({makecomplete=1})
end