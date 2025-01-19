local M = {}
local L = { mongosh_buffer = nil, mongosh_window = nil }

Config = {
  mongo_dbs = { "local" },
  mongo_uris = { "mongodb://localhost:27017" },
  input_register = "i",
  output_register = "o",
}

local curr_uri_idx = 1
local curr_db_idx = 1

function M.put_input()
  vim.cmd(":silent " .. "normal " .. '"' .. Config.input_register .. "p")
end

function M.put_output()
  vim.cmd(":silent " .. "normal " .. '"' .. Config.output_register .. "p")
end

-- Adapted from: http://lua-users.org/wiki/SplitJoin
local function split(str, separator, limit)
  assert(separator ~= '')
  assert(limit == nil or limit >= 1)

  local results = {}

  if str:len() > 0 then
    limit = limit or -1

    local split_idx, sub_idx = 1, 1
    local first_idx, last_idx = str:find(separator, sub_idx, true)
    while first_idx and limit ~= 0 do
      results[split_idx] = str:sub(sub_idx, first_idx - 1)
      split_idx = split_idx + 1
      sub_idx = last_idx + 1
      first_idx, last_idx = str:find(separator, sub_idx, true)
      limit = limit - 1
    end
    results[split_idx] = str:sub(sub_idx)
  end

  return results
end

function M.get_curr_uri()
  return Config.mongo_uris[curr_uri_idx]
end

local function get_obfuscated_uri()
  local curr_uri = M.get_curr_uri()
  if curr_uri:find("@", 1, true) then
    local pre, host = unpack(split(curr_uri, "@"))
    local scheme, creds = unpack(split(pre, "://"))
    local username, _ = unpack(split(creds, ":"))
    return scheme .. "://" .. username .. ":" .. "****" .. "@" .. host
  else
    return curr_uri
  end
end

function M.get_curr_db()
  return Config.mongo_dbs[curr_db_idx]
end

local function update_ui()
  if L.mongosh_buffer ~= nil then
    local conn_info = "Connection - " .. "Uri: " .. get_obfuscated_uri() .. " | " .. "Database: " .. M.get_curr_db()
    vim.api.nvim_buf_set_lines(L.mongosh_buffer, 0, -1, false, { conn_info, "", "" })
    local replacelines = split(vim.fn.getreg(Config.output_register), "\n")
    vim.api.nvim_buf_set_lines(L.mongosh_buffer, 4, -1, false, replacelines)
  end
end

function M.next_uri()
  if curr_uri_idx == #Config.mongo_uris then
    curr_uri_idx = 1
  else
    curr_uri_idx = curr_uri_idx + 1
  end
  update_ui()
  print("Switched Target Uri to: " .. M.get_curr_uri())
end

function M.prev_uri()
  if curr_uri_idx == 1 then
    curr_uri_idx = #Config.mongo_uris
  else
    curr_uri_idx = curr_uri_idx - 1
  end
  update_ui()
  print("Switched Target Uri to: " .. M.get_curr_uri())
end

function M.next_db()
  if curr_db_idx == #Config.mongo_dbs then
    curr_db_idx = 1
  else
    curr_db_idx = curr_db_idx + 1
  end
  update_ui()
  print("Switched Target Db to: " .. M.get_curr_db())
end

function M.prev_db()
  if curr_db_idx == 1 then
    curr_db_idx = #Config.mongo_dbs
  else
    curr_db_idx = curr_db_idx - 1
  end
  update_ui()
  print("Switched Target Db to: " .. M.get_curr_db())
end

local function assert_ui()
  if L.mongosh_buffer == nil then
    L.mongosh_buffer = vim.api.nvim_create_buf(false, true)
  end
end

function M.toggle_ui()
  if (L.mongosh_window == nil) or (not vim.api.nvim_win_is_valid(L.mongosh_window)) then
    assert_ui()
    update_ui()
    vim.cmd(":below split")
    L.mongosh_window = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(L.mongosh_window, L.mongosh_buffer)
  else
    vim.api.nvim_win_hide(L.mongosh_window)
    L.mongosh_window = nil
  end
end

local function use_db_str()
  return "--eval $'use(\\'" .. M.get_curr_db() .. "\\')'"
end

function M.run_buffer()
  local cmd = "mongosh " .. M.get_curr_uri() .. " --quiet " .. use_db_str() .. " --file " .. vim.fn.expand("%")
  local file = assert(io.popen(cmd .. " 2>&1", "r"), "Unable to read output from mongosh command")
  file:flush()
  local res = file:read("a")
  file:close()

  vim.fn.setreg(Config.output_register, res)
  if L.mongosh_window ~= nil then
    update_ui()
  end
end

function M.run_selection()
  vim.cmd(":silent " .. "normal " .. '"' .. Config.input_register .. "y")
  local selection = vim.fn.getreg(Config.input_register)
  selection = string.gsub(selection, "'", "\\'")
  selection = string.gsub(selection, '"', '\\"')
  local cmd = "mongosh " .. M.get_curr_uri() .. " --quiet " .. use_db_str() .. " --eval " .. "$'" .. selection .. "'"
  local file = assert(io.popen(cmd .. " 2>&1", "r"), "Unable to read output from mongosh command")
  file:flush()
  local res = file:read("a")
  file:close()

  vim.fn.setreg(Config.output_register, res)
  if L.mongosh_window ~= nil then
    update_ui()
  end
end

function M.setup(opts)
  for k, v in pairs(opts) do
    if Config[k] ~= nil then
      Config[k] = v
    end
  end
  -- Clear the registers to avoid accidentally executing something from a previous session.
  vim.fn.setreg(Config.input_register, "")
  vim.fn.setreg(Config.output_register, "")
end

return M
