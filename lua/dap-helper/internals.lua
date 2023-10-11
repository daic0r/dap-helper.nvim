local M = {}

local function get_config_path()
   return vim.fn.stdpath("data") .. "/"
end

local function get_dir_key()
   return vim.loop.cwd()
end

-- Saves data to json file
--
-- @param filename: string (path to file)
-- @param args: table (data to be stored in the json)
-- @return boolean
local function save_to_json(filename, args)
   local f = io.open(filename, "w")
   if not f then
      return false
   end
   local json = vim.json.encode(args)
   f:write(json)
   f:close()
   return true
end

-- Loads data from json file and executes action on it
--
-- @param filename: string (path to file)
-- @param name_data: string (name of the data entry to be stored in the json)
-- @param action: function (function to be executed on the data entry)
   -- @return boolean, table (boolean: whether the data was modified; table: the modified data)
-- @param key: string (main key to store this data under; default: current directory)
-- @return table
local function load_entry_from_file_and(filename, name_data, action, key)
   local f = io.open(filename, "r")
   local data = {}
   if f then
      local content = f:read("*a")
      f:close()
      _, data = pcall(vim.json.decode, content, { object = true, array = true })
      assert(data, "Could not decode json")
   end

   key = key or get_dir_key()

   local entry = data[key]
   if not entry then
      data[key] = {}
      entry = data[key]
   end
   entry[name_data] = entry[name_data] or {}

   local modified, modified_entry = action(entry[name_data])
   if modified then
      entry[name_data] = modified_entry
      return save_to_json(filename, data)
   end
   return entry[name_data]
end

-- Updates data in json file
--
-- @param name_data: string (name of the data entry to be stored in the json)
-- @param data: table (data to be stored under the entry)
-- @param key: string (main key to store this data under; default: current directory)
-- @return boolean
function M.update_json_file(name_data, data, key)
   local target_file = get_config_path() .. "dap-helper.json"

   return load_entry_from_file_and(target_file, name_data, function(entry)
      return true, data
   end, key)
end

-- Loads data from json file
--
-- @param name_data: string (name of the data entry stored in the json)
-- @param key: string (main key to store this data under; default: current directory)
-- @return table
function M.load_from_json_file(name_data, key)
   local target_file = get_config_path() .. "dap-helper.json"

   return load_entry_from_file_and(target_file, name_data, function(entry)
      return false
   end, key)
end

-- Compares two arrays of arguments
--
-- @param args1: table (array of arguments)
-- @param args2: table (array of arguments)
-- @return boolean
function M.compare_args(args1, args2)
   if not args1 or not args2 then
      return false
   end
   if #args1 ~= #args2 then
      return false
   end
   for i = 1, #args1 do
      if args1[i] ~= args2[i] then
         return false
      end
   end
   return true
end

return M
