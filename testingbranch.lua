
repeat wait() until game:IsLoaded() 

-- Services

local HTTPService = game:GetService("HttpService")

-- Values

local Token = "4bb22d00-28aa-40ab-bc65-c651d77c3ccd"

local Trading = false

local Items
--local Overrides
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

--local function GetRealItemName(Name)

--	for RealName, Value in pairs(Overrides.Item) do

--		if Value.ItemName == Name then

--			return RealName

--		end

--	end

--end

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

	if Request.StatusCode == 200 then

		for _, Data in pairs(HTTPService:JSONDecode(Request.Body)) do

			local UserID = tostring(Data.user.id)

			if WithdrawQueue[UserID] == nil then

				WithdrawQueue[UserID] = {}

			end

			for _, Item in pairs(Data.user_items) do

				table.insert(WithdrawQueue[UserID], Item["item_id"])

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

--Overrides = game.ReplicatedStorage.GetSyncData:InvokeServer()

local InTradeItems = {}

game.ReplicatedStorage.Trade.UpdateTrade.OnClientEvent:Connect(function(Trade)

	InTradeItems = Trade.Player1.Offer

end)

local c

c = TradeRequestFrame:GetPropertyChangedSignal("Visible"):Connect(function()

	if TradeRequestFrame.Visible == true and not Trading then

		local Player = game.Players:FindFirstChild(TradeRequestFrame.ReceivingRequest.Username.Text)

		if Player then

			local RoFlipId = HTTPService:GetAsync("https://roflip.org/api/v1/user/getByRolboxId/"..Player.UserId)

			--local RoFlipId = 4

			if RoFlipId ~= nil then

				RoFlipId = tonumber(HTTPService:JSONDecode(RoFlipId).id)

				if RoFlipId == nil then

					TradeRemotes.CancelRequest:FireServer()

					ChatSay("RoFlip | Can't find "..Player.Name.."'s RoFlip account")

					return
	
				end

			else

				TradeRemotes.CancelRequest:FireServer()

				ChatSay("RoFlip | Can't find "..Player.Name.."'s RoFlip account")

				return

			end

			ChatSay("RoFlip | Trading with "..Player.Name)

			wait(0.2)

			TradeRemotes.AcceptRequest:FireServer()

			Trading = true

			if WithdrawQueue[tostring(RoFlipId)] and #WithdrawQueue[tostring(RoFlipId)] > 0 then -- if #WithdrawQueue[tostring(Player.UserId)] >= 1 then

				for i=1,4 do
					
					wait(0.1)

					TradeRemotes.OfferItem:FireServer(
						GetItemNameById(WithdrawQueue[tostring(RoFlipId)][i]),
						"Weapons"
					)

					table.remove(WithdrawQueue[tostring(RoFlipId)],i)

				end

			end

			local InputItems = {}

			wait(1)

			local Connection

			Connection = PlayerGui.TradeGUI.Container.Trade.TheirOffer.Accepted:GetPropertyChangedSignal("Visible"):Connect(function()

				local Corrupted = false

				if PlayerGui.TradeGUI.Container.Trade.TheirOffer.Accepted.Visible == true then

					Connection:Disconnect()

					for _, Item in pairs(InTradeItems) do

						local ID = GetItemIdByName(Item[1])

						if ID then

							local Amount = Item[2]

							if Amount <= 100 then

								for i=1, Amount do

									table.insert(InputItems,ID)

								end

							else

								ChatSay("RoFlip | Bot doesn't accept amounts more than 100")

								Corrupted = true

								TradeRemotes.DeclineTrade:FireServer()

							end

						else

							ChatSay("RoFlip | Bot doesn't accept "..Item[1])

							Corrupted = true

							TradeRemotes.DeclineTrade:FireServer()

						end

					end

					if not Corrupted then

						TradeRemotes.AcceptTrade:FireServer()

						AddItems(RoFlipId, InputItems)
						
						local ProccessingConnection

						wait(0.2)

						ProccessingConnection = TradeGUI.Processing.Changed:Connect(function()

							if TradeGUI.Processing.Visible == false then

								ChatSay("RoFlip | Ready for trade")

								Trading = false

								ProccessingConnection:Disconnect()

							end

						end)
						
					else
						
						ChatSay("RoFlip | Ready for trade")

						Trading = false

					end

				end

			end)

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

	while wait(3) do

		if _G.RoFlipBot == true then

			c:Disconnect()

			break

		else

			UpdateWithdrawQueue()

		end

	end

end)
