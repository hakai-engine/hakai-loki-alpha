local promotionManager = {}

local promotionsPath = CORE_DIRECTORY .. "/modules/scripts/gamestore/store_promotions.lua"

local function loadCampaigns()
	local environment = {}
	local chunk, loadError = loadfile(promotionsPath, "t", environment)
	if not chunk then
		return {}
	end

	local ok, document = pcall(chunk)
	if not ok or type(document) ~= "table" or type(document.campaigns) ~= "table" then
		logger.error("[GameStore Promotions] Invalid campaign file: {}", ok and "campaigns table missing" or document)
		return {}
	end
	return document.campaigns
end

local function restoreCatalogOffer(offer)
	if offer._catalogPrice == nil then
		offer._catalogPrice = offer.price
		offer._catalogState = offer.state
		offer._catalogBasePrice = offer.basePrice
	end

	offer.price = offer._catalogPrice
	offer.state = offer._catalogState
	offer.basePrice = offer._catalogBasePrice
	offer.saleStartsAt = nil
	offer.saleEndsAt = nil
end

function promotionManager.apply(offer)
	if type(offer) ~= "table" or type(offer.id) ~= "number" then
		return offer
	end

	restoreCatalogOffer(offer)
	local campaign = loadCampaigns()[offer.id]
	if type(campaign) ~= "table" or campaign.enabled ~= true then
		return offer
	end

	local now = os.time()
	local startsAt = tonumber(campaign.startsAt) or 0
	local endsAt = tonumber(campaign.endsAt) or 0
	local price = tonumber(campaign.price)
	local basePrice = tonumber(campaign.basePrice) or offer._catalogPrice

	if startsAt > now or endsAt <= now or not price or price < 0 or basePrice <= price then
		return offer
	end

	offer.price = math.floor(price)
	offer.basePrice = math.floor(basePrice)
	offer.state = GameStore.States.STATE_SALE
	offer.saleStartsAt = startsAt
	offer.saleEndsAt = endsAt
	return offer
end

function promotionManager.getPath()
	return promotionsPath
end

return promotionManager
