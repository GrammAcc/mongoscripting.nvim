# mongoscripting.nvim
Minimal wrapper around the mongosh utility for use inside neovim.

## Why?

I use SQL for all of my projects, but my employer uses MongoDB, which means that I have to learn mongo
as well as a very complicated non-relational schema while also completing my regular duties as a Software Engineer.

My co-workers made me jealous when I saw them using a very nice VSCode plugin to run mongo queries inside
their editors, but not jealous enough to use VSCode, so I wrote this simple wrapper around mongosh
to get the same basic functionality inside neovim without all the UI fluff.

## Features

- Run mongo queries inside neovim buffers, and write the output to a register for later use.
- Supports running an entire buffer as a mongosh script or running only the current visual selection.
- Has a toggleble UI that shows the current connection info and the output of the latest query run.
- Supports keymaps for cycling through multiple database and host connections via configurable Uri and Db arrays.

## Installation and Config

The `mongosh` command must be in your `PATH`.

Example with [lazy.nvim](https://github.com/folke/lazy.nvim) and default config values:

```lua
return {
  dir = "GrammAcc/mongoscripting.nvim",
  opts = {
    mongo_uris = {"mongodb://localhost:27017"},
    mongo_dbs = {"local"},
    input_register = "i",
    output_register = "o",
  },
}
```

True to the name, all opts are optional.

This plugin exposes lua functions for working with db connections and running queries.
No keymaps are set by default, so you will need to set any keymaps you want to use in your init.lua after this plugin is loaded.

Example:

```lua
local mongosh = require("mongoscripting")

vim.keymap.set("v", "<leader>mr", mongosh.run_selection)
vim.keymap.set("n", "<leader>mr", mongosh.run_buffer)
vim.keymap.set({"v","n"}, "<leader>mt", mongosh.toggle_ui)
vim.keymap.set("n", "<leader>md0", mongosh.next_db)
vim.keymap.set("n", "<leader>md9", mongosh.prev_db)
vim.keymap.set("n", "<leader>ma0", mongosh.next_uri)
vim.keymap.set("n", "<leader>ma9", mongosh.prev_uri)
vim.keymap.set({"v", "n", "i"}, "<leader>mep", mongosh.put_input)
vim.keymap.set({"v", "n", "i"}, "<leader>mwp", mongosh.put_output)
```

A brief explanation of each function:
  - `run_buffer`: Run the current buffer as a mongosh script file. The buffer must be written to disk for content to be executed.
    - This will store the output of the mongosh script in the configured `output_register`.
  - `run_selection`: Run the current selection directly. Multiple lines can be selected and will be executed exactly as written.
    - This will yank the selection into the configured `input_register`, and write the output into the configured `output_register`.
  - `toggle_ui`: Open/close the output window. Includes the output of the last run query as well as the current connection info.
  - `next|prev_db|uri`: Cycle through the configured mongo databases and uris. The output UI will update with the new connection info.
  - `put_input`: Paste the contents of the input register under the cursor. Same as `"ip` if using the default, but works with whatever register is configured.
  - `put_output`: Paste the contents of the output register under the cursor. Same as `"ip` if using the default, but works with whatever register is configured.

## Development

This plugin does what I need for work, and since I don't use mongo outside of work, I probably won't be adding any new features.
I will fix any significant problems as I have time, but don't expect fast turnaround on issues if you open one.

I am much more likely to address an issue right away if it comes with a PR. :)

Significant UI features such as selectable dbs/uris or floating windows are outside of the scope of this plugin. If you want these kinds of features, your best bet is to either fork this repo or list it as a dependency of your plugin and use it as a library for accessing mongosh.
