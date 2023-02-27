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

Currently provides the following functions:

    function        arguments
    --------------------------------------------------
    put             lines, opts
    setlines        buf, lines, start, finish
    scratchbuf      lines, opts
    commands        cmds
    augroup         name
    echo            opts, opts2
    echoerr         text
    yesno           question
    popup           opts
    bufsize         buf
    eval            expr, throw
    try             opts
    search          pat, flags, stopline, timeout, skip
    testspeed       cmd, cnt, title

Also:

    nvim.reg        table to access vim registers
    nvim.keycodes   table with on-demand termcodes generation

Help file:

    :help nvim-lib-nvim


-------------------------------------------------------------------------------

## tbl

    local tlb = require("nvim-lib").tlb

Differently from `vim.tbl_*` functions, they can change the table in-place, and
the `fn` is called with `(key, value)`, not only with `(value)`.

There is a new iterator (`tbl.spairs`) that sorts the keys, and accepts
a `comp` function for the sorting operation.

Functions with argument `iter` accept a custom iterator (default is `pairs`).

    function        arguments
    ------------------------------------
    spairs          t, comp
    map             t, fn, new, iter
    filter          t, fn, new, iter
    toarray         t
    merge           t1, t2, keep
    empty           t
    copy            t, iter
    get             t, ...
    count           t
    replace         t, val, rep, iter
    keys            t
    values          t
    flatten         t
    contains        t, val
    deepcopy        object
    equal           a, b, deep
    intersect       a, b, iter
    difference      a, b, iter

Help files:

    :help nvim-lib-tbl
    :help nvim-lib-tbl.txt

-------------------------------------------------------------------------------

## arr

    local arr = require("nvim-lib").arr

Functions that are more specialized in handling arrays and sequences.

There is a new iterator (`arr.npairs`) that can iterate arrays without skipping
nil values (as `ipairs` does instead), so it can be used to iterate arrays, and
not only sequences.

    function        arguments
    ------------------------------------
    npairs          t
    range           n, m, step
    maparr          t, fn, new
    mapseq          t, fn
    filterarr       t, fn, new
    filterseq       t, fn
    seq             t
    isseq           t
    isarr           t
    indexof         t, v
    uniq            t
    slice           t, start, finish
    extend          dst, src, at, start, finish
    intersectarr    a, b
    subtractarr     a, b

Help files:

    :help nvim-lib-arr
    :help nvim-lib-arr.txt


-------------------------------------------------------------------------------

## config

Because I'm annoyed by the convetion that has become dominant in the Neovim
plugin ecosystem. More informations in [config.md](./config.md).
