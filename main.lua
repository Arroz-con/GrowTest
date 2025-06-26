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

        return Utils
    end
    function __DARKLUA_BUNDLE_MODULES.b()
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
    function __DARKLUA_BUNDLE_MODULES.c()
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
    function __DARKLUA_BUNDLE_MODULES.d()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Pets = {}
        local localPlayer = Players.LocalPlayer
        local backPack = localPlayer:WaitForChild('Backpack')
        local playerData = DataService:GetData()
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local petsToKeep = {
            'Chicken',
            'Rooster',
        }
        local eggRarityPetsSell = {
            'Common Egg',
            'Common Summer Egg',
            'Uncommon Egg',
            'Rare Egg',
            'Rare Summer Egg',
        }

        function Pets.SellPet(petModel)
            gameEventsFolder.SellPet_RE:FireServer(petModel)
        end
        function Pets.IsMaxPetsInInventory()
            local maxPets = playerData.PetsData.MutableStats.MaxPetsInInventory
            local count = 0

            for uuid, value in playerData.PetsData.PetInventory.Data do
                count = count + 1
            end

            return count >= maxPets and true or false
        end
        function Pets.HatchPets(folder)
            for _, model in folder:GetChildren()do
                if not model:IsA('Model') then
                    continue
                end
                if model:GetAttribute('OBJECT_TYPE') ~= 'PetEgg' then
                    continue
                end

                local prompt = model:FindFirstChild('ProximityPrompt', true)

                if prompt and prompt:IsA('ProximityPrompt') and prompt.Enabled then
                    gameEventsFolder.PetEggService:FireServer('HatchPet', model)
                    Utils.PrintDebug('hatched egg?')
                end
            end
        end
        function Pets.IsMaxEggPlanted(folder)
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

            if count >= playerData.PetsData.MutableStats.MaxEggsInFarm then
                return true
            end

            return false
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
        function Pets.PlacePetToFarm(petUUID, position)
            gameEventsFolder.PetsService:FireServer('EquipPet', petUUID, position)
            task.wait(2)
        end
        function Pets.GetHighestPetUUIDWithCap(MaxLevel)
            local petUUID
            local petLevel = 0

            for uuid, v in playerData.PetsData.PetInventory.Data do
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
            return playerData.PetsData.PetInventory.Data[petUUID].PetData
        end
        function Pets.GetUUIDPetsToSell()
            local sellList = {}

            for uuid, value in playerData.PetsData.PetInventory.Data do
                if table.find(petsToKeep, value.PetType) then
                    continue
                end
                if not table.find(eggRarityPetsSell, value.PetData.HatchedFrom) then
                    continue
                end
                if value.PetData.BaseWeight > 15 then
                    continue
                end

                table.insert(sellList, uuid)
            end

            return sellList
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

        return Pets
    end
    function __DARKLUA_BUNDLE_MODULES.e()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local ByteNetRemotes = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('Remotes')))
        local InventoryService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('InventoryService')))
        local MutationHandler = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('MutationHandler')))
        local ToolHandle = __DARKLUA_BUNDLE_MODULES.load('c')
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('b')
        local Pets = __DARKLUA_BUNDLE_MODULES.load('d')
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
                if forceHarvestFruit or isNewPlayer or FarmPlot.IsFruitNormalVariant(model) or FarmPlot.MutationCountFor(model) > 3 then
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
                    gameEventsFolder.Remove_Item:FireServer(fruitModel.PrimaryPart)
                    task.wait(0.1)
                end
            end
        end
        function FarmPlot.IsFruitNormalVariant(fruitModel)
            local variant = (fruitModel:WaitForChild('Variant'))

            if variant.Value == 'Normal' then
                return true
            end

            return false
        end
        function FarmPlot.MutationCountFor(fruitModel)
            local count = 0

            for name, value in fruitModel:GetAttributes()do
                if MutationHandler.MutationNames[name] then
                    count = count + 1
                end
            end

            return count
        end
        function FarmPlot.HarvestPlants(folder, isNewPlayer, forceHarvestFruit)
            for _, plantModel in folder:GetChildren()do
                if not plantModel:IsA('Model') then
                    continue
                end

                local fruitsFolder = plantModel:FindFirstChild('Fruits')

                if fruitsFolder then
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
        function FarmPlot.GetEggToolandPlant(eggsNotToPlant, dirtPart, folder)
            for _, eggTool in playerBackpack:GetChildren()do
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
                    until not eggTool.Parent or Pets.IsMaxEggPlanted(folder) or eggTool:GetAttribute('LocalUses') <= 0
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
    function __DARKLUA_BUNDLE_MODULES.f()
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
    function __DARKLUA_BUNDLE_MODULES.g()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local SeedLimits = __DARKLUA_BUNDLE_MODULES.load('f')
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
        function Inventory.GetFruitUUID()
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
        function Inventory.GetFruitModel()
            local fruitUUID = Inventory.GetFruitUUID()

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

        return Inventory
    end
    function __DARKLUA_BUNDLE_MODULES.h()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Workspace = game:GetService('Workspace')
        local DataService = (require(ReplicatedStorage:WaitForChild('Modules'):WaitForChild('DataService')))
        local SeedData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('SeedData')))
        local GearData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('GearData')))
        local PetEggData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('PetEggData')))
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Inventory = __DARKLUA_BUNDLE_MODULES.load('g')
        local Shops = {}
        local playerData = DataService:GetData()
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
                task.wait(5)
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
        function Shops.BuyGears(tbl)
            for name, gear in playerData.GearStock.Stocks do
                if not table.find(tbl, name) then
                    continue
                end

                loopBuyAllofSameItem(GearData, gameEventsFolder.BuyGearStock, name, gear)
                Utils.PrintDebug(string.format('Bought gear: %s, stock left: %s', tostring(name), tostring(gear.Stock)))
            end
        end

        return Shops
    end
    function __DARKLUA_BUNDLE_MODULES.i()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local SeedData = (require(ReplicatedStorage:WaitForChild('Data'):WaitForChild('SeedData')))
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('b')
        local PlayerStage = {}

        PlayerStage.IsNewPlayer = false
        PlayerStage.CanPlaceSprinker = false

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

            if getRarityPlantedCount('Divine') >= 10 then
                PlayerStage.CanPlaceSprinker = true
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                    'Divine',
                }
            elseif getRarityPlantedCount('Mythical') >= 10 then
                PlayerStage.CanPlaceSprinker = true
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                    'Divine',
                    'Mythical',
                }
            elseif getRarityPlantedCount('Legendary') >= 10 then
                PlayerStage.CanPlaceSprinker = false
                PlayerStage.IsNewPlayer = false
                newTable = {
                    'Prismatic',
                    'Divine',
                    'Mythical',
                    'Legendary',
                }
            elseif getRarityPlantedCount('Rare') >= 0 then
                PlayerStage.CanPlaceSprinker = false
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

        function PlayerStage.GetNamesToFarm()
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
    function __DARKLUA_BUNDLE_MODULES.j()
        local ReplicatedStorage = game:GetService('ReplicatedStorage')
        local Players = game:GetService('Players')
        local ToolHandle = __DARKLUA_BUNDLE_MODULES.load('c')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Sprinklers = {}
        local localPlayer = Players.LocalPlayer
        local gameEventsFolder = (ReplicatedStorage:WaitForChild('GameEvents'))
        local playerBackpack = localPlayer:WaitForChild('Backpack')

        function Sprinklers.PlantSprinkler(position)
            local newPosition = position + Vector3.new(0, 0.135, 0)

            gameEventsFolder.SprinklerService:FireServer('Create', newPosition)
            Utils.PrintDebug('Placed Sprinkler?')
        end
        function Sprinklers.HasSprinklerToPlant(tbl)
            for _, v in playerBackpack:GetChildren()do
                if not v:IsA('Tool') then
                    continue
                end

                local toolName = v:GetAttribute('f')

                if toolName and typeof(toolName) == 'string' and table.find(tbl, toolName) then
                    return v
                end
            end

            return nil
        end
        function Sprinklers.IsSprinklerAlreadyPlanted(folder, tbl)
            for i, v in folder:GetChildren()do
                if not v:IsA('Model') then
                    continue
                end
                if not table.find(tbl, v.Name) then
                    continue
                end

                return true
            end

            return false
        end
        function Sprinklers.EquipSprinkerAndPlant(tbl, dirtPart)
            local tool = Sprinklers.HasSprinklerToPlant(tbl)

            if not tool then
                return
            end
            if not ToolHandle.EquipTool(tool.Name) then
                return
            end

            task.wait(2)
            Sprinklers.PlantSprinkler(dirtPart.CFrame)
        end

        return Sprinklers
    end
    function __DARKLUA_BUNDLE_MODULES.k()
        local Players = game:GetService('Players')
        local VirtualInputManager = game:GetService('VirtualInputManager')
        local Workspace = game:GetService('Workspace')
        local FarmPlotPath = __DARKLUA_BUNDLE_MODULES.load('b')
        local FarmPlot = __DARKLUA_BUNDLE_MODULES.load('e')
        local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
        local Shops = __DARKLUA_BUNDLE_MODULES.load('h')
        local Inventory = __DARKLUA_BUNDLE_MODULES.load('g')
        local Pets = __DARKLUA_BUNDLE_MODULES.load('d')
        local PlayerStage = __DARKLUA_BUNDLE_MODULES.load('i')
        local Sprinklers = __DARKLUA_BUNDLE_MODULES.load('j')
        local self = {}
        local localPlayer = Players.LocalPlayer
        local playerGui = localPlayer:WaitForChild('PlayerGui')
        local confirmSprinker = (playerGui:WaitForChild('ConfirmSprinkler'))
        local autoFarmDebouce = false
        local rng = Random.new()
        local currentCamera = Workspace.CurrentCamera
        local viewportSize = currentCamera.ViewportSize
        local myFarmPlot = FarmPlotPath.GetFarmPlotFor(localPlayer)
        local important = myFarmPlot:WaitForChild('Important')
        local plantLocations = important:WaitForChild('Plant_Locations')
        local plantsPhysical = important:WaitForChild('Plants_Physical')
        local objectsPhysical = important:WaitForChild('Objects_Physical')
        local centerPoint = (myFarmPlot:WaitForChild('Center_Point'))
        local seedsToFarm = {}
        local gearList = {
            'Advanced Sprinkler',
            'Godly Sprinkler',
            'Master Sprinkler',
            'Tanning Mirror',
        }
        local eggsNotToBuy = {
            'Common Egg',
            'Uncommon Egg',
            'Common Summer Egg',
        }
        local MAX_PET_LEVEL = 75

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
            local seedTool = FarmPlot.GetSeed(seedsToFarm)

            if seedTool then
                Utils.TeleportPlayerTo(centerPoint)
                FarmPlot.LoopPlantingSameSeed(seedTool, dirtPart)
            end
            if PlayerStage.CanPlaceSprinker and Sprinklers.HasSprinklerToPlant(gearList) and not Sprinklers.IsSprinklerAlreadyPlanted(objectsPhysical, gearList) then
                Utils.TeleportPlayerTo(centerPoint)
                Sprinklers.EquipSprinkerAndPlant(gearList, dirtPart)
            end

            FarmPlot.HarvestPlants(plantsPhysical, PlayerStage.IsNewPlayer, false)

            local maxPets = Pets.IsMaxPetsInInventory()

            if not maxPets and FarmPlot.HasEggToPlant(eggsNotToBuy) and not Pets.IsMaxEggPlanted(objectsPhysical) then
                Utils.TeleportPlayerTo(centerPoint)
                FarmPlot.GetEggToolandPlant(eggsNotToBuy, dirtPart, objectsPhysical)
            end
            if not maxPets then
                Pets.HatchPets(objectsPhysical)
            end
            if not Pets.IsMaxPetsEquipped() then
                local petUUID = Pets.GetHighestPetUUIDWithCap(MAX_PET_LEVEL)

                if petUUID then
                    if not Utils.IsCharacterAtLocation(centerPoint, 1) then
                        Utils.TeleportPlayerTo(centerPoint)
                    end

                    Pets.PlacePetToFarm(petUUID, centerPoint.CFrame)
                end
            end

            for _, uuid in Pets.GetAllPetsCurrentlyFarming()do
                local petData = Pets.GetPetDataFor(uuid)

                if petData.Hunger < 500 then
                    local fruitTool = Inventory.GetFruitModel()

                    if fruitTool then
                        Utils.GetHumanoid():EquipTool(fruitTool)
                        task.wait(2)
                        Pets.FeedPet(uuid)
                        Utils.PrintDebug(string.format('Fed pet?: %s', tostring(petData.Name)))
                    end
                elseif petData.Level >= MAX_PET_LEVEL then
                    Pets.RemovePetFromFarm(uuid)
                    task.wait(1)
                end
            end

            if FarmPlot.IsRmoveablePlantInGarden(seedsToFarm, plantsPhysical) then
                FarmPlot.HarvestPlants(plantsPhysical, PlayerStage.IsNewPlayer, true)
                FarmPlot.RemovePlantsNotInTable(seedsToFarm, plantsPhysical)
            end

            Utils.GetHumanoid():UnequipTools()
            Shops.SellAllInventory()

            if not Utils.IsCharacterAtLocation(centerPoint, 1) then
                Utils.TeleportPlayerTo(centerPoint)
            end

            local plantsTotal = #plantsPhysical:GetChildren()

            Utils.PrintDebug('how many crops planted: ' .. plantsTotal)

            autoFarmDebouce = false
        end

        function self.Init()
            getgenv().Connections.confirmSprinker = confirmSprinker:GetPropertyChangedSignal('Enabled'):Connect(function(
            )
                if not confirmSprinker.Enabled then
                    return
                end

                confirmSprinker:WaitForChild('Frame')

                local confirmButton = (confirmSprinker.Frame:WaitForChild('Confirm'))

                task.wait(1)
                firesignal((confirmButton.MouseButton1Click))
                Utils.PrintDebug('Fired button')
            end)
        end
        function self.Start()
            for _, v in getconnections((localPlayer.Idled))do
                v:Disable()
            end

            for _ = 1, 3 do
                VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, true, game, 1)
                task.wait(0.1)
                VirtualInputManager:SendMouseButtonEvent(viewportSize.X / 2, viewportSize.Y / 2, 0, false, game, 1)
            end

            getgenv().AutoFarm = coroutine.create(function()
                while true do
                    seedsToFarm = PlayerStage.GetNamesToFarm()

                    Shops.BuySeeds(seedsToFarm)
                    Shops.BuyGears(gearList)
                    Shops.BuyEggs(eggsNotToBuy)
                    autoFarm()
                    task.wait(60)
                end
            end)

            coroutine.resume(getgenv().AutoFarm)
        end

        return self
    end
end

getgenv().Connections = {}

if not game:IsLoaded() then
    game.Loaded:Wait()
end
if game.PlaceId ~= 126884695634066 then
    return
end

getgenv().DEBUG_MODE = false

local Utils = __DARKLUA_BUNDLE_MODULES.load('a')
local files = {
    {
        StartFarmingHandler = __DARKLUA_BUNDLE_MODULES.load('k'),
    },
}

Utils.PrintDebug('----- INITIALIZING MODULES -----')

for index, _table in ipairs(files)do
    for moduleName, _ in _table do
        if files[index][moduleName].Init then
            Utils.PrintDebug(string.format('INITIALIZING: %s', tostring(moduleName)))
            files[index][moduleName].Init()
            task.wait(2)
        end
    end
end

Utils.PrintDebug('----- STARTING MODULES -----')

for index, _table in ipairs(files)do
    for moduleName, _ in _table do
        if files[index][moduleName].Start then
            Utils.PrintDebug(string.format('STARTING: %s', tostring(moduleName)))
            files[index][moduleName].Start()
            task.wait(2)
        end
    end
end

Utils.PrintDebug('done')
