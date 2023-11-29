# `nvim-mapper` 

> `nvim-mapper` provides wrappers around `vim.keymap.set` which allows you to
> pass through a callback for the right side of you keymap which gets fed the
> previous mapping as an argument so you can use it as a fallback in your new
> mapping.

Sometimes I want to multiple things one key can do depending on some conditions.
For example, in insert mode, I want `<C-f>` to jump me forward in my snippet, if
there is text on the line, I want it to put me at the end of my line, and
finally, if the line is empty, I want it to indent my cursor to the correct
position (the default behavour). `nvim-mapper` allows me to do this.

Let's say I define the following mappings, in this order, with `nvim-mapper`:

```lua
-- jumps my cursor to the end of the line if there is text on the line
require("nvim-mapper").map_keymap({ "i" }, "<C-f>", function(fallback)
    if vim.fn.len(vim.fn.getline(".")) > vim.fn.getpos(".")[3] then
        return "<C-o>$"
    else
      fallback()
    end
end)
```

> Note if I just wanted to map `<C-f>` to `<C-o>\$`, I would just put the raw
> string in the 3rd argument of `map_keymap`. `fallback` is the default
> behaviour vim has for using that mapping. In the case of `<C-f>`, it indents
> our cursor at the correct line in our current scope.

Then let's define a function which jumps our cursor forward if we are in a
luasnippet.

```lua
local ls = require("luasnip")
require("nvim-mapper").map_keymap({ "i" }, "<C-f>", function(fallback)
  if ls.jumpable(1) then
    ls.jump(1)
  else
    fallback()
  end
end)
```

As long as these are defined in the correct order, now we have a keymap which does the following:

- If we are in a snippet, we jump
- If we are on a line with characters, we jump to the end of the line
- If we are on a blank line, we indent our cursor 
