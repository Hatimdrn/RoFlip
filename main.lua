
repeat wait() until game:IsLoaded() 

-- Services

local HTTPService = game:GetService("HttpService")

-- Values

local Token = "4bb22d00-28aa-40ab-bc65-c651d77c3ccd"

local Items
local WithdrawQueue = {}

-- Links

local TradeRemotes = game.ReplicatedStorage.Trade

-- UI

local PlayerGui = game.Players.LocalPlayer.PlayerGui
local TradeRequestFrame = PlayerGui.MainGUI.Game.Leaderboard.Container.TradeRequest
local TradeGUI = PlayerGui.TradeGUI

-- Functions

local function ChatSay(Message)

	game.ReplicatedStorage:WaitForChild("DefaultChatSystemChatEvents").SayMessageRequest:FireServer(Message,"normalchat")

end

local function GetItemNameById(Id)

	for _,Item in pairs(Items) do

		if Item.ID == Id then

			return Item.ItemName

		end

	end

end

local function GetItemIdByName(Name)

	for _,Item in pairs(Items) do

		if Item.ItemName == Name then

			return Item.ID

		end

	end

end

local function AddItems(ID : number, Items : table)

	HTTPService:RequestAsync(

		{

			Method = "POST",
			Url = "https://roflip.org/api/public/user/"..ID.."/item/addAll",
			Headers = {
				["X-API-KEY"] = Token,
				["Content-Type"] = "application/json"
			},

			Body = HTTPService:JSONEncode({
				items_ids = Items
			})

		}

	)

end

local function UpdateWithdrawQueue()

	local Request = HTTPService:RequestAsync(

		{

			Method = "GET",
			Url = "https://roflip.org/api/public/withdrawal/getAllIncoming",
			Headers = {
				["X-API-KEY"] = Token
			}

		}

	)

    for _, Data in pairs(HTTPService:JSONDecode(Request.Body)) do

        local RoFlipId = tostring(Data["user"]["id"])

        if WithdrawQueue[RoFlipId] == nil then

            WithdrawQueue[RoFlipId] = {}

        end

        for _, Item in pairs(Data["user_items"]) do

            table.insert(WithdrawQueue[RoFlipId], Item["item_id"])

        end

    end

end

local function GetLocalIdFromUserId(UserId)
	
	local LocalId = HTTPService:GetAsync("https://roflip.org/api/v1/user/getByRolboxId/"..UserId)
	
	if LocalId ~= "" then
		
		local Raw = HTTPService:JSONDecode(LocalId)
		
		return tonumber(Raw["id"])
		
	end
	
	return 4
	
end

local function GetTypeFromId(Id) 
    
    for _, Item in pairs(Items) do

        if Item.ID == Id then

            if Item.Type == "Weapon" then
                
                return "Weapons"
                
            elseif Item.Type == "Pet" then
                
                return "Pets"
                
            end

        end

    end
    
end

-- Lets go!

ChatSay("RoFlip | Bot is now starting...")

_G.RoFlipBot = true

wait(2)

_G.RoFlipBot = false

Items = HTTPService:JSONDecode(HTTPService:GetAsync("https://raw.githubusercontent.com/AlreadyMAKS/RoFlip/main/items.json"))

-- After initialization

local CurrentTradeData = {
	
	Trading = false,
	User = nil,
	RoflipId = nil
	
}

TradeRemotes.DeclineTrade.OnClientEvent:Connect(function()
    
    if CurrentTradeData.Trading then
        
        CurrentTradeData = {

            Trading = false,
            User = nil,
            RoflipId = nil

        }
        
    end
    
    ChatSay("RoFlip | Ready for trade")
    
end)

TradeRemotes.SendRequest.OnClientInvoke = function(Sender)

	task.spawn(function()
        
        if CurrentTradeData.Trading == false then

            -- Finding user

            local RoFlipId = GetLocalIdFromUserId(Sender.UserId)

            if RoFlipId == nil then

                --TradeRemotes.CancelRequest:FireServer()

                ChatSay("RoFlip | Can't find "..Sender.Name.."'s RoFlip account")

                return

            end

            ChatSay("RoFlip | Trading with "..Sender.Name.. " (ID:"..RoFlipId..")")

            -- Binding user

            CurrentTradeData.Trading = true
            CurrentTradeData.User = Sender
            CurrentTradeData.RoflipId = RoFlipId
            
            TradeRemotes.AcceptRequest:FireServer()

            -- Withrawing items

            local ToWithdraw = WithdrawQueue[tostring(RoFlipId)]

            if ToWithdraw ~= nil and ToWithdraw ~= {} then

                for i=1,4 do

                    wait(0.1)

                    local Id = ToWithdraw[i]

                    TradeRemotes.OfferItem:FireServer(
                        GetItemNameById(Id),
                        GetTypeFromId(Id)
                    )

                    table.remove(ToWithdraw,i)

                end

            end

        end
        
    end)
    
    return require(game.ReplicatedStorage.Modules.TradeModule).RequestsEnabled

end

game.ReplicatedStorage.Trade.UpdateTrade.OnClientEvent:Connect(function(Trade)

	if CurrentTradeData.RoflipId ~= nil then
        
        if Trade.Player1.Accepted then

            local Items = {}

            for _, Item in pairs(Trade.Player1.Offer) do

                local ID = GetItemIdByName(Item[1])

                if ID then

                    local Amount = Item[2]

                    if Amount <= 100 then

                        for i=1, Amount do

                            table.insert(Items,ID)

                        end

                    else

                        ChatSay("RoFlip | Bot doesn't accept amounts more than 100")

                        TradeRemotes.DeclineTrade:FireServer()

                        return

                    end

                else

                    ChatSay("RoFlip | Bot doesn't accept "..Item[1])

                    TradeRemotes.DeclineTrade:FireServer()

                    return

                end

            end

            TradeRemotes.AcceptTrade:FireServer()

            AddItems(CurrentTradeData.RoflipId, Items)

            wait(5)

            ChatSay("RoFlip | Ready for trade")

            CurrentTradeData = {

                Trading = false,
                User = nil,
                RoflipId = nil

            }

        end
        
    end

end)

ChatSay("RoFlip | Bot started")

-- Anti Afk

game:GetService("Players").LocalPlayer.Idled:connect(function()

	game:GetService("VirtualUser"):ClickButton2(Vector2.new())

end)

-- Soft Updater

spawn(function()

	while wait(2) do

		if _G.RoFlipBot == true then

			TradeRemotes.SendRequest.OnClientInvoke = nil

			break

		else

			UpdateWithdrawQueue()

		end

	end

end)
