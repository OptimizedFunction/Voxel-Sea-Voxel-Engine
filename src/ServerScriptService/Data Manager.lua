--!nocheck

local data_manager = {}

local config = require(game:GetService("ReplicatedStorage")["VoxelSea 2.0"].Modules.Configuration)

local http_service = game:GetService("HttpService")
local DS_service = game:GetService('DataStoreService')
local DS = DS_service:GetDataStore('WorldSaves')

local max_retry_count : number = script:GetAttribute('max_retry_count')
local retries = 0

function data_manager.SaveWorld(plr : Player, update_log : {})
	assert(plr:IsA('Player'), '[VOXARIA][Data Manager]: Argument #1 to SaveWorld() must be a player object!')
	assert(type(update_log) == 'table', '[VOXARIA][Data Manager]: Argument #3 to SaveWorld() must be a list!')
	
	local encoded_update_log = encodeUpdates(update_log)
	
	local function save()
		local old_save = DS:GetAsync(plr.PlayerId)

		local data_table = {
			['updateLog'] = encoded_update_log;
		}

		if not old_save then
			DS:SetAsync(plr.PlayerId, data_table)
		elseif old_save then
			
			local function update_data(old_data)
				old_data['updateLog'] = encoded_update_log
				if #encoded_update_log < old_data['updateLog'] then 
					error('New save is possibly corrupted!') 
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

function data_manager.GetWorldSave(plr : Player) : ({} | nil)
	assert(plr:IsA('Player'), '[VOXARIA][Data Manager]: Argument #1 to GetWorldSave() must be a player object!')
	
	local function load()
		local save = DS:GetAsync(plr.PlayerId)
		if save then
			return decodeUpdates(save['updateLog'])
		else 
			return nil
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

--Encodes the update_log to allow for saving by the Data Manager. [Incomplete. Need custom RLE]
function encodeUpdates(update_log : {}) : string
	local encoded_update_log = {} 

	for pos, update_log_partition in pairs(update_log) do
		encoded_update_log[pos] = {}
		local curr_encoded_part = encoded_update_log[pos]
		local current = 0
		local next_index = 0
		local runLength = 1

		for i, voxelIndex in pairs(update_log_partition) do
			current = voxelIndex
			next_index = update_log_partition[i+1] or -1

			if next_index == current then
				runLength += 1
				continue	
			else
				if runLength > 1 then
					curr_encoded_part[#curr_encoded_part + 1] = {runLength, current}
				else
					curr_encoded_part[#curr_encoded_part + 1] = current
				end

				runLength = 1
			end

			current = next_index
		end

	end

	local encoded_string = http_service:JSONEncode(encoded_update_log)
	return encoded_string
end

function decodeUpdates(encoded_string : string) : {}
	local chunk_size = config.GetChunkSize()
	local vert_chunk_size = config.GetVertChunkSize()
	local decoded_log = {}

	local encoded_log = http_service:JSONDecode(encoded_string)
	for pos, encoded_log_part in encoded_log do

		decoded_log[pos] = table.create(chunk_size^2 * vert_chunk_size)
		local decoded_log_part = decoded_log[pos]

		for i,v in encoded_log_part do
			if type(v) == "number" then
				decoded_log_part[#decoded_log_part+1] = v
			else
				for j = 1, v[1] do
					decoded_log_part[#decoded_log_part+1] = v[2]
				end
			end
		end

	end

	return decoded_log
end

return data_manager
