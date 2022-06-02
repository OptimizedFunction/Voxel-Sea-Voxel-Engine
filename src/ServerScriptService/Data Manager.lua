--!nocheck

local data_manager = {}

local DS_service = game:GetService('DataStoreService')
local DS = DS_service:GetDataStore('WorldSaves')

local max_retry_count : number = script:GetAttribute('max_retry_count')
local retries = 0

function data_manager.SaveWorld(plr : Player, update_log : {})
	assert(plr:IsA('Player'), '[VOXARIA][Data Manager]: Argument #1 to SaveWorld() must be a player object!')
	assert(type(update_log) == 'table', '[VOXARIA][Data Manager]: Argument #3 to SaveWorld() must be a list!')

	local function save()
		local old_save = DS:GetAsync(plr.PlayerId)

		local data_table = update_log

		if not old_save then
			DS:SetAsync(plr.PlayerId, data_table)
		elseif old_save then
			local function update_data(old_data)
				old_data['updateLog'] = update_log
				if #update_log < old_data['updateLog'] then 
					error('new save is possibly corrupted!') 
				end
				return old_data
			end
			DS:UpdateAsync(plr.PlayerId, data_table, update_data)
		end
	end
	
	local success, err = pcall(save)
	
	if success then 
		return true, nil
	elseif not success then
		if retries < max_retry_count then
			retries += 1
			data_manager.SaveWorld(plr, update_log)
		else
			retries = 0
			return false, err
		end
	end
end

function data_manager.GetWorldSave(plr : Player) : (number | nil, {} | nil)
	assert(plr:IsA('Player'), '[VOXARIA][Data Manager]: Argument #1 to GetWorldSave() must be a player object!')
	
	local function load()
		local save = DS:GetAsync(plr.PlayerId)
		if save then
			return save
		else 
			return
		end
	end
	
	local success, err = pcall(load)
	
	if success then 
		return true, nil
	elseif not success then
		if retries < max_retry_count then
			retries += 1
			data_manager.GetWorldSave(plr)
		else
			retries = 0
			return false, err
		end
	end
	
end

return data_manager
