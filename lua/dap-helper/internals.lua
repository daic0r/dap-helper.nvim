local M = {}

local function get_config_path()
   return vim.fn.stdpath("data")
end

local function get_dir_key()
   -- None found? Use current directory as key
   local git_dir = M.get_git_dir()
   if not git_dir then
      return vim.loop.cwd()
   end
   -- Return base path (with the .git stripped off)
   return vim.fs.dirname(git_dir)
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
   local target_file = vim.fs.joinpath(get_config_path(), "dap-helper.json")

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
   local target_file = vim.fs.joinpath(get_config_path(),  "dap-helper.json")

   return load_entry_from_file_and(target_file, name_data, function(entry)
      return false
   end, key)
end

function M.save_watches()
   local dapui = require("dapui")

   local curbuf = vim.api.nvim_get_current_buf()
   local filename = vim.api.nvim_buf_get_name(curbuf)

   M.update_json_file("watches", dapui.elements.watches.get(), filename)
end

function M.load_watches()
   local dapui = require("dapui")

   local curbuf = vim.api.nvim_get_current_buf()
   local filename = vim.api.nvim_buf_get_name(curbuf)
   local entry = M.load_from_json_file("watches", filename)

   -- remove present watches -> we want only watches pertinent to the file
   local watches = dapui.elements.watches.get()
   while #watches > 0 do
      table.remove(watches, 1)
   end
   for _, watch in ipairs(entry) do
      dapui.elements.watches.add(watch.expression)
   end
end

function M.save_breakpoints()
   local bps = require("dap.breakpoints");

   local curbuf = vim.api.nvim_get_current_buf()

   local bufbps = bps.get(curbuf)
   --local _,bpsextracted = pairs(bufbps)(bufbps)
   local bpsextracted = bufbps[curbuf]

   local filename = vim.api.nvim_buf_get_name(curbuf)
   M.update_json_file("breakpoints", bpsextracted, filename)
end

function M.load_breakpoints()
   local bps = require("dap.breakpoints");

   local curbuf = vim.api.nvim_get_current_buf()

   local entry = M.load_from_json_file("breakpoints", vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
   if entry then
      for _, bp in ipairs(entry) do
         bps.set(bp, curbuf, bp.line)
      end
   end
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

function M.is_invalid_filename(filename)
   return #filename == 0 or not vim.loop.fs_stat(filename) or string.find(filename, "^term:")
end

function M.get_git_dir()
   -- Try to find base folder that contains the .git files
   local path = vim.fs.find(".git", {
      upward = true,
      stop = vim.uv.os_homedir(),
      path = vim.fs.dirname(vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
   })
   return path[1] or {}
end

-- Parent dir of the .git dir
function M.get_base_dir()
   return vim.fs.dirname(M.get_git_dir())
end

return M
