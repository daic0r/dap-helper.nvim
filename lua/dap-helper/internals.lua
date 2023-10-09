local M = {}

local function get_config_path()
   return vim.fn.stdpath("data") .. "/"
end

function M.save_to_json(name, args)
   local target_file = get_config_path() .. "dap-helper." .. name .. ".json"
   local f = io.open(target_file, "w")
   if not f then
      return false
   end
   local json = vim.json.encode(args)
   f:write(json)
   f:close()
   return true
end

function M.load_from_json(name)
   local target_file = get_config_path() .. "dap-helper." .. name .. ".json"
   local f = io.open(target_file, "r")
   if not f then
      return nil
   end
   local data = f:read("*a")
   f:close()
   return vim.json.decode(data, { object = true, array = true })
end

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
