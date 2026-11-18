local M = {
  buf = nil,
  win = nil,
  handle = nil,
  last_reset_row = nil,
  efm = nil,
}

function M:close()
  self.last_reset_row = nil
  if self.handle then
    self.handle:kill()
    self.handle = nil
  end
  if self.win then
    if vim.api.nvim_win_is_valid(self.win) then
      vim.api.nvim_win_close(self.win, true)
    end
    self.win = nil
  end
  if self.buf then
    vim.api.nvim_buf_delete(self.buf, {force = true})
    self.buf = nil
  end
end

function M:open(cmd, opts)
  opts = opts or {}
  M:close()
  M:_open_window()
  self.handle = vim.system(cmd, {
    cwd = opts.cwd,
    stdout = function(err, data)
      if err then
        vim.schedule(function() print('Error: ' .. tostring(err)) end)
        return
      end

      if data and self.buf then
        vim.schedule(function()
          local lines = vim.split(data, '[\r\n]+')
if lines[#lines] == '' then table.remove(lines) end
          if #lines == 0 then return end

          if opts.line_mapper then
            lines = vim.iter(lines):map(opts.line_mapper):totable()
          end

          vim.api.nvim_buf_set_lines(self.buf, -1, -1, false, lines)
          if self.win and not self:_win_is_current() then
            vim.api.nvim_win_set_cursor(self.win, {vim.api.nvim_buf_line_count(self.buf), 0})
          end
        end)
      end
    end,
    stderr = function(_, data)
      if data and self.buf then
        vim.schedule(function()
          local lines = vim.split(data, '[\r\n]+')
          if lines[#lines] == '' then table.remove(lines) end
          if #lines == 0 then return end
          vim.api.nvim_buf_set_lines(self.buf, -1, -1, false, lines)
        end)
      end
    end
  })
end

function M:_win_is_current()
  return vim.api.nvim_get_current_win() == self.win
end

function M:_open_window()
  self.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, true, {})
  local opts = {
    relative = 'editor',
    width = math.floor(vim.o.columns / 3),
    height = 20,
    col = vim.o.columns,
    row = 0,
    anchor = 'SE',
    style = 'minimal',
  }
  self.win = vim.api.nvim_open_win(self.buf, false, opts)
  vim.api.nvim_set_option_value('wrap', false, {win = self.win})
  vim.api.nvim_set_option_value('winhl', 'Normal:MyHighlight', {win = self.win})
end

function M:open_quickfix()
  if not self.buf then
    return
  end
  opts = opts or {}
  local start = self.last_reset_row or 0
  local lines = vim.api.nvim_buf_get_lines(self.buf, start, -1, false)
  if opts.line_mapper then
    lines = vim.iter(lines):map(opts.line_mapper):totable()
  end
  local entries = vim.fn.getqflist({
    lines = lines,
    efm = self.efm,
  }).items
  entries = vim.iter(entries):filter(function(x)
    return x.valid == 1
  end):totable()
  if #entries == 0 then
    vim.cmd('cclose')
    print('no errors')
  else
    vim.fn.setqflist(entries, 'r')
    vim.cmd('copen')
    vim.cmd('cbottom')
  end
  self.last_reset_row = vim.api.nvim_buf_line_count(self.buf)
end

return M
