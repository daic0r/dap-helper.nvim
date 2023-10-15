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

To reset the stored data, you can run `:DapHelperReset`.

The plugin tries to determine a project's base directory by attempting to locate a `.git` directory. Command line arguments will always be associated with that folder, i.e. if you launch Neovim from a subdirectory of your project, the arguments can still be found. If no `.git`. directory is present, the arguments will be associated with the current working directory.
