local M = {}
local e = vim.fn.fnameescape
local config = require("persisted.config")

---Print an error message
--@param msg string
--@param error string
--@return string
local function echoerr(msg, error)
  vim.api.nvim_echo({
    { "[persisted.nvim]: ", "ErrorMsg" },
    { msg, "WarningMsg" },
    { error, "Normal" },
  }, true, {})
end

--- Escape special pattern matching characters in a string
---@param input string
---@return string
local function escape_pattern(input)
  local magic_chars = { "%", "(", ")", ".", "+", "-", "*", "?", "[", "^", "$" }

  for _, char in ipairs(magic_chars) do
    input = input:gsub("%" .. char, "%%" .. char)
  end

  return input
end

--- Get the last element in a table
---@param table table
---@return string
function M.get_last_item(table)
  local last
  for _, _ in pairs(table) do
    last = #table - 0
  end
  return table[last]
end

---Check if a target directory exists in a given table
---@param dir string
---@param dirs_table table
---@return boolean
function M.dirs_match(dir, dirs_table)
  dir = vim.fn.expand(dir)
  return dirs_table
    and next(vim.tbl_filter(function(pattern)
      return dir:find(escape_pattern(vim.fn.expand(pattern)))
    end, dirs_table))
end

---Get the directory pattern based on OS
---@return string
function M.get_dir_pattern()
  local pattern = "/"
  if vim.fn.has("win32") == 1 then
    pattern = "[\\:]"
  end
  return pattern
end

---Load the given session
---@param session string
---@param silent boolean Load the session silently?
---@return nil|string
function M.load_session(session, silent)
  vim.api.nvim_exec_autocmds("User", { pattern = "PersistedLoadPre", data = session })

  local ok, result = pcall(vim.cmd, (silent and "silent " or "") .. "source " .. e(session))
  if not ok then
    return echoerr("Error loading the session! ", result)
  end

  vim.api.nvim_exec_autocmds("User", { pattern = "PersistedLoadPost", data = session })
end

---@param buffer number: buffer ID.
---@return boolean: `true` if this buffer could be restored later on loading.
function M.is_restorable(buffer)
  if #vim.api.nvim_buf_get_option(buffer, 'bufhidden') ~= 0 then
    return false
  end

  local buftype = vim.api.nvim_buf_get_option(buffer, 'buftype')
  if #buftype == 0 then
    -- Normal buffer, check if it listed.
    if not vim.api.nvim_buf_get_option(buffer, 'buflisted') then
      return false
    end
    -- Check if it has a filename.
    if #vim.api.nvim_buf_get_name(buffer) == 0 then
      return false
    end
  elseif buftype ~= 'terminal' then
    -- Buffers other then normal or terminal are impossible to restore.
    return false
  end

  if
    vim.tbl_contains(config.options.autosave_ignore_filetypes, vim.api.nvim_buf_get_option(buffer, 'filetype'))
    or vim.tbl_contains(config.options.autosave_ignore_buftypes, vim.api.nvim_buf_get_option(buffer, 'buftype'))
  then
    return false
  end
  return true
end

return M
