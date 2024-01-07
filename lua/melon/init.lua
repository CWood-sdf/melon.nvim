local M = {}

---@class MelonConfig
---@field ignore fun(string): boolean
---@field signOpts table<string, string>
M.config = {
    ignore = function(_)
        return false
    end,
    signOpts = {}
}
local lastTime = vim.loop.hrtime()
local augroup = vim.api.nvim_create_augroup("Melon", {
    clear = true
})
local editingFile = false
local function placeSigns(force)
    force = force or false
    if (vim.loop.hrtime() - lastTime) < 1000 and not force then
        return
    end
    if vim.api.nvim_buf_get_name(0) == "" then
        return
    end
    if not editingFile then
        return
    end
    local marks = vim.api.nvim_exec2("marks", { output = true })
    local arr = {}
    local str = ""
    for i = 1, #marks.output do
        local c = marks.output:sub(i, i)
        if c == "\n" then
            table.insert(arr, str)
            str = ""
        else
            str = str .. c
        end
    end
    if #str ~= 0 then
        table.insert(arr, str)
    end
    lastTime = vim.loop.hrtime()
    local signUnplace = "call sign_unplace('Melon_sign_group', {})"
    local _ = vim.api.nvim_exec2(signUnplace, {})
    for _, v in ipairs(arr) do
        local sign = ""
        local i = 1
        while v:sub(i, i) == ' ' do
            i = i + 1
        end
        sign = v:sub(i, i)
        local a = vim.api.nvim_buf_get_mark(0, sign)
        local l = a[1]
        local c = a[2]
        -- print(sign)
        if l == 0 and c == 0 then
            goto continue
        end
        if M.config.ignore(sign) then
            goto continue
        end
        local txt = sign
        if txt == "'" then
            txt = "qt1"
        end
        local signDef = "sign define Melon_" .. txt .. " text=" .. sign
        for k, val in pairs(M.config.signOpts) do
            signDef = signDef .. " " .. k .. "=" .. val
        end
        -- print(signDef)
        local _ = vim.api.nvim_exec2(signDef, { output = true })
        -- print(out.out)
        local priority = 1
        if sign:match("[a-z]") then
            priority = 2
        end
        local signPlace = "call sign_place(0, 'Melon_sign_group', 'Melon_" ..
            txt .. "', nvim_get_current_buf(), {'lnum':" .. l .. ", 'priority': " .. priority .. "})"
        -- print(signPlace)
        local _ = vim.api.nvim_exec2(signPlace, { output = true })
        ::continue::
    end
end

---@param opts MelonConfig
function M.setup(opts)
    M.config = vim.tbl_deep_extend("force", M.config, opts or {})
    vim.api.nvim_create_autocmd({ "BufReadPost" },
        {
            pattern = "*.*",
            callback = function()
                editingFile = true
            end,
            group = augroup
        })
    vim.api.nvim_create_autocmd({ "BufEnter" },
        {
            pattern = "*.*",
            callback = function()
                placeSigns(true)
            end,
            group = augroup,
        })
    vim.api.nvim_create_autocmd({ "BufLeave" }, {
        callback = function()
            editingFile = false
        end,
        group = augroup,
    })
    vim.api.nvim_create_autocmd({ "ModeChanged" }, {
        callback = function()
            placeSigns(true)
        end,
        group = augroup,
    })
    vim.on_key(placeSigns)
end

return M
