## nvim.config

This is a proof of concept for a saner system of plugin configurations.
The currently adopted convention is to have plugins to call a `setup()`
function. This has the advantage that it doesn't require setting options in
a global variable (typically `vim.g`), but has the disadvantage that it
prevents proper lazy loading, since `require`-ing the setup functions in many
cases will source most of the plugin scripts: goodbye lazy-loading at that
point.

The typical new-ish Neovim user may think: I use `lazy-this` and `lazy-that`,
who cares.

Well I do care, because to have proper lazy loading you shouldn't be forced to
rely on some package manager. Vim (and therefore Neovim) have had means for
package lazy-loading for years now. There are no good excuses for plugins to
prevent the users from correctly loading them at a convenient time, and not
before that.

This is an alternative system that has the following advantages:

1. doesn't spoil lazy loading
2. doesn't pollute the global namespace
3. it protects from accidental options corruption

-------------------------------------------------------------------------------

How it works:
```lua
    local config = require("nvim-lib.config")
```
The user configures plugins like this:
```lua
    config.plugin_name {
        options
    }
```
This simple. Note that it's actually a function call. If you try to do:
```lua
    config.plugin_name = options
```
it's an error.

When this is done the first time (in the user vimrc), the plugin isn't loaded
yet. It will load when it thinks it should. Or maybe it will never be loaded,
who knows at this point.

Then the plugin can fetch its own user configuration with:
```lua
    -- local cfg = config.plugin_name -- NO: this is a function to SET options
    local cfg = config().get("plugin_name")
```
And can also set a `setup` function, so that if the user wants to adjust the
options, the setup function will be called automatically:
```lua
    config().set("plugin_name", plugin_setup_function)
```
Next time the user does:
```lua
    config.plugin_name {
        options
    }
```
that call will not only update the configuration, but also call the setup
function:
```lua
    plugin_setup_function(options)
```
-------------------------------------------------------------------------------

Full example:
```lua
    -- user does this
    config = require'nvim-lib.config'
    config.plugin_name {
      option1 = 1,
      option2 = 2,
    }

    -- plugin author does this
    local cfg = config().get("plugin_name") -- then sets options

    local function plugin_setup(opts)
      print("You have successfully updated the plugin_name configuration.")
      print("New options: " .. vim.inspect(opts))
    end

    config().set("plugin_name", plugin_setup)

    -- user updates config again, and plugin_setup is called too
    config.plugin_name {
      option1 = 3,
      option2 = 4,
    }

    config().info() -- popup with resumée
```
