# dap-helper
Neovim Plugin that provides some convenience functions for nicer debugging

## Installation
### lazy.nvim
```lua
{
  'daic0r/dap-helper.nvim',
  config = function()
    require("dap-helper").setup()
  end
}
```

## Usage
To edit command line arguments passed during program launch run `:DapHelperSetLaunchArgs`.

Breakpoints and watches are saved automatically when a buffer is unloaded and read in once a file is loaded into a buffer.
