local M = {}

local send_keys_to_nvim = function(string)
    local keys = vim.api.nvim_replace_termcodes(string, true, false,
        true)
    return vim.api.nvim_feedkeys(keys, "n",
        false)
end

---@param mode Mode[]|Mode: The mode or list of modes the mapping should apply to
---@param left string
---@param right string|fun(fallback: unknown)
---@param opts table?
---@param ext_opts table?
M.map_keymap = function(mode, left, right, opts, ext_opts)
    ---@type Mode[]
    mode = type(mode) == "table" and mode or { mode }
    local new_mapping = right
    for _, m in ipairs(mode) do
        vim.keymap.set(m, left,
            M.get_current_key_map(m, left, new_mapping),
            vim.tbl_deep_extend("keep", opts or { expr = true }, ext_opts or {}))
    end
end

---@alias Mode "n" | "v" | "i" | "x" | "s"
---@class Keymap
---@field[1]  Mode[]|Mode: mode
---@field[2] string: left
---@field[3] string | fun(fallback: unknown|nil) right
---@field[4] table?: opts
---@param mappings Keymap[]: A list of keymaps follwing the `Keymap` type
---@param ext_opts table?: Options which will be additionally applied to every keymap in the given mapping list
M.map_keymap_list = function(mappings, ext_opts)
    ---@param mapping Keymap
    vim.tbl_map(function(mapping)
        local mode = mapping[1]
        local left = mapping[2]
        local right = mapping[3]
        local opts = mapping[4]
        M.map_keymap(mode, left, right, opts, ext_opts)
    end, mappings)
end


---@param mode Mode
---@param left string
---@param right string|fun(fallback: function|nil)
---@return function
M.get_current_key_map = function(mode, left, right)
    if type(right) == "string" then
        return function()
            return right
        end
    end

    ---@type string|function
    local prev_mapping
    local current_mapping = vim.fn.maparg(left, mode, nil, true)
    if current_mapping then
        prev_mapping = current_mapping.rhs or current_mapping.callback
    end

    local result = function() return nil end
    if not prev_mapping then
        result = function()
            return right(nil)
        end
    else
        ---@type function
        prev_mapping = type(prev_mapping) == "function" and prev_mapping or
            function()
                return prev_mapping
            end

        result = function()
            return right(prev_mapping)
        end
    end
    return function()
        local success = pcall(result)
        if not success then
            return left
        end
    end
end

return M
