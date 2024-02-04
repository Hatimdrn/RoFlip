
-- Services

local HTTPService = game:GetService("HttpService")

-- Values

local Token = "4bb22d00-28aa-40ab-bc65-c651d77c3ccd"

local Trading = false

local Items

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

--local function UpdateWithdrawQueue()

--	local Request = HTTPService:RequestAsync(

--		{

--			Method = "GET",
--			Url = "https://roflip.org/api/public/withdrawal/getAllIncoming",
--			Headers = {
--				["X-API-KEY"] = Token
--			}

--		}

--	)

--	if Request.StatusCode == 200 then

--		for _, Data in pairs(HTTPService:JSONDecode(Request.Body)) do

--			table.insert(WithdrawQueue, Data)

--		end

--	end

--end

-- Lets go!

ChatSay("RoFlip | Bot is now starting...")

_G.RoFlipBot = true

wait(2)

_G.RoFlipBot = false

Items = HTTPService:JSONDecode(HTTPService:GetAsync("https://raw.githubusercontent.com/AlreadyMAKS/RoFlip/main/items.json"))

print(Items)

local c

c = TradeRequestFrame:GetPropertyChangedSignal("Visible"):Connect(function()

	if TradeRequestFrame.Visible == true and not Trading then

		local Player = game.Players:FindFirstChild(TradeRequestFrame.ReceivingRequest.Username.Text)

		if Player then

			--local RoFlipId = HTTPService:GetAsync("https://roflip.org/api/v1/user/getByRolboxId/"..tostring(Player.UserId))

			local RoFlipId = 4

			--if RoFlipId.Body then

			--	local RoFlipId = tonumber(HTTPService:JSONDecode(RoFlipId.Body).id)

			--else

			--	TradeRemotes.CancelRequest:FireServer()

			--	ChatSay("RoFlip | Can't find "..Player.Name.."'s RoFlip account")

			--	return

			--end

			ChatSay("RoFlip | Trading with "..Player.Name)

			wait(0.2)

			TradeRemotes.AcceptRequest:FireServer()

			Trading = true

			local InputItems = {}

			wait(1)

			local Connection

			Connection = PlayerGui.TradeGUI.Container.Trade.TheirOffer.Accepted:GetPropertyChangedSignal("Visible"):Connect(function()
				
				local Corrupted = false

				if PlayerGui.TradeGUI.Container.Trade.TheirOffer.Accepted.Visible == true then

					Connection:Disconnect()

					for _, Item in pairs(PlayerGui.TradeGUI.Container.Trade.TheirOffer.Container:GetChildren()) do

						if Item:IsA("Frame") then

							if Item.Visible == true then

								if Item.Container.Amount.Text == "" then

									local ID = GetItemIdByName(Item.ItemName.Label.Text)
									
									if ID == nil then
										
										Corrupted = true
										
										ChatSay("RoFlip | Bot doesn't accept "..Item.ItemName.Label.Text)
										
										TradeRemotes.DeclineTrade:FireServer()
										
									end

									table.insert(InputItems,ID)

								else

									local s = Item.Container.Amount.Text

									local Amount = tonumber(string.sub(s,2,s:len()))

									local ID = GetItemIdByName(Item.ItemName.Label.Text)
									
									if ID == nil then
										
										Corrupted = true

										ChatSay("RoFlip | Bot doesn't accept "..Item.ItemName.Label.Text)

										TradeRemotes.DeclineTrade:FireServer()

									end

									for i=1,Amount do

										table.insert(InputItems,ID)

									end

								end

							end

						end

					end

					if not Corrupted then
						
						TradeRemotes.AcceptTrade:FireServer()

						AddItems(RoFlipId, InputItems)
						
					end
					
					wait(5)
					
					ChatSay("RoFlip | Ready for trade")
					
					Trading = false

				end

			end)

		end

	end

end)

ChatSay("RoFlip | Bot started")

spawn(function()

	while wait(0.1) do

		if _G.FAF == true then

			c:Disconnect()

			break

		end

	end

end)
