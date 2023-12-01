local M = {}

local send_keys_to_nvim = function(string)
    local keys = vim.api.nvim_replace_termcodes(string, true, false,
        true)
    if vim.api.nvim_get_mode().mode == "niI" then
        return vim.cmd("normal " .. keys)
    end
    return vim.api.nvim_feedkeys(keys, "n",
        false)
end

local send_keys_to_nvim_with_count = function(string)
    local count = vim.api.nvim_get_vvar("count")
    send_keys_to_nvim((count ~= 0 and count or "") .. string)
end

---@param mode Mode[]|Mode: The mode or list of modes the mapping should apply to
---@param left string: left part of mapping
---@param right string|fun(fallback: unknown): string|nil Right part of mapping
---@param opts table: options for our keymap
M.map_keymap = function(mode, left, right, opts)
    ---@type Mode[]
    mode = type(mode) == "table" and mode or { mode }
    local fallback = opts.fallback
    opts.fallback = nil
    local new_mapping = right
    for _, m in ipairs(mode) do
        vim.keymap.set(m, left,
            M.gen_mapping(m, left, new_mapping, fallback), opts)
    end
end

---@alias Mode "n" | "v" | "i" | "x" | "s"
---@class Keymap
---@field[1]  Mode[]|Mode: mode
---@field[2] string: left
---@field[3] string | fun(fallback: unknown|nil) right
---@field[4] table?: opts: options for the specific keymap that override options passed through map_keymap_list
---@param mappings Keymap[]: A list of keymaps follwing the `Keymap` type
---@param ext_opts table: Options which will be additionally applied to every keymap in the given mapping list
M.map_keymap_list = function(mappings, ext_opts)
    ---@param mapping Keymap
    vim.tbl_map(function(mapping)
        local mode = mapping[1]
        local left = mapping[2]
        local right = mapping[3]
        local opts = mapping[4]
        opts = vim.tbl_deep_extend("keep", opts or {}, ext_opts or {}) or {}
        M.map_keymap(mode, left, right, opts)
    end, mappings)
end


---@param mode Mode
---@param left string
---@param right string|fun(fallback: function|nil)
---@param fallback boolean? Whether you want the fallback to be passed through. Needed when you are passing a callback with a different signature. For example, vim.lsp.buf.rename. True by default
M.gen_mapping = function(mode, left, right, fallback)
    fallback = fallback == nil and true or fallback
    if type(right) == "string" then
        return function()
            send_keys_to_nvim_with_count(right)
        end
    end

    local mapping_or_default = function(mapping_callback)
        return function()
            local success, res = pcall(mapping_callback)
            if not success then
                return send_keys_to_nvim_with_count(left) -- send the raw keys back if we have not mapped the key
            end
            if type(res) == "string" then
                send_keys_to_nvim_with_count(res)
            end
        end
    end

    if not fallback then
        return mapping_or_default(right)
    end

    ---@type string|function
    local prev_mapping
    local keymap_meta_info = vim.fn.maparg(left, mode, nil, true)
    if vim.fn.len(keymap_meta_info) ~= 0 then
        prev_mapping = keymap_meta_info.rhs or keymap_meta_info.callback
    end

    if not prev_mapping then
        return mapping_or_default(right)
    end

    ---@type function
    prev_mapping = type(prev_mapping) == "function" and prev_mapping or
        function()
            send_keys_to_nvim_with_count(prev_mapping)
        end

    return mapping_or_default(function()
        right(prev_mapping)
    end)
end

return M
