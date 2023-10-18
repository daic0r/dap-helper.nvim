# dap-helper
Neovim Plugin that provides some convenience functions for nicer debugging with [nvim-dap](https://github.com/mfussenegger/nvim-dap) and [nvim-dap-ui](https://github.com/rcarriga/nvim-dap-ui), such as:

- Easy modification of command line arguments passed to the debuggee
- Saving/restoring of breakpoints and watches across sessions

## Installation
### lazy.nvim
```lua
{
  'daic0r/dap-helper.nvim',
  dependencies = { "rcarriga/nvim-dap-ui", "mfussenegger/nvim-dap" },
  config = function()
    require("dap-helper").setup()
  end
}
```

## Usage

Breakpoints and watches are saved automatically when a buffer is unloaded and read in once a file is loaded into a buffer.

To edit command line arguments passed during program launch run `:DapHelperSetLaunchArgs`.

The plugin tries to determine a project's base directory by attempting to locate a `.git` directory. Command line arguments will always be associated with that folder, i.e. if you launch Neovim from a subdirectory of your project, the arguments can still be found. If no `.git`. directory is present, the arguments will be associated with the current working directory.

To reset the stored data, you can run `:DapHelperReset`.

To edit the build command (command run before starting debugging) run `:DapHelperSetBuildCommand`. The value saved here can later be queried by `require"dap-helper".get_build_cmd()`.
### Example
```lua
local dap_helper = require"dap-helper"
vim.keymap.set("n", "<F5>", function()
   -- Check if debuggger is already running
   if #dap.status() == 0 then
      local ret = os.execute(dap_helper.get_build_cmd() .. " > /dev/null 2>&1")
      if ret ~= 0 then
         vim.notify("Build failed", vim.log.levels.ERROR)
         return
      end
   end
   dap.continue()
end)
```
