function reload()
   package.loaded["dap-helper"] = nil
   require("dap-helper").setup()
end

local internals = require("dap-helper.internals")

local M = {}

function M.setup()
   print(vim.fn.stdpath("data") .. '/dap-helper.args.json')
   vim.api.nvim_create_user_command("DapHelperSetLaunchArgs", function(_arg)
      local data = internals.load_from_json("debug")
      local opts = { prompt = "Enter launch arguments: " }
      -- Check if file exists and data could be loaded
      -- If not, create default entry for this directory
      -- TODO: Always use base directory of current project, not cwd
      if not data then
         data = { [vim.loop.cwd()] = { args = {} } }
      end
      local entry = data[vim.loop.cwd()]
      -- If entry exists and has args, use them as default for the prompt
      -- concatening them with spaces
      if entry and #entry.args > 0 then
         opts.default = table.concat(entry.args, " ")
      end
      -- Ask use to input arguments
      local new_args = vim.fn.input(opts)
      -- Now do the reverse of the above, and split the input into an array
      local arg_array = {}
      for arg in string.gmatch(new_args, "%S+") do
         table.insert(arg_array, arg)
      end
      -- If the entry does not exist, or the arguments have changed, save the
      -- new arguments
      if not entry or not internals.compare_args(arg_array, entry.args) then
         data[vim.loop.cwd()].args = arg_array
         if not internals.save_to_json("debug", data) then
            print("Saving failed")
         end
      end
   end, {})
end

function M.get_launch_args()
   local data = internals.load_from_json("debug")
   if not data then
      return nil
   end
   local entry = data[vim.loop.cwd()]
   if entry then
      return entry.args
   end
   return nil
end

function M.set_launch_args()
   require("dap").configurations.rust[1].args = M.get_launch_args()
   P(require("dap").configurations.rust[1].args)
end

return M
