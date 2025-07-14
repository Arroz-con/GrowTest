local __DARKLUA_BUNDLE_MODULES

__DARKLUA_BUNDLE_MODULES = {
    cache = {},
    load = function(m)
        if not __DARKLUA_BUNDLE_MODULES.cache[m] then
            __DARKLUA_BUNDLE_MODULES.cache[m] = {
                c = __DARKLUA_BUNDLE_MODULES[m](),
            }
        end

        return __DARKLUA_BUNDLE_MODULES.cache[m].c
    end,
}

do
    function __DARKLUA_BUNDLE_MODULES.a()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local Utils = {}
        local localPlayer = Players.LocalPlayer
        local playerData = DataService:GetData()
        local printDebugMode = getgenv().DEBUG_MODE

        function Utils.GetCharacter()
            return localPlayer.Character or localPlayer.CharacterAdded:Wait()
        end
        function Utils.GetHumanoid()
            local humanoid = (Utils.GetCharacter():WaitForChild('Humanoid'))

            return humanoid
        end
        function Utils.GetHumanoidRootPart()
            local rootPart = (Utils.GetCharacter():WaitForChild('HumanoidRootPart'))

            return rootPart
        end
        function Utils.IsCharacterAtLocation(part, waitTime)
            local count = 0

            while true do
                local distance = (Utils.GetCharacter():GetPivot().Position - part.Position).Magnitude

                if distance <= 15 then
                    return true
                end
                if count >= waitTime then
                    return false
                end

                count = count + 1

                task.wait(1)
            end
        end
        function Utils.TeleportPlayerTo(teleportPart)
            if not Utils.IsCharacterAtLocation(teleportPart, 1) then
                Utils.GetCharacter():MoveTo(teleportPart.Position)

                if not Utils.IsCharacterAtLocation(teleportPart, 10) then
                    return false
                end
            end

            return true
        end
        function Utils.GetPlayerSheckles()
            return playerData.Sheckles
        end
        function Utils.FirstTimeUser()
            return playerData.FirstTimeUser
        end
        function Utils.PrintDebug(...)
            if not printDebugMode then
                return
            end

            print(string.format('[\u{1f41b} DEBUG] %s', tostring(...)))
        end
        function Utils.WaitForToolToEquip(timeout)
            local hasTool = Utils.GetCharacter():FindFirstChildWhichIsA('Tool')

            if hasTool then
                return true
            end

            local count = 0

            timeout = timeout or 1

            repeat
                task.wait(1)

                hasTool = Utils.GetCharacter():FindFirstChildWhichIsA('Tool')
                count = count + 1
            until hasTool or count > timeout

            if count > timeout then
                return false
            end

            return true
        end
        function Utils.FormatNumber(num)
            local absNum = math.abs(num)
            local sign = num < 0 and '-' or ''

            if absNum >= 1e9 then
                return string.format('%s%.2fB', sign, absNum / 1e9)
            elseif absNum >= 1e6 then
                return string.format('%s%.2fM', sign, absNum / 1e6)
            elseif absNum >= 1e3 then
                return string.format('%s%.1fK', sign, absNum / 1e3)
            else
                return string.format('%s%.0f', sign, absNum)
            end
        end
        function Utils.FormatTime(currentTime)
            local hours = math.floor(currentTime / 3600)
            local minutes = math.floor((currentTime % 3600) / 60)
            local seconds = currentTime % 60

            return string.format('%02d:%02d:%02d', hours, minutes, seconds)
        end

        return Utils
    end
    function __DARKLUA_BUNDLE_MODULES.b()
        local ReplicatedStorage = cloneref(game:GetService('ReplicatedStorage'))
        local Players = cloneref(game:GetService('Players'))
        local HttpService = cloneref(game:GetService('HttpService'))
        local PetRegistry = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('PetRegistry')))
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local WebHookHandler = {}

        WebHookHandler.UniqueString = ''

        local localPlayer = Players.LocalPlayer
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local vpsName = getgenv().WEBHOOK.VPS_NAME or 'None'
        local SELECTED_FARMING_PETS = getgenv().CONFIGS.SELECTED_FARMING_PETS
        local PETS_TO_KEEP = getgenv().CONFIGS.PETS_TO_KEEP
        local getThumbnailImage = function(rbxassetidLink)
            local assetid = rbxassetidLink:match('rbxassetid://(%d+)')

            if not assetid then
                return nil
            end

            local url = string.format(
[[https://thumbnails.roblox.com/v1/assets?assetIds=%s&size=420x420&format=png&isCircular=false]], tostring(assetid))
            local request = request or syn.request
            local headers = {
                ['Content-Type'] = 'application/json',
            }
            local requestOptions = {
                Url = url,
                Method = 'GET',
                Headers = headers,
            }
            local success, result = pcall(function()
                return request(requestOptions).Body
            end)

            if success then
                local data = HttpService:JSONDecode(result)

                if data and data.data and data.data[1] and data.data[1].imageUrl then
                    return data.data[1].imageUrl
                end
            end

            return nil
        end

        function WebHookHandler.SendWebHook(petName, petData, itemDataDB)
            local imageUrl = getThumbnailImage(itemDataDB.Icon)
            local embed = {
                title = string.format('NEW PET DETECTED!\n[%s] %s', tostring(vpsName), tostring(localPlayer.Name)),
                description = string.format('%s)', tostring(itemDataDB.Description)),
                color = 0xccff,
                fields = {
                    {
                        name = 'Pet Name',
                        value = petName,
                        inline = true,
                    },
                    {
                        name = 'Level',
                        value = tostring(petData.Level),
                        inline = true,
                    },
                    {
                        name = 'Rarity',
                        value = itemDataDB.Rarity,
                        inline = true,
                    },
                    {
                        name = 'Hatched From',
                        value = petData.HatchedFrom,
                        inline = true,
                    },
                    {
                        name = 'Sell Price',
                        value = tostring(itemDataDB.SellPrice),
                        inline = true,
                    },
                    {
                        name = 'BaseWeight',
                        value = tostring(petData.BaseWeight),
                        inline = true,
                    },
                },
                footer = {
                    text = string.format('\nShittyHub - %s', tostring(DateTime.now():FormatLocalTime('LLL', 'en-us'))),
                },
            }

            if imageUrl then
                embed.thumbnail = {url = imageUrl}
            end

            local dataFrame = {
                username = 'Pet Notifier',
                avatar_url = string.format(
[[https://www.roblox.com/headshot-thumbnail/image?userId=%s&width=420&height=420&format=png]], tostring(localPlayer.UserId)),
                embeds = {embed},
            }
            local request = request or syn.request
            local headers = {
                ['Content-Type'] = 'application/json',
            }
            local jsonData = HttpService:JSONEncode(dataFrame)
            local requestData = {
                Url = getgenv().WEBHOOK.URL,
                Method = 'POST',
                Headers = headers,
                Body = jsonData,
            }
            local success, result = pcall(function()
                return request(requestData)
            end)

            if success then
                Utils.PrintDebug(string.format('Request Succesful: %s', tostring(result)))
            else
                Utils.PrintDebug(string.format('Request Failed: %s', tostring(result)))
            end

            return nil
        end

        local getItemDefaultData = function(petName)
            return PetRegistry.PetList[petName] or nil
        end

        function WebHookHandler.Init()
            if not (getgenv().WEBHOOK and getgenv().WEBHOOK.URL) then
                Utils.PrintDebug('NO Webhook provided')
            end

            local webhookUrl = string.match(getgenv().WEBHOOK.URL, 'https://discord.com/api/webhooks/')

            if not webhookUrl then
                Utils.PrintDebug(
[[Webhook url not valid, needs format https://discord.com/api/webhooks/ect]])
            end

            gameEventsFolder.DataStream.OnClientEvent:Connect(function(
                eventType,
                profileName,
                updatedData
            )
                if eventType ~= 'UpdateData' then
                    return
                end
                if profileName ~= string.format('%s_DataServiceProfile', tostring(localPlayer.Name)) then
                    return
                end

                for _, entry in ipairs(updatedData)do
                    local path = entry[1]
                    local data = entry[2]

                    if typeof(data) == 'table' and string.find(path, 'PetInventory') then
                        if not (data.PetType and data.PetData) then
                            return
                        end
                        if table.find(SELECTED_FARMING_PETS, data.PetType) then
                            return
                        end
                        if not table.find(PETS_TO_KEEP, data.PetType) then
                            return
                        end

                        local itemDefaultData = getItemDefaultData(data.PetType)

                        if not itemDefaultData then
                            Utils.PrintDebug('itemDefaultData: Not able to get data!')

                            return
                        end

                        Utils.PrintDebug('Processing webhook data')
                        WebHookHandler.SendWebHook(data.PetType, data.PetData, itemDefaultData)
                    end
                end
            end)
        end

        return WebHookHandler
    end
    function __DARKLUA_BUNDLE_MODULES.c()
        local Workspace = game:GetService('Workspace')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local FarmPlotPath = {CachedPlots = {}}
        local getFarmPlotOwner = function(plot)
            local importantFolder = plot:WaitForChild('Important')
            local Owner = (importantFolder:WaitForChild('Data'):WaitForChild('Owner'))

            return Owner.Value
        end

        function FarmPlotPath.GetFarmPlotFor(player)
            if FarmPlotPath.CachedPlots[player.UserId] then
                return FarmPlotPath.CachedPlots[player.UserId]
            end

            local farmsFolder = Workspace:WaitForChild('Farm')

            for _, plot in farmsFolder:GetChildren()do
                if not plot:IsA('Folder') then
                    continue
                end

                local owner = getFarmPlotOwner(plot)

                if owner == player.Name then
                    FarmPlotPath.CachedPlots[player.UserId] = plot

                    return plot
                end
            end

            Utils.PrintDebug('Didnt find plot owner trying again')
            task.wait(10)

            return FarmPlotPath.GetFarmPlotFor(player)
        end

        return FarmPlotPath
    end
    function __DARKLUA_BUNDLE_MODULES.d()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local PetRegistry = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('PetRegistry')))
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('c')
        local Pets = {}
        local localPlayer = Players.LocalPlayer
        local backPack = localPlayer:WaitForChild('Backpack')
        local playerData = DataService:GetData()
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local myFarmPlot = FarmPlotPath.GetFarmPlotFor(localPlayer)
        local important = myFarmPlot:WaitForChild('Important')
        local objectsPhysical = important:WaitForChild('Objects_Physical')
        local BASE_WEIGHT = 7
        local unlockableSlots = {
            ['1'] = 20,
            ['2'] = 30,
            ['3'] = 45,
            ['4'] = 60,
            ['5'] = 75,
        }
        local Dinos = {
            'Raptor',
            'Triceratops',
            'Stegosaurus',
            'Pterodactyl',
            'Brontosaurus',
            'T-Rex',
        }

        function Pets.GiftPet(player)
            gameEventsFolder.PetGiftingService:FireServer('GivePet', player)
        end
        function Pets.SellPet(petModel)
            gameEventsFolder.SellPet_RE:FireServer(petModel)
        end
        function Pets.GetMaxEggsCanFarm()
            return playerData.PetsData.MutableStats.MaxEggsInFarm or 0
        end
        function Pets.GetMaxEquippedPets()
            return playerData.PetsData.MutableStats.MaxEquippedPets or 0
        end
        function Pets.GetMaxPetsInInventory()
            return playerData.PetsData.MutableStats.MaxPetsInInventory or 0
        end
        function Pets.GetPetDefaultHunger(petName)
            return PetRegistry.PetList[petName].DefaultHunger or 500
        end
        function Pets.GetAmountOfPetsInInventory()
            local count = 0

            for uuid, value in playerData.PetsData.PetInventory.Data do
                count = count + 1
            end

            return count
        end
        function Pets.IsMaxPetsInInventory()
            local maxPets = playerData.PetsData.MutableStats.MaxPetsInInventory
            local count = 0

            for uuid, value in playerData.PetsData.PetInventory.Data do
                count = count + 1
            end

            return count >= maxPets and true or false
        end
        function Pets.HatchPets()
            for _, model in objectsPhysical:GetChildren()do
                if not model:IsA('Model') then
                    continue
                end
                if model:GetAttribute('OBJECT_TYPE') ~= 'PetEgg' then
                    continue
                end

                local prompt = model:FindFirstChild('ProximityPrompt', true)

                if prompt and prompt:IsA('ProximityPrompt') and prompt.Enabled then
                    gameEventsFolder.PetEggService:FireServer('HatchPet', model)
                    Utils.PrintDebug('hatched egg')
                end
            end
        end
        function Pets.HatchEggByUUID(eggUUID)
            for _, model in objectsPhysical:GetChildren()do
                if not model:IsA('Model') then
                    continue
                end
                if model:GetAttribute('OBJECT_TYPE') ~= 'PetEgg' then
                    continue
                end

                local uuid = model:GetAttribute('OBJECT_UUID')

                if not uuid then
                    continue
                end
                if uuid == eggUUID then
                    gameEventsFolder.PetEggService:FireServer('HatchPet', model)
                    Utils.PrintDebug('hatched egg')
                end
            end
        end
        function Pets.IsMaxEggPlanted()
            local count = 0

            for _, v in objectsPhysical:GetChildren()do
                if not v:IsA('Model') then
                    continue
                end
                if v:GetAttribute('OBJECT_TYPE') ~= 'PetEgg' then
                    continue
                end

                count = count + 1
            end

            if count >= playerData.PetsData.MutableStats.MaxEggsInFarm then
                return true
            end

            return false
        end
        function Pets.GetAmountOfEggsPlanted(folder)
            local count = 0

            for _, v in folder:GetChildren()do
                if not v:IsA('Model') then
                    continue
                end
                if v:GetAttribute('OBJECT_TYPE') ~= 'PetEgg' then
                    continue
                end

                count = count + 1
            end

            return count
        end
        function Pets.IsMaxPetsEquipped()
            local petsData = playerData.PetsData

            if #petsData.EquippedPets >= petsData.MutableStats.MaxEquippedPets then
                return true
            end

            return false
        end
        function Pets.GetAllPetsCurrentlyFarming()
            return playerData.PetsData.EquippedPets
        end
        function Pets.IsPetAlreadyFarming(petUUID)
            for _, v in playerData.PetsData.EquippedPets do
                if v == petUUID then
                    return true
                end
            end

            return false
        end
        function Pets.RemovePetFromFarm(petUUID)
            gameEventsFolder.PetsService:FireServer('UnequipPet', petUUID)
            task.wait(2)
        end
        function Pets.RemoveAllPetsFromFarm()
            repeat
                for _, uuid in Pets.GetAllPetsCurrentlyFarming()do
                    Pets.RemovePetFromFarm(uuid)
                end

                task.wait(1)
            until #Pets.GetAllPetsCurrentlyFarming() <= 0

            Utils.PrintDebug('Equpped All Pets from farming')
        end
        function Pets.PlacePetToFarm(petUUID, position)
            gameEventsFolder.PetsService:FireServer('EquipPet', petUUID, position)
            task.wait(2)
        end
        function Pets.GetHighestPetUUIDWithCap(MaxLevel)
            local petUUID
            local petLevel = 0

            for uuid, v in playerData.PetsData.PetInventory.Data do
                if not v.PetType then
                    continue
                end
                if Pets.IsPetAlreadyFarming(uuid) then
                    continue
                end
                if v.PetData.Level >= MaxLevel then
                    continue
                end
                if v.PetData.Level > petLevel then
                    petLevel = v.PetData.Level
                    petUUID = uuid
                end
            end

            return petUUID
        end
        function Pets.GetMaxLevelPetUUID(MaxLevel)
            for uuid, v in playerData.PetsData.PetInventory.Data do
                if not v.PetType then
                    continue
                end
                if Pets.IsPetAlreadyFarming(uuid) then
                    continue
                end
                if v.PetData.Level >= MaxLevel then
                    return uuid
                end
            end

            return nil
        end
        function Pets.GetHighestPetUUIDWithCapButNoDinos(MaxLevel)
            local petUUID
            local petLevel = 0

            for uuid, v in playerData.PetsData.PetInventory.Data do
                if not v.PetType then
                    continue
                end
                if Pets.IsPetAlreadyFarming(uuid) then
                    continue
                end
                if table.find(Dinos, v.PetType) then
                    continue
                end
                if v.PetData.Level >= MaxLevel then
                    continue
                end
                if v.PetData.Level > petLevel then
                    petLevel = v.PetData.Level
                    petUUID = uuid
                end
            end

            return petUUID
        end
        function Pets.GetHighestPetUUIDWithCapAndName(MaxLevel, petNames)
            local petUUID
            local petLevel = -1

            for uuid, v in playerData.PetsData.PetInventory.Data do
                if not v.PetType then
                    continue
                end
                if table.find(petNames, v.PetType) then
                    if Pets.IsPetAlreadyFarming(uuid) then
                        continue
                    end
                    if v.PetData.Level >= MaxLevel then
                        continue
                    end
                    if v.PetData.Level >= petLevel then
                        petLevel = v.PetData.Level
                        petUUID = uuid
                    end
                end
            end

            return petUUID
        end
        function Pets.GetPetUUID(petName)
            for uuid, v in playerData.PetsData.PetInventory.Data do
                if v.PetType ~= petName then
                    continue
                end
                if Pets.IsPetAlreadyFarming(uuid) then
                    continue
                end

                return uuid
            end

            return nil
        end
        function Pets.GetPetDataFor(petUUID)
            return playerData.PetsData.PetInventory.Data[petUUID]
        end
        function Pets.GetUUIDPetsToSell(keepList)
            local sellList = {}

            for uuid, value in playerData.PetsData.PetInventory.Data do
                if table.find(keepList, value.PetType) then
                    continue
                end
                if value.PetData.BaseWeight > BASE_WEIGHT then
                    continue
                end

                table.insert(sellList, uuid)
            end

            return sellList
        end
        function Pets.SellUnWantedPets(keepList)
            for _, petUUID in Pets.GetUUIDPetsToSell(keepList)do
                local petTool = Pets.GetPetToolByUUID(petUUID)

                if not petTool then
                    continue
                end

                Utils.GetHumanoid():EquipTool(petTool)
                Utils.WaitForToolToEquip(10)
                Pets.SellPet(petTool)
                Utils.PrintDebug(string.format('Sold Pet: %s', tostring(petTool.Name)))
                task.wait(1)
            end
        end
        function Pets.GetUUIDPetForDinoMachine(keepList)
            for uuid, value in playerData.PetsData.PetInventory.Data do
                if table.find(Dinos, value.PetType) then
                    continue
                end
                if table.find(keepList, value.PetType) then
                    continue
                end
                if value.PetData.BaseWeight > BASE_WEIGHT then
                    continue
                end

                return uuid
            end

            return nil
        end
        function Pets.FeedPet(petUUID)
            gameEventsFolder.ActivePetService:FireServer('Feed', petUUID)
            task.wait(1)
        end
        function Pets.GetPetToolByUUID(petUUID)
            for _, petTool in backPack:GetChildren()do
                if not petTool:IsA('Tool') then
                    continue
                end
                if petTool:GetAttribute('PetType') ~= 'Pet' then
                    continue
                end

                local uuid = (petTool:GetAttribute('PET_UUID'))

                if not uuid then
                    continue
                end
                if uuid ~= petUUID then
                    continue
                end

                return petTool
            end

            return nil
        end
        function Pets.GetPetNamesThatAreFarming()
            local petNames = {}
            local petsFarming = Pets.GetAllPetsCurrentlyFarming()

            for _, uuid in petsFarming do
                local petInfo = Pets.GetPetDataFor(uuid)

                table.insert(petNames, petInfo.PetType)
            end

            return petNames
        end
        function Pets.TurnInPetForExtraSlot(uuid, slotName)
            gameEventsFolder.UnlockSlotFromPet:FireServer(uuid, slotName)
            Utils.PrintDebug('Unlocked slotName')
        end
        function Pets.TryExtraSlotUpgrade(pets, purchasedSlotName, slotName)
            local slotAmount = playerData.PetsData[purchasedSlotName]

            if typeof(slotAmount) ~= 'number' then
                Utils.PrintDebug(string.format('The type of %s is not a number', tostring(slotAmount)))

                return
            end
            if slotAmount >= 5 then
                return true
            end

            Utils.PrintDebug(string.format('%s: isnt Max yet so checking if pet meets level required', tostring(purchasedSlotName)))

            for uuid, value in playerData.PetsData.PetInventory.Data do
                if not table.find(pets, value.PetType) then
                    continue
                end
                if value.PetData.Level == unlockableSlots[tostring(slotAmount + 1)] then
                    Utils.PrintDebug(string.format('pet level: %s,  unlock level: %s', tostring(value.PetData.Level), tostring(unlockableSlots[tostring(slotAmount + 1)])))
                    Pets.RemovePetFromFarm(uuid)
                    Pets.TurnInPetForExtraSlot(uuid, slotName)
                    task.wait(3)
                end
            end

            if playerData.PetsData[purchasedSlotName] >= 5 then
                return true
            end

            Utils.PrintDebug(string.format('%s: still need more slots to unlock', tostring(purchasedSlotName)))

            return false
        end
        function Pets.TryEligiblePetForExtraSlots(pets)
            if not Pets.TryExtraSlotUpgrade(pets, 'PurchasedEggSlots', 'Egg') then
                return
            end
            if not Pets.TryExtraSlotUpgrade(pets, 'PurchasedEquipSlots', 'Pet') then
                return
            end
            if not Pets.TryExtraSlotUpgrade(pets, 'PurchasedPetInventorySlots', 'PetInventory') then
                return
            end
        end

        return Pets
    end
    function __DARKLUA_BUNDLE_MODULES.e()
        local Players = game:GetService('Players')
        local Pets = __DARKLUA_BUNDLE_MODULES.load('d')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local PetTradingHandler = {}
        local localPlayer = Players.LocalPlayer
        local playerGui = localPlayer:WaitForChild('PlayerGui')
        local giftNotification = (playerGui:WaitForChild('Gift_Notification'))
        local MAX_PET_LEVEL = getgenv().CONFIGS.PET_MAX_LEVEL or 100
        local MULES = getgenv().CONFIGS.MULES
        local giftPet = function(character)
            if not character then
                return false
            end

            local player = Players:GetPlayerFromCharacter(character)

            if not player then
                return false
            end

            local humanoidRootPart = (character:FindFirstChild('HumanoidRootPart'))

            if not humanoidRootPart then
                return false
            end

            local petUUID = Pets.GetMaxLevelPetUUID(MAX_PET_LEVEL)

            if not petUUID then
                return false
            end

            local petTool = Pets.GetPetToolByUUID(petUUID)

            if not petTool then
                return false
            end

            Utils.GetHumanoid():EquipTool(petTool)
            Utils.WaitForToolToEquip(5)

            if Utils.TeleportPlayerTo(humanoidRootPart) then
                Pets.GiftPet(player)
                Utils.PrintDebug(string.format('Traded: %s Pet: %s', tostring(player.Name), tostring(petTool.Name)))

                return true
            end

            return false
        end
        local startTrading = function(character)
            task.wait(1)
            Utils.PrintDebug(string.format('Trading %s', tostring(character)))
            task.spawn(function()
                while true do
                    local hasPet = giftPet(character)

                    if not hasPet then
                        break
                    end

                    task.wait(10)
                end

                Utils.PrintDebug('Doesnt have anymore pets to trade')
            end)
        end

        function PetTradingHandler.Init()
            giftNotification:WaitForChild('Frame').ChildAdded:Connect(function(
                child
            )
                if child.Name ~= 'Gift_Notification' then
                    return
                end

                local notification = child

                if not notification:WaitForChild('Holder', 10) then
                    return
                end
                if not notification.Holder:WaitForChild('Frame', 10) then
                    return
                end

                local acceptButton = (notification.Holder.Frame:WaitForChild('Accept', 10))

                if not acceptButton then
                    return
                end

                firesignal((acceptButton.MouseButton1Click))
                Utils.PrintDebug('clicked on button')
            end)

            if localPlayer.Name == localPlayer.Name then
                return
            end

            Players.PlayerAdded:Connect(function(player)
                if not table.find(MULES, player.Name) then
                    return
                end

                Utils.PrintDebug('Mule joined game. sending trade')
                player.CharacterAdded:Connect(function(character)
                    startTrading(character)
                end)
            end)
        end
        function PetTradingHandler.Start()
            repeat
                local notification = (giftNotification:WaitForChild('Frame'):FindFirstChild('Gift_Notification'))

                if not notification then
                    return
                end
                if not notification:FindFirstChild('Holder') then
                    return
                end
                if not notification.Holder:FindFirstChild('Frame') then
                    return
                end

                local acceptButton = (notification.Holder.Frame:FindFirstChild('Accept'))

                if not acceptButton then
                    return
                end

                firesignal((acceptButton.MouseButton1Click))
                Utils.PrintDebug('clicked on button')
                task.wait(1)
            until not notification

            if localPlayer.Name == localPlayer.Name then
                return
            end

            for _, player in Players:GetPlayers()do
                if not table.find(MULES, player.Name) then
                    continue
                end
                if not player.Character then
                    continue
                end

                startTrading(player.Character)
            end
        end

        return PetTradingHandler
    end
    function __DARKLUA_BUNDLE_MODULES.f()
        local Players = game:GetService('Players')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local ToolHandle = {}
        local localPlayer = Players.LocalPlayer
        local playerBackpack = localPlayer:WaitForChild('Backpack')
        local isToolAlreadyEquipped = function(toolName)
            local hasTool = Utils.GetCharacter():FindFirstChild(toolName)

            if not (hasTool and hasTool:IsA('Tool')) then
                return false
            end

            return true
        end
        local waitForTool = function(tool)
            local isToolEquipped
            local count = 0
            local MAX_COUNT = 20

            repeat
                isToolEquipped = isToolAlreadyEquipped(tool.Name)
                count = count + 1

                task.wait(1)
            until isToolEquipped or count >= MAX_COUNT

            if count >= MAX_COUNT then
                return false
            end

            return true
        end
        local getToolFromBackpack = function(toolName)
            local tool = playerBackpack:FindFirstChild(toolName)

            if not (tool and tool:IsA('Tool')) then
                return nil
            end

            return tool
        end

        function ToolHandle.EquipTool(toolName)
            if not toolName then
                return false
            end
            if isToolAlreadyEquipped(toolName) then
                return true
            end

            local tool = getToolFromBackpack(toolName)

            if not tool then
                return false
            end

            Utils.GetHumanoid():EquipTool(tool)
            task.wait()

            return waitForTool(tool)
        end

        return ToolHandle
    end
    function __DARKLUA_BUNDLE_MODULES.g()
        return {
            ['Strawberry'] = {
                MaxLimit = 50,
                StopPlantingAfterAmount = 1000000,
            },
            ['Carrot'] = {
                MaxLimit = 50,
                StopPlantingAfterAmount = 1000000,
            },
            ['Blueberry'] = {
                MaxLimit = 50,
                StopPlantingAfterAmount = 1000000,
            },
            ['Tomato'] = {
                MaxLimit = 50,
                StopPlantingAfterAmount = 50000000,
            },
            ['Cauliflower'] = {
                MaxLimit = 50,
                StopPlantingAfterAmount = 50000000,
            },
            ['Watermelon'] = {
                MaxLimit = 50,
                StopPlantingAfterAmount = 50000000,
            },
        }
    end
    function __DARKLUA_BUNDLE_MODULES.h()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local MutationHandler = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('MutationHandler')))
        local SeedLimits = __DARKLUA_BUNDLE_MODULES.load('g')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Inventory = {}
        local localPlayer = Players.LocalPlayer
        local playerData = DataService:GetData()
        local playerBackpack = localPlayer:WaitForChild('Backpack')

        function Inventory.IsMaxQuantity(seedName)
            if not SeedLimits[seedName] then
                return false
            end

            for _, v in playerData.InventoryData do
                if v.ItemType ~= 'Seed' then
                    continue
                end
                if v.ItemData.ItemName and v.ItemData.ItemName ~= seedName then
                    continue
                end
                if v.ItemData.Quantity and v.ItemData.Quantity >= SeedLimits[seedName]['MaxLimit'] then
                    return true
                end
            end

            return false
        end
        function Inventory.GetGearQuantity(gearName)
            for _, v in playerData.InventoryData do
                if v.ItemType ~= gearName then
                    continue
                end
                if v.ItemData.Uses then
                    return v.ItemData.Uses
                end
            end

            return 0
        end
        function Inventory.MutationCountFor(fruitModel)
            local count = 0

            for name, value in fruitModel:GetAttributes()do
                if MutationHandler.MutationNames[name] then
                    count = count + 1
                end
            end

            Utils.PrintDebug(string.format('%s has %s mutations', tostring(fruitModel), tostring(count)))

            return count
        end
        function Inventory.IsFruitNormalVariant(fruitModel)
            local variant = (fruitModel:WaitForChild('Variant', 6))

            if variant and variant.Value == 'Normal' then
                return true
            end

            return false
        end
        function Inventory.GetRandomFruitUUID()
            for uuid, v in playerData.InventoryData do
                if v.ItemType ~= 'Holdable' then
                    continue
                end
                if v.ItemData.IsFavorite then
                    continue
                end
                if v.ItemData.Variant == 'Normal' then
                    return uuid
                end
            end

            return nil
        end
        function Inventory.GetTanningMirrorUUID()
            for uuid, v in playerData.InventoryData do
                if v.ItemType ~= 'Tanning Mirror' then
                    continue
                end

                return uuid
            end

            return nil
        end
        function Inventory.GetSprinklerUUID(name)
            for uuid, v in playerData.InventoryData do
                if v.ItemType ~= 'Sprinkler' then
                    continue
                end
                if v.ItemData.ItemName ~= name then
                    continue
                end

                return uuid
            end

            return nil
        end
        function Inventory.GetFruitModel()
            local fruitUUID = Inventory.GetRandomFruitUUID()

            if not fruitUUID then
                return nil
            end

            for _, tool in playerBackpack:GetChildren()do
                if not tool:IsA('Tool') then
                    continue
                end

                local toolUUID = tool:GetAttribute('c')

                if not toolUUID then
                    continue
                end
                if fruitUUID ~= toolUUID then
                    continue
                end

                return tool
            end

            return nil
        end
        function Inventory.GetMaxBackpackHold()
            local bonusBackpackSize = (localPlayer:GetAttribute('BonusBackpackSize'))

            return 200 + (bonusBackpackSize or 0)
        end
        function Inventory.GetAmountOfFruits()
            local count = 0

            for uuid, value in playerData.InventoryData do
                if value.ItemType ~= 'Holdable' then
                    continue
                end

                count = count + 1
            end

            return count
        end
        function Inventory.GetSeedPackInventory()
            for uuid, value in playerData.InventoryData do
                if value.ItemType ~= 'Seed Pack' then
                    continue
                end

                return value.ItemData.Type
            end

            return nil
        end

        return Inventory
    end
    function __DARKLUA_BUNDLE_MODULES.i()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local ByteNetRemotes = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('Remotes')))
        local InventoryService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('InventoryService')))
        local ToolHandle = __DARKLUA_BUNDLE_MODULES.load('f')
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('c')
        local Pets = __DARKLUA_BUNDLE_MODULES.load('d')
        local Inventory = __DARKLUA_BUNDLE_MODULES.load('h')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local FarmPlot = {}
        local fireCollect = ByteNetRemotes.Crops.Collect.send
        local localPlayer = Players.LocalPlayer
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local playerBackpack = localPlayer:WaitForChild('Backpack')
        local myFarmPlot = FarmPlotPath.GetFarmPlotFor(localPlayer)
        local important = myFarmPlot.Important
        local plantsPhysical = important.Plants_Physical
        local rng = Random.new()
        local MAX_PLANTED = 800
        local plantSeed = function(position, seed)
            local x = rng:NextNumber(-10, 10)
            local z = rng:NextNumber(-10, 10)
            local newPosition = position + Vector3.new(x, 0.13, z)

            gameEventsFolder.Plant_RE:FireServer(newPosition, seed)
        end
        local tryCollectPlant = function(model, isNewPlayer, forceHarvestFruit)
            if InventoryService:IsMaxInventory() then
                return false
            end

            local prompt = model:FindFirstChild('ProximityPrompt', true)

            if prompt and prompt:IsA('ProximityPrompt') and prompt.Enabled then
                if forceHarvestFruit or isNewPlayer or Inventory.IsFruitNormalVariant(model) or Inventory.MutationCountFor(model) >= 3 then
                    fireCollect({model})
                    task.wait(0.1)
                end
            end

            return true
        end
        local loopFruitsFolder = function(
            folder,
            isNewPlayer,
            forceHarvestFruit
        )
            for _, fruitModel in folder:GetChildren()do
                if not fruitModel:IsA('Model') then
                    continue
                end
                if not tryCollectPlant(fruitModel, isNewPlayer, forceHarvestFruit) then
                    return false
                end
            end

            return true
        end

        function FarmPlot.PlantEgg(position, eggName)
            local x = rng:NextNumber(-10, 10)
            local z = rng:NextNumber(-10, 10)
            local newPosition = position + Vector3.new(x, 0.135, z)

            gameEventsFolder.PetEggService:FireServer('CreateEgg', newPosition)
            Utils.PrintDebug(string.format('PlantedEgg: %s', tostring(eggName)))
        end
        function FarmPlot.IsRmoveablePlantInGarden(seedsToFarm, folder)
            for _, fruitModel in folder:GetChildren()do
                if not fruitModel:IsA('Model') then
                    continue
                end
                if not table.find(seedsToFarm, fruitModel.Name) then
                    return true
                end
            end

            return false
        end
        function FarmPlot.RemovePlantsNotInTable(seedsToFarm, folder)
            local isShovelToolEquipped = ToolHandle.EquipTool('Shovel [Destroy Plants]')

            if not isShovelToolEquipped then
                return
            end

            for _, fruitModel in folder:GetChildren()do
                if not fruitModel:IsA('Model') then
                    continue
                end
                if not table.find(seedsToFarm, fruitModel.Name) then
                    Utils.PrintDebug(string.format('Removed tree: %s', tostring(fruitModel.Name)))
                    gameEventsFolder.Remove_Item:FireServer(fruitModel.PrimaryPart)
                    task.wait(0.2)
                end
            end
        end
        function FarmPlot.HarvestPlants(
            plantNames,
            isNewPlayer,
            forceHarvestFruit
        )
            for _, plantModel in plantsPhysical:GetChildren()do
                if not plantModel:IsA('Model') then
                    continue
                end
                if not forceHarvestFruit then
                    if not table.find(plantNames, plantModel.Name) then
                        continue
                    end
                end

                local fruitsFolder = plantModel:FindFirstChild('Fruits')

                if fruitsFolder and #fruitsFolder:GetChildren() >= 1 then
                    loopFruitsFolder(fruitsFolder, isNewPlayer, forceHarvestFruit)
                else
                    if not tryCollectPlant(plantModel, isNewPlayer, forceHarvestFruit) then
                        return
                    end
                end
            end
        end
        function FarmPlot.GetSeed(tbl)
            for _, tool in playerBackpack:GetChildren()do
                if not tool:IsA('Tool') then
                    continue
                end

                local seedName = tool:GetAttribute('Seed')

                if not seedName or typeof(seedName) ~= 'string' then
                    continue
                end
                if not table.find(tbl, seedName) then
                    continue
                end

                return tool
            end

            return nil
        end
        function FarmPlot.LoopPlantingSameSeed(tool, dirtPart)
            local seedName = tool:GetAttribute('Seed')

            if not seedName or typeof(seedName) ~= 'string' then
                return
            end

            repeat
                ToolHandle.EquipTool(tool.Name)
                plantSeed(dirtPart.Position, seedName)
                task.wait(1)
            until not tool.Parent or tool:GetAttribute('Quantity') <= 0 or #plantsPhysical:GetChildren() >= MAX_PLANTED
        end
        function FarmPlot.GetEggToolandPlant(eggsNotToPlant, dirtPart)
            for _, eggTool in playerBackpack:GetChildren()do
                if Pets.IsMaxEggPlanted() then
                    return
                end
                if not eggTool:IsA('Tool') then
                    continue
                end

                local eggName = eggTool:GetAttribute('h')

                if eggName and typeof(eggName) == 'string' then
                    if table.find(eggsNotToPlant, eggName) then
                        continue
                    end

                    repeat
                        ToolHandle.EquipTool(eggTool.Name)
                        FarmPlot.PlantEgg(dirtPart.Position, eggName)
                        task.wait(1)
                    until not eggTool.Parent or Pets.IsMaxEggPlanted() or eggTool:GetAttribute('LocalUses') <= 0
                end
            end
        end
        function FarmPlot.HasEggToPlant(eggsNotToPlant)
            for _, v in playerBackpack:GetChildren()do
                if not v:IsA('Tool') then
                    continue
                end

                local eggName = v:GetAttribute('h')

                if eggName and typeof(eggName) == 'string' then
                    if table.find(eggsNotToPlant, eggName) then
                        continue
                    end

                    return true
                end
            end

            return false
        end

        return FarmPlot
    end
    function __DARKLUA_BUNDLE_MODULES.j()
        local GearList = {
            ['Advanced Sprinkler'] = {
                CanBuy = true,
                MaxBuyLimit = 999,
                MaxAmountToPlant = 1,
            },
            ['Godly Sprinkler'] = {
                CanBuy = true,
                MaxBuyLimit = 999,
                MaxAmountToPlant = 1,
            },
            ['Master Sprinkler'] = {
                CanBuy = true,
                MaxBuyLimit = 999,
                MaxAmountToPlant = 1,
            },
            ['Tanning Mirror'] = {
                CanBuy = true,
                MaxBuyLimit = 999,
                MaxAmountToPlant = 999,
            },
        }

        return GearList
    end
    function __DARKLUA_BUNDLE_MODULES.k()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Workspace = game:GetService('Workspace')
        local Players = game:GetService('Players')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local SeedData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('SeedData')))
        local GearData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('GearData')))
        local PetEggData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('PetEggData')))
        local ByteNetRemotes = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('Remotes')))
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Inventory = __DARKLUA_BUNDLE_MODULES.load('h')
        local GearList = __DARKLUA_BUNDLE_MODULES.load('j')
        local Shops = {}
        local localPlayer = Players.LocalPlayer
        local playerData = DataService:GetData()
        local backpack = localPlayer:WaitForChild('Backpack')
        local npcsFolder = Workspace:WaitForChild('NPCS')
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local BuyPetEggRemote = gameEventsFolder:WaitForChild('BuyPetEgg')
        local loopBuyAllofSameItem = function(requireData, remote, name, item)
            while true do
                if item.Stock <= 0 then
                    return
                end
                if requireData[name].Price > Utils.GetPlayerSheckles() then
                    return
                end
                if Inventory.IsMaxQuantity(name) then
                    return
                end

                remote:FireServer(name)
                task.wait(1)
            end
        end

        function Shops.SellSingleFruit()
            local stevenNPC = (npcsFolder:FindFirstChild('Steven'))

            if not stevenNPC then
                return
            end

            local stevenHead = (stevenNPC.PrimaryPart)

            if Utils.IsCharacterAtLocation(stevenHead, 6) then
                gameEventsFolder.Sell_Item:FireServer()
            else
                Utils.GetCharacter():PivotTo(stevenNPC:GetPivot() * CFrame.new(0, 0, 
-5))
                task.wait(5)
                gameEventsFolder.Sell_Item:FireServer()
            end
        end
        function Shops.SellAllInventory()
            local stevenNPC = (npcsFolder:FindFirstChild('Steven'))

            if not stevenNPC then
                return
            end

            local stevenHead = (stevenNPC.PrimaryPart)

            if Utils.IsCharacterAtLocation(stevenHead, 6) then
                gameEventsFolder.Sell_Inventory:FireServer()
            else
                Utils.GetCharacter():PivotTo(stevenNPC:GetPivot() * CFrame.new(0, 0, 
-5))
                Utils.IsCharacterAtLocation(stevenHead, 6)
                task.wait(1)
                gameEventsFolder.Sell_Inventory:FireServer()
            end
        end
        function Shops.BuySeeds(tbl)
            for name, seed in playerData.SeedStock.Stocks do
                if not table.find(tbl, name) then
                    continue
                end

                loopBuyAllofSameItem(SeedData, gameEventsFolder.BuySeedStock, name, seed)
                Utils.PrintDebug(string.format('Bought seed: %s, stock left: %s', tostring(name), tostring(seed.Stock)))
            end
        end
        function Shops.BuyFromEventShop(toBuy)
            for name, item in playerData.EventShopStock.Stocks do
                if not table.find(toBuy, name) then
                    continue
                end

                gameEventsFolder.BuyEventShopStock:FireServer(name)
                Utils.PrintDebug(string.format('Bought %s from eventshop', tostring(name)))
                task.wait(0.1)
            end
        end
        function Shops.BuyEggs(tbl)
            for i = 1, 3 do
                if table.find(tbl, playerData.PetEggStock.Stocks[i].EggName) then
                    continue
                end
                if playerData.PetEggStock.Stocks[i].Stock <= 0 then
                    continue
                end
                if PetEggData[playerData.PetEggStock.Stocks[i].EggName].Price > Utils.GetPlayerSheckles() then
                    continue
                end

                Utils.PrintDebug(string.format('buying egg: %s', tostring(playerData.PetEggStock.Stocks[i].EggName)))
                BuyPetEggRemote:FireServer(i)
                task.wait(0.1)
            end
        end
        function Shops.GetAllSeedRaritys()
            local raritys = {}

            for i, v in SeedData do
                if table.find(raritys, v.SeedRarity) then
                    continue
                end

                table.insert(v.SeedRarity)
            end

            return raritys
        end
        function Shops.BuyGears()
            for name, gear in playerData.GearStock.Stocks do
                if not (GearList[name] and GearList[name].CanBuy) then
                    continue
                end

                local amount = Inventory.GetGearQuantity(name)

                if amount >= GearList[name].MaxBuyLimit then
                    continue
                end

                loopBuyAllofSameItem(GearData, gameEventsFolder.BuyGearStock, name, gear)
                Utils.PrintDebug(string.format('Bought gear: %s, stock left: %s', tostring(name), tostring(gear.Stock)))
            end
        end
        function Shops.TryTurnInAllSummerHarvestFruits()
            gameEventsFolder.SummerHarvestRemoteEvent:FireServer('SubmitAllPlants')
        end
        function Shops.TryTurnInSummerHarvestFruitsByEquip()
            for _, toolModel in backpack:GetChildren()do
                if not toolModel:IsA('Tool') then
                    continue
                end

                local variant = (toolModel:FindFirstChild('Variant'))

                if not variant then
                    continue
                end
                if variant.Value == 'Normal' then
                    print('giving fruit')
                    Utils.GetHumanoid():EquipTool(toolModel)
                    Utils.WaitForToolToEquip(2)
                    gameEventsFolder.SummerHarvestRemoteEvent:FireServer('SubmitHeldPlant')
                    task.wait(0.1)
                end
            end
        end
        function Shops.SellGoldenAndRainbowFruitsByEquip()
            for _, toolModel in backpack:GetChildren()do
                if not toolModel:IsA('Tool') then
                    continue
                end

                local variant = (toolModel:FindFirstChild('Variant'))

                if not variant then
                    continue
                end
                if variant.Value ~= 'Normal' then
                    Utils.PrintDebug(string.format('Equipping Tool: %s', tostring(toolModel.Name)))
                    Utils.GetHumanoid():EquipTool(toolModel)
                    Utils.WaitForToolToEquip(10)
                    Shops.SellSingleFruit()
                    task.wait(0.25)
                end
            end
        end
        function Shops.OpenSeedPack(seedPackName)
            Utils.PrintDebug(string.format('Opened seedpack: %s', tostring(seedPackName)))
            ByteNetRemotes.SeedPack.Open.send(seedPackName)
        end
        function Shops.BuyTravelingMerchantBaldEagle()
            if playerData.TravelingMerchantShopStock.Stocks['Bald Eagle'].Stock == 0 then
                return
            end

            gameEventsFolder.BuyTravelingMerchantShopStock:FireServer('Bald Eagle')
        end

        return Shops
    end
    function __DARKLUA_BUNDLE_MODULES.l()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local SeedData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('SeedData')))
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('c')
        local PlayerStage = {}

        PlayerStage.IsNewPlayer = false

        local localPlayer = Players.LocalPlayer
        local myFarmPlot = FarmPlotPath.GetFarmPlotFor(localPlayer)
        local important = myFarmPlot.Important
        local plantsPhysical = important.Plants_Physical
        local getRarityPlantedCount = function(rarity)
            local count = 0

            for _, model in plantsPhysical:GetChildren()do
                if not SeedData[model.Name] then
                    continue
                end
                if SeedData[model.Name].SeedRarity == rarity then
                    count = count + 1
                end
            end

            return count
        end
        local updateRarityToFarm = function()
            local newTable = {}

            if getRarityPlantedCount('Prismatic') >= 10 then
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                }
            elseif getRarityPlantedCount('Divine') >= 10 then
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                    'Divine',
                }
            elseif getRarityPlantedCount('Mythical') >= 10 then
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                    'Divine',
                    'Mythical',
                }
            elseif getRarityPlantedCount('Legendary') >= 10 then
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                    'Divine',
                    'Mythical',
                    'Legendary',
                }
            elseif getRarityPlantedCount('Rare') >= 0 then
                PlayerStage.IsNewPlayer = true
                newTable = {
                    'Prismatic',
                    'Divine',
                    'Mythical',
                    'Legendary',
                    'Rare',
                    'Uncommon',
                    'Common',
                }
            end

            return newTable
        end

        function PlayerStage.GetSeedNamesToFarm()
            local raritys = updateRarityToFarm()
            local seedNames = {}

            for key, vlaue in SeedData do
                if table.find(raritys, SeedData[key].SeedRarity) then
                    table.insert(seedNames, key)
                end
            end

            return seedNames
        end

        return PlayerStage
    end
    function __DARKLUA_BUNDLE_MODULES.m()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local GearList = __DARKLUA_BUNDLE_MODULES.load('j')
        local Inventory = __DARKLUA_BUNDLE_MODULES.load('h')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('c')
        local GearPlantable = {}
        local localPlayer = Players.LocalPlayer
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local playerBackpack = localPlayer:WaitForChild('Backpack')
        local rng = Random.new()
        local objectsPhysical = FarmPlotPath.GetFarmPlotFor(localPlayer).Important.Objects_Physical
        local amountPlanted = function(gearName)
            local count = 0

            for i, v in objectsPhysical:GetChildren()do
                if v.Name == gearName then
                    count = count + 1
                end
            end

            return count
        end

        function GearPlantable.PlaceOnDirt(remoteService, position)
            local x = rng:NextNumber(-10, 10)
            local z = rng:NextNumber(-10, 10)
            local newPosition = position + Vector3.new(x, 0.135, z)

            if remoteService == 'TanningMirrorService' then
                gameEventsFolder.TanningMirrorService:FireServer('Create', newPosition)

                return
            end

            gameEventsFolder.SprinklerService:FireServer('Create', newPosition)
        end
        function GearPlantable.GetGearToolInBackpackByUUID(uuid)
            for _, tool in playerBackpack:GetChildren()do
                if not tool:IsA('Tool') then
                    continue
                end

                local toolUUID = tool:GetAttribute('c')

                if not (toolUUID and typeof(toolUUID) == 'string') then
                    continue
                end
                if toolUUID ~= uuid then
                    continue
                end

                return tool
            end

            return nil
        end
        function GearPlantable.IsMaxAmountPlanted(gearName)
            if GearList[gearName] and GearList[gearName].CanBuy then
                if amountPlanted(gearName) >= GearList[gearName].MaxAmountToPlant then
                    return true
                end
            end

            return false
        end
        function GearPlantable.EquipAndPlantGearTools(centerPoint, dirtPart)
            for key, _ in GearList do
                if GearPlantable.IsMaxAmountPlanted(key) then
                    continue
                end

                local uuid = Inventory.GetSprinklerUUID(key) or Inventory.GetTanningMirrorUUID()

                if not uuid then
                    continue
                end

                local tool = GearPlantable.GetGearToolInBackpackByUUID(uuid)

                if not tool then
                    continue
                end

                print(string.format('tool: %s', tostring(tool.Name)))
                Utils.TeleportPlayerTo(centerPoint)
                task.wait(1)
                Utils.GetHumanoid():EquipTool(tool)
                task.wait(1)

                if tool.Name:match('Sprinkler') then
                    print('placing Sprinkler')
                    GearPlantable.PlaceOnDirt('SprinklerService', dirtPart.CFrame)
                elseif tool.Name:match('Mirror') then
                    print('placing Tanning Mirror')
                    GearPlantable.PlaceOnDirt('TanningMirrorService', dirtPart.CFrame)
                end
            end
        end

        return GearPlantable
    end
    function __DARKLUA_BUNDLE_MODULES.n()
        local Players = game:GetService('Players')
        local GuiClass = {}

        GuiClass.__index = GuiClass

        local localPlayer = Players.LocalPlayer
        local isVisible = true
        local PlayerStatsGui = Instance.new('ScreenGui')
        local FullFrame = Instance.new('Frame')
        local Username = Instance.new('TextLabel')
        local PetsEquipped = Instance.new('TextLabel')
        local Sheckles = Instance.new('TextLabel')
        local PlantsPlanted = Instance.new('TextLabel')
        local Timer = Instance.new('TextLabel')
        local PetsInInventory = Instance.new('TextLabel')
        local Event = Instance.new('TextLabel')
        local PetsFrame = Instance.new('Frame')
        local TemplatePetInfo = Instance.new('TextLabel')
        local UIGridLayout = Instance.new('UIGridLayout')
        local TextButton = Instance.new('TextButton')

        PlayerStatsGui.Name = 'PlayerStatsGui'
        PlayerStatsGui.Parent = localPlayer:WaitForChild('PlayerGui')
        PlayerStatsGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        PlayerStatsGui.ResetOnSpawn = false
        PlayerStatsGui.IgnoreGuiInset = true
        PlayerStatsGui.DisplayOrder = 1000
        FullFrame.Name = 'FullFrame'
        FullFrame.Parent = PlayerStatsGui
        FullFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        FullFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        FullFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        FullFrame.BorderSizePixel = 0
        FullFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
        FullFrame.Size = UDim2.new(1, 0, 1, 0)
        Username.Name = 'userName'
        Username.Parent = FullFrame
        Username.AnchorPoint = Vector2.new(0.5, 0.5)
        Username.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Username.BackgroundTransparency = 1
        Username.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Username.BorderSizePixel = 0
        Username.Position = UDim2.new(0.499739587, 0, 0.186755031, 0)
        Username.Size = UDim2.new(0.8, 0, 0.116278842, 0)
        Username.Font = Enum.Font.FredokaOne
        Username.Text = string.format('\u{1f916} Username: %s', tostring(localPlayer.Name))
        Username.TextColor3 = Color3.fromRGB(255, 255, 255)
        Username.TextScaled = true
        Username.TextSize = 14
        Username.TextWrapped = true
        PetsEquipped.Name = 'PetsEquipped'
        PetsEquipped.Parent = FullFrame
        PetsEquipped.AnchorPoint = Vector2.new(0.5, 0.5)
        PetsEquipped.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PetsEquipped.BackgroundTransparency = 1
        PetsEquipped.BorderColor3 = Color3.fromRGB(0, 0, 0)
        PetsEquipped.BorderSizePixel = 0
        PetsEquipped.Position = UDim2.new(0.5, 0, 0.390535802, 0)
        PetsEquipped.Size = UDim2.new(0.8, 0, 0.0975197256, 0)
        PetsEquipped.Font = Enum.Font.FredokaOne
        PetsEquipped.Text = '\u{1f407} Equipped Pets: 0/4'
        PetsEquipped.TextColor3 = Color3.fromRGB(255, 255, 255)
        PetsEquipped.TextScaled = true
        PetsEquipped.TextSize = 14
        PetsEquipped.TextWrapped = true
        Sheckles.Name = 'Sheckles'
        Sheckles.Parent = FullFrame
        Sheckles.AnchorPoint = Vector2.new(0.5, 0.5)
        Sheckles.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Sheckles.BackgroundTransparency = 1
        Sheckles.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Sheckles.BorderSizePixel = 0
        Sheckles.Position = UDim2.new(0.5, 0, 0.29322347, 0)
        Sheckles.Size = UDim2.new(0.8, 0, 0.0975197256, 0)
        Sheckles.Font = Enum.Font.FredokaOne
        Sheckles.Text = '\u{1f911} Sheckles: 0'
        Sheckles.TextColor3 = Color3.fromRGB(255, 255, 255)
        Sheckles.TextScaled = true
        Sheckles.TextSize = 14
        Sheckles.TextWrapped = true
        PlantsPlanted.Name = 'PlantsPlanted'
        PlantsPlanted.Parent = FullFrame
        PlantsPlanted.AnchorPoint = Vector2.new(0.5, 0.5)
        PlantsPlanted.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PlantsPlanted.BackgroundTransparency = 1
        PlantsPlanted.BorderColor3 = Color3.fromRGB(0, 0, 0)
        PlantsPlanted.BorderSizePixel = 0
        PlantsPlanted.Position = UDim2.new(0.498958319, 0, 0.800174356, 0)
        PlantsPlanted.Size = UDim2.new(0.8, 0, 0.0975197256, 0)
        PlantsPlanted.Font = Enum.Font.FredokaOne
        PlantsPlanted.Text = '\u{1f334} Plants Planted: 0'
        PlantsPlanted.TextColor3 = Color3.fromRGB(255, 255, 255)
        PlantsPlanted.TextScaled = true
        PlantsPlanted.TextSize = 14
        PlantsPlanted.TextWrapped = true
        Timer.Name = 'Timer'
        Timer.Parent = FullFrame
        Timer.AnchorPoint = Vector2.new(0.5, 0.5)
        Timer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Timer.BackgroundTransparency = 1
        Timer.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Timer.BorderSizePixel = 0
        Timer.Position = UDim2.new(0.499479175, 0, 0.0642491803, 0)
        Timer.Size = UDim2.new(0.8, 0, 0.128913194, 0)
        Timer.Font = Enum.Font.FredokaOne
        Timer.Text = '\u{23f0} 00:00:00'
        Timer.TextColor3 = Color3.fromRGB(255, 255, 255)
        Timer.TextScaled = true
        Timer.TextSize = 14
        Timer.TextWrapped = true
        PetsInInventory.Name = 'PetsInInventory'
        PetsInInventory.Parent = FullFrame
        PetsInInventory.AnchorPoint = Vector2.new(0.5, 0.5)
        PetsInInventory.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        PetsInInventory.BackgroundTransparency = 1
        PetsInInventory.BorderColor3 = Color3.fromRGB(0, 0, 0)
        PetsInInventory.BorderSizePixel = 0
        PetsInInventory.Position = UDim2.new(0.5, 0, 0.701935232, 0)
        PetsInInventory.Size = UDim2.new(0.8, 0, 0.0975197256, 0)
        PetsInInventory.Font = Enum.Font.FredokaOne
        PetsInInventory.Text = '\u{1f436} Pets in inventory: 0/60'
        PetsInInventory.TextColor3 = Color3.fromRGB(255, 255, 255)
        PetsInInventory.TextScaled = true
        PetsInInventory.TextSize = 14
        PetsInInventory.TextWrapped = true
        Event.Name = 'Event'
        Event.Parent = FullFrame
        Event.AnchorPoint = Vector2.new(0.5, 0.5)
        Event.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Event.BackgroundTransparency = 1
        Event.BorderColor3 = Color3.fromRGB(0, 0, 0)
        Event.BorderSizePixel = 0
        Event.Position = UDim2.new(0.5, 0, 0.92457211, 0)
        Event.Size = UDim2.new(0.8, 0, 0.150855929, 0)
        Event.Font = Enum.Font.FredokaOne
        Event.Text = '\u{1f468}\u{200d}\u{1f33e} Harvest Points: 0'
        Event.TextColor3 = Color3.fromRGB(255, 255, 255)
        Event.TextScaled = true
        Event.TextSize = 14
        Event.TextWrapped = true
        PetsFrame.Name = 'PetsFrame'
        PetsFrame.Parent = FullFrame
        PetsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
        PetsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        PetsFrame.BackgroundTransparency = 1
        PetsFrame.BorderColor3 = Color3.fromRGB(0, 0, 0)
        PetsFrame.BorderSizePixel = 0
        PetsFrame.Position = UDim2.new(0.5, 0, 0.546000004, 0)
        PetsFrame.Size = UDim2.new(1, 0, 0.213879734, 0)
        TemplatePetInfo.Name = 'TemplatePetInfo'
        TemplatePetInfo.AnchorPoint = Vector2.new(0.5, 0.5)
        TemplatePetInfo.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
        TemplatePetInfo.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TemplatePetInfo.BorderSizePixel = 0
        TemplatePetInfo.Position = UDim2.new(0.5, 0, 0.5, 0)
        TemplatePetInfo.Size = UDim2.new(0.200000003, 0, 1, 0)
        TemplatePetInfo.Font = Enum.Font.FredokaOne
        TemplatePetInfo.Text = 'petName'
        TemplatePetInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
        TemplatePetInfo.TextScaled = true
        TemplatePetInfo.TextSize = 14
        TemplatePetInfo.TextWrapped = true
        UIGridLayout.Parent = PetsFrame
        UIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        UIGridLayout.CellPadding = UDim2.new(0.00499999989, 0, 0, 0)
        UIGridLayout.CellSize = UDim2.new(0.119999997, 0, 1, 0)
        TextButton.Parent = PlayerStatsGui
        TextButton.AnchorPoint = Vector2.new(0.5, 0.5)
        TextButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        TextButton.BackgroundTransparency = 1
        TextButton.BorderColor3 = Color3.fromRGB(0, 0, 0)
        TextButton.BorderSizePixel = 0
        TextButton.Position = UDim2.new(0.948747337, 0, 0.0804038495, 0)
        TextButton.Size = UDim2.new(0.100000001, 0, 0.149802253, 0)
        TextButton.Font = Enum.Font.SourceSans
        TextButton.Text = '\u{1f648}'
        TextButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        TextButton.TextScaled = true
        TextButton.TextSize = 14
        TextButton.TextWrapped = true

        function GuiClass.new(name)
            local self = setmetatable({}, GuiClass)

            self.TextLabelClone = TemplatePetInfo:Clone()
            self.TextLabelClone.Name = name
            self.TextLabelClone.Text = ''
            self.TextLabelClone.Parent = PetsFrame

            return self
        end
        function GuiClass.SetText(self, text)
            self.TextLabelClone.Text = text
        end
        function GuiClass.SetTextTimer(text)
            Timer.Text = text
        end
        function GuiClass.SetTextSheckles(text)
            Sheckles.Text = text
        end
        function GuiClass.SetTextPetsEquipped(text)
            PetsEquipped.Text = text
        end
        function GuiClass.SetTextPlantsPlanted(text)
            PlantsPlanted.Text = text
        end
        function GuiClass.SetTextPetsInInventory(text)
            PetsInInventory.Text = text
        end
        function GuiClass.SetTextEvent(text)
            Event.Text = text
        end

        TextButton.Activated:Connect(function()
            FullFrame.Visible = not isVisible

            game:GetService('RunService'):Set3dRenderingEnabled(isVisible)

            isVisible = not isVisible
        end)

        return GuiClass
    end
    function __DARKLUA_BUNDLE_MODULES.o()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local DinoEvent = {}
        local playerData = DataService:GetData()
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))

        function DinoEvent.IsDinoEggReady()
            return playerData.DinoMachine.RewardReady
        end
        function DinoEvent.IsDinoMachineRunning()
            return playerData.DinoMachine.IsRunning
        end
        function DinoEvent.ClaimReward()
            gameEventsFolder.DinoMachineService_RE:FireServer('ClaimReward')
        end
        function DinoEvent.GivePetToMachine()
            gameEventsFolder.DinoMachineService_RE:FireServer('MachineInteract')
        end

        return DinoEvent
    end
    function __DARKLUA_BUNDLE_MODULES.p()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local VirtualInputManager = game:GetService('VirtualInputManager')
        local Workspace = game:GetService('Workspace')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('c')
        local FarmPlot = __DARKLUA_BUNDLE_MODULES.load('i')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Shops = __DARKLUA_BUNDLE_MODULES.load('k')
        local Inventory = __DARKLUA_BUNDLE_MODULES.load('h')
        local Pets = __DARKLUA_BUNDLE_MODULES.load('d')
        local PlayerStage = __DARKLUA_BUNDLE_MODULES.load('l')
        local GearPlantable = __DARKLUA_BUNDLE_MODULES.load('m')
        local GuiClass = __DARKLUA_BUNDLE_MODULES.load('n')
        local DinoEvent = __DARKLUA_BUNDLE_MODULES.load('o')
        local StartFarmingHandler = {}
        local playerData = DataService:GetData()
        local localPlayer = Players.LocalPlayer
        local playerGui = localPlayer:WaitForChild('PlayerGui')
        local confirmSprinker = (playerGui:WaitForChild('ConfirmSprinkler'))
        local autoFarmDebouce = false
        local rng = Random.new()
        local startingTime = DateTime.now().UnixTimestamp
        local startingSheckles
        local USE_SELECTED_PETS_ONLY = getgenv().CONFIGS.USE_SELECTED_PETS_ONLY
        local SELECTED_FARMING_PETS = getgenv().CONFIGS.SELECTED_FARMING_PETS
        local EGGS_NOT_TO_BUY = getgenv().CONFIGS.EGGS_NOT_TO_BUY
        local PETS_TO_KEEP = getgenv().CONFIGS.PETS_TO_KEEP
        local currentCamera = Workspace.CurrentCamera
        local viewportSize = currentCamera.ViewportSize
        local myFarmPlot = FarmPlotPath.GetFarmPlotFor(localPlayer)
        local important = myFarmPlot:WaitForChild('Important')
        local plantLocations = important:WaitForChild('Plant_Locations')
        local plantsPhysical = important:WaitForChild('Plants_Physical')
        local objectsPhysical = important:WaitForChild('Objects_Physical')
        local centerPoint = (myFarmPlot:WaitForChild('Center_Point'))
        local seedsToFarm = {}
        local petSlots = {}
        local plantsTotal
        local MAX_PET_LEVEL = getgenv().CONFIGS.PET_MAX_LEVEL or 100
        local setTimeLabelText = function()
            local currentTime = DateTime.now().UnixTimestamp
            local timeElapsed = currentTime - startingTime

            GuiClass.SetTextTimer(string.format('\u{23f1}\u{fe0f} %s', tostring(Utils.FormatTime(timeElapsed))))
        end
        local setShecklesDiff = function()
            return playerData.Sheckles - startingSheckles
        end
        local updateGui = function()
            GuiClass.SetTextSheckles(string.format('\u{1f4b8} Sheckles: %s (%s)', tostring(Utils.FormatNumber(playerData.Sheckles)), tostring(Utils.FormatNumber(setShecklesDiff()))))
            GuiClass.SetTextPetsEquipped(string.format('\u{1f436} %s/%s', tostring(#Pets.GetAllPetsCurrentlyFarming()), tostring(Pets.GetMaxEquippedPets())) .. string.format('| \u{1f95a} %s/%s', tostring(Pets.GetAmountOfEggsPlanted(objectsPhysical)), tostring(Pets.GetMaxEggsCanFarm())))
            GuiClass.SetTextPetsInInventory(string.format('\u{1f392} Pets backpack: %s/%s ', tostring(Pets.GetAmountOfPetsInInventory()), tostring(Pets.GetMaxPetsInInventory())) .. string.format('| Fruits: %s/%s ', tostring(Inventory.GetAmountOfFruits()), tostring(Inventory.GetMaxBackpackHold())))
            GuiClass.SetTextPlantsPlanted(string.format('\u{1f334} Plants Planted: %s/800', tostring(plantsTotal or 0)))
        end

        local function getRandomDirtPart()
            local dirtParts = plantLocations:GetChildren()
            local dirt = (dirtParts[rng:NextInteger(1, #dirtParts)])

            if not dirt then
                task.wait(1)
                getRandomDirtPart()
            end

            return dirt
        end

        local autoFarm = function()
            if autoFarmDebouce then
                return
            end

            autoFarmDebouce = true

            local dirtPart = getRandomDirtPart()

            plantsTotal = #plantsPhysical:GetChildren()

            Utils.PrintDebug(string.format('how many crops planted: %s', tostring(plantsTotal)))

            if plantsTotal >= 100 then
                Utils.PrintDebug('has TOO many crops planted: ' .. plantsTotal .. ', removing..')
                FarmPlot.RemovePlantsNotInTable(seedsToFarm, plantsPhysical)
            end

            local seedTool = FarmPlot.GetSeed(seedsToFarm)

            if plantsTotal <= 600 and seedTool then
                Utils.TeleportPlayerTo(centerPoint)
                FarmPlot.LoopPlantingSameSeed(seedTool, dirtPart)
            end
            if not PlayerStage.IsNewPlayer then
                GearPlantable.EquipAndPlantGearTools(centerPoint, dirtPart)
            end
            if FarmPlot.HasEggToPlant(EGGS_NOT_TO_BUY) and not Pets.IsMaxEggPlanted() then
                Utils.TeleportPlayerTo(centerPoint)
                FarmPlot.GetEggToolandPlant(EGGS_NOT_TO_BUY, dirtPart)
            end

            local maxPets = Pets.IsMaxPetsInInventory()

            if not maxPets then
                Pets.HatchPets()
            end

            FarmPlot.HarvestPlants(seedsToFarm, PlayerStage.IsNewPlayer, false)

            if USE_SELECTED_PETS_ONLY then
                for _, uuid in Pets.GetAllPetsCurrentlyFarming()do
                    local petInfo = Pets.GetPetDataFor(uuid)

                    if table.find(SELECTED_FARMING_PETS, petInfo.PetType) then
                        if petInfo.PetData.Level >= MAX_PET_LEVEL then
                            Pets.RemovePetFromFarm(uuid)
                            task.wait(1)
                        elseif petInfo.PetData.Hunger < (Pets.GetPetDefaultHunger(petInfo.PetType) / 2) then
                            repeat
                                local fruitTool = Inventory.GetFruitModel()

                                if fruitTool then
                                    Utils.GetHumanoid():EquipTool(fruitTool)
                                    task.wait(1)
                                    Pets.FeedPet(uuid)
                                    Utils.PrintDebug(string.format('Fed pet?: %s', tostring(petInfo.PetData.Name)))
                                end

                                task.wait()
                            until petInfo.PetData.Hunger >= Pets.GetPetDefaultHunger(petInfo.PetType) - 50 or not fruitTool
                        end
                    else
                        Pets.RemovePetFromFarm(uuid)
                        task.wait(1)
                    end
                end
            end
            if not Pets.IsMaxPetsEquipped() then
                local petUUID

                if USE_SELECTED_PETS_ONLY then
                    petUUID = Pets.GetHighestPetUUIDWithCapAndName(MAX_PET_LEVEL, SELECTED_FARMING_PETS)
                else
                    petUUID = Pets.GetHighestPetUUIDWithCap(MAX_PET_LEVEL)
                end
                if petUUID then
                    if not Utils.IsCharacterAtLocation(centerPoint, 1) then
                        Utils.TeleportPlayerTo(centerPoint)
                    end

                    Pets.PlacePetToFarm(petUUID, dirtPart.CFrame)
                end
            end

            Utils.GetHumanoid():UnequipTools()

            if PlayerStage.IsNewPlayer then
                FarmPlot.HarvestPlants(seedsToFarm, PlayerStage.IsNewPlayer, true)
                Utils.PrintDebug('Is new player so selling everything')
                Shops.SellAllInventory()
            else
                Shops.SellAllInventory()
                task.wait(1)
            end

            Pets.TryEligiblePetForExtraSlots({
                'Starfish',
            })

            if DinoEvent.IsDinoEggReady() then
                Utils.PrintDebug('Dino Egg is ready to be picked up')
                DinoEvent.ClaimReward()
                task.wait(1)
            end
            if not DinoEvent.IsDinoMachineRunning() then
                local petUUID = Pets.GetUUIDPetForDinoMachine(PETS_TO_KEEP)

                if petUUID then
                    local petTool = Pets.GetPetToolByUUID(petUUID)

                    Utils.PrintDebug(string.format('DinoEvent: petTool %s', tostring(petTool)))

                    if petTool then
                        Utils.GetHumanoid():EquipTool(petTool)
                        Utils.WaitForToolToEquip(10)
                        DinoEvent.GivePetToMachine()
                        Utils.PrintDebug('Gave pet to turn into egg')
                    end
                end
            end
            if Pets.GetAmountOfPetsInInventory() >= Pets.GetMaxPetsInInventory() then
                Utils.PrintDebug('Pet Backpack is full...')
                Pets.SellUnWantedPets(PETS_TO_KEEP)
                Utils.PrintDebug('Sold all pets except pets in PETS_TO_KEEP')
            end

            local seedPack = Inventory.GetSeedPackInventory()

            if seedPack then
                Shops.OpenSeedPack(seedPack)
            end

            autoFarmDebouce = false
        end

        function StartFarmingHandler.Init()
            confirmSprinker:GetPropertyChangedSignal('Enabled'):Connect(function(
            )
                if not confirmSprinker.Enabled then
                    return
                end
                if not confirmSprinker:WaitForChild('Frame', 10) then
                    return
                end

                local confirmButton = (confirmSprinker.Frame:WaitForChild('Confirm', 10))

                if not confirmButton then
                    return
                end

                task.wait(1)
                firesignal((confirmButton.MouseButton1Click))
                Utils.PrintDebug('Fired button')
            end)
            localPlayer:GetAttributeChangedSignal('SessionTime'):Connect(setTimeLabelText)
        end
        function StartFarmingHandler.Start()
            local queueOnTeleport = (syn and syn.queue_on_teleport) or queue_on_teleport

            if queueOnTeleport then
                queueOnTeleport('\r\n            game:Shutdown()\r\n        ')
            end

            for _, v in getconnections((localPlayer.Idled))do
                v:Disable()
            end

            for _ = 1, 3 do
                VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 1)
            end

            startingSheckles = playerData.Sheckles

            updateGui()

            getgenv().AutoFarm = coroutine.create(function()
                while true do
                    for index, uuid in Pets.GetAllPetsCurrentlyFarming()do
                        local petInfo = Pets.GetPetDataFor(uuid)
                        local slot = petSlots[index]

                        if slot then
                            slot:SetText(string.format('%s lvl: %s', tostring(petInfo.PetType), tostring(petInfo.PetData.Level)))
                        else
                            local newSlot = GuiClass.new(tostring(petSlots[index]))

                            newSlot:SetText(string.format('%s lvl: %s', tostring(petInfo.PetType), tostring(petInfo.PetData.Level)))
                            table.insert(petSlots, newSlot)
                        end
                    end

                    seedsToFarm = PlayerStage.GetSeedNamesToFarm()

                    Shops.BuySeeds(seedsToFarm)
                    Shops.BuyGears()
                    Shops.BuyEggs(EGGS_NOT_TO_BUY)
                    Utils.PrintDebug('Starting AutoFarm')
                    autoFarm()
                    Utils.PrintDebug('Updating Gui')
                    updateGui()
                    Utils.PrintDebug('Waiting for 60 secs')
                    task.wait(60)
                end
            end)

            coroutine.resume(getgenv().AutoFarm)
        end

        return StartFarmingHandler
    end
end

if not game:IsLoaded() then
    game.Loaded:Wait()
end
if game.PlaceId ~= 126884695634066 then
    return
end

local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
local files = {
    {
        WebhookHandler = __DARKLUA_BUNDLE_MODULES.load('b'),
    },
    {
        PetTradingHandler = __DARKLUA_BUNDLE_MODULES.load('e'),
    },
    {
        StartFarmingHandler = __DARKLUA_BUNDLE_MODULES.load('p'),
    },
}

Utils.PrintDebug('----- INITIALIZING MODULES -----')

for index, _table in ipairs(files)do
    for moduleName, _ in _table do
        if files[index][moduleName].Init then
            Utils.PrintDebug(string.format('INITIALIZING: %s', tostring(moduleName)))
            files[index][moduleName].Init()
            task.wait(1)
        end
    end
end

Utils.PrintDebug('----- STARTING MODULES -----')

for index, _table in ipairs(files)do
    for moduleName, _ in _table do
        if files[index][moduleName].Start then
            Utils.PrintDebug(string.format('STARTING: %s', tostring(moduleName)))
            files[index][moduleName].Start()
            task.wait(1)
        end
    end
end

Utils.PrintDebug('done')
