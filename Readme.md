# nvim-lib

A library with several modules:


|||
|----------|----------|
|api       | api functions, less `nvim_`     |
|nvim      | miscellaneous functions         |
|tbl       | generic table functions         |
|arr       | array/sequence functions        |
|config    | more theory than practice       |

General help file:

    :help nvim-lib

-------------------------------------------------------------------------------

## api

    local api = require("nvim-lib").api

Then you can call functions like this:

    api.win_close(...) -- instead of vim.api.nvim_win_close(...)

There are no other differences, nor any performance impact.
Names are still perfectly searchable with `K` key (unless you use `lsp` of
course...).

-------------------------------------------------------------------------------

## nvim

    local nvim = require("nvim-lib").nvim

It contains functions to create augroups, commands, popups, etc.

Also:

    nvim.reg        table to access vim registers
    nvim.keycodes   table with on-demand termcodes generation
    nvim.pos        table for easy access to marks and other positions

Help file:

    :help nvim-lib-nvim
    :help nvim-lib-tables


-------------------------------------------------------------------------------

## tbl

    local tlb = require("nvim-lib").tlb

Differently from `vim.tbl_*` functions, they can change the table in-place, and
the `fn` is called with `(key, value)`, not only with `(value)`.

Help files:

    :help nvim-lib-tbl
    :help nvim-lib-tbl.txt

-------------------------------------------------------------------------------

## arr

    local arr = require("nvim-lib").arr

Functions that are more specialized in handling arrays and sequences.
They use `ipairs` as default iterator.

There is a new iterator (`arr.npairs`) that can iterate arrays without skipping
nil values (as `ipairs` does instead), so it can be used to iterate arrays, and
not only sequences.

Help files:

    :help nvim-lib-arr
    :help nvim-lib-arr.txt
