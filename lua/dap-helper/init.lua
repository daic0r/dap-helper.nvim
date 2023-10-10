function reload()
   package.loaded["dap-helper"] = nil
   require("dap-helper").setup()
end

local internals = require("dap-helper.internals")

local M = {}

local daic0r_dap_helper = vim.api.nvim_create_augroup("DAIC0R_DAP_HELPER", {
   clear = true
})

local function save_breakpoints()
   local bps = require("dap.breakpoints");
   assert(bps, "dap.breakpoints not loaded")
   
   local curbuf = vim.api.nvim_get_current_buf()

   local breakpoints = bps.get(curbuf)
   if #breakpoints == 0 then
      return
   end

   local filename = vim.api.nvim_buf_get_name(curbuf)
   internals.update_json_file("breakpoints", breakpoints, filename)
end

local function load_breakpoints()
   local bps = require("dap.breakpoints");
   assert(bps, "dap.breakpoints not loaded")

   local curbuf = vim.api.nvim_get_current_buf()

   local entry = internals.load_from_json_file("breakpoints", vim.api.nvim_buf_get_name(vim.api.nvim_get_current_buf()))
   if entry and #entry > 0 then
      bps.set({}, curbuf, entry)
   end
end

function M.setup()
   print(vim.fn.stdpath("data"))
   vim.api.nvim_create_user_command("DapHelperSetLaunchArgs", function(_arg)
      local entry = internals.load_from_json_file("args")
      local opts = { prompt = "Enter launch arguments: " }
      -- Check if file exists and data could be loaded
      -- If not, create default entry for this directory
      -- TODO: Always use base directory of current project, not cwd
      -- If entry exists and has args, use them as default for the prompt
      -- concatening them with spaces
      if #entry > 0 then
         opts.default = table.concat(entry, " ")
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
      if not entry or not internals.compare_args(arg_array, entry) then
         if not internals.update_json_file("args", arg_array) then
            print("Saving failed")
         end
      end
   end, {})

   vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = {"*.h", ".c", ".cpp", "*.rs" },
      callback = function(opts)
         print("Saving")
         save_breakpoints()
      end,
      group = daic0r_dap_helper
   })
   vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = {"*.h", ".c", ".cpp", "*.rs" },
      callback = function(opts)
         print("Loading breakpoints")
         load_breakpoints()
      end,
      group = daic0r_dap_helper
   })

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
   require("dap").configurations[vim.bo.filetype][1].args = M.get_launch_args()
   -- TODO: Remove debug statement
   P(require("dap").configurations[vim.bo.filetype][1].args)
end

return M
