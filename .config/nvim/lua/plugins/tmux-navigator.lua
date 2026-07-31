return {
  'christoomey/vim-tmux-navigator',
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    local uv = vim.uv or vim.loop

    -- Which multiplexer surrounds us never changes during a session, so resolve
    -- it once instead of reading the environment on every keystroke.
    local herdr_pane = vim.env.HERDR_PANE_ID
    local in_herdr = herdr_pane ~= nil and herdr_pane ~= ''

    -- Tell the herdr `herdr-nvim-nav` plugin that Neovim owns this pane, so its
    -- ctrl+h/j/k/l actions forward the chord here instead of moving panes.
    -- herdr has no equivalent of tmux's `@pane-is-vim` pane option, and asking it
    -- what a pane is running costs a process per keystroke -- a file named after
    -- the pane lets the check be pure shell builtins. The PID lets a marker left
    -- behind by a crash be recognised as stale.
    local marker_owned = true

    local function marker_path()
      if not in_herdr then
        return nil
      end
      local cache = vim.env.XDG_CACHE_HOME
      if cache == nil or cache == '' then
        cache = vim.env.HOME .. '/.cache'
      end
      return cache .. '/herdr/nvim-panes/' .. herdr_pane
    end

    ---@return integer|nil pid in the marker, if it names a live process
    local function live_marker_pid(path)
      local fd = io.open(path, 'r')
      if not fd then
        return nil
      end
      local pid = tonumber(fd:read('l'))
      fd:close()
      if not pid then
        return nil
      end
      local ok, alive = pcall(uv.kill, pid, 0) -- signal 0 only probes
      return (ok and alive) and pid or nil
    end

    local function claim_marker()
      local path = marker_path()
      if not path then
        return
      end
      -- Another live Neovim already claimed this pane: we are nested in its
      -- :terminal, so the marker is not ours to write or remove.
      local owner = live_marker_pid(path)
      if owner and owner ~= uv.os_getpid() then
        marker_owned = false
        return
      end
      vim.fn.mkdir(vim.fn.fnamemodify(path, ':h'), 'p')
      local fd = io.open(path, 'w')
      if fd then
        fd:write(tostring(uv.os_getpid()), '\n')
        fd:close()
      end
    end

    local function release_marker()
      if not marker_owned then
        return
      end
      local path = marker_path()
      if path then
        os.remove(path)
      end
    end

    claim_marker()
    vim.api.nvim_create_autocmd('VimResume', { callback = claim_marker })
    vim.api.nvim_create_autocmd({ 'VimSuspend', 'VimLeavePre' }, { callback = release_marker })

    -- Crossing a pane boundary used to shell out with `vim.fn.system{herdr, ...}`,
    -- which blocks the UI for a process spawn -- a median of ~10ms on this machine
    -- and a tail into the hundreds, because fork/exec here is slow and erratic.
    -- herdr's control socket answers the same request in ~0.1ms and creates no
    -- process. The spawn stays as a fallback: the wire protocol is undocumented
    -- and could move under us on an update.
    local HERDR_BIN = vim.env.HERDR_BIN_PATH
    if HERDR_BIN == nil or HERDR_BIN == '' then
      HERDR_BIN = 'herdr'
    end
    local HERDR_SOCKET = vim.env.HERDR_SOCKET_PATH
    if HERDR_SOCKET == nil or HERDR_SOCKET == '' then
      HERDR_SOCKET = vim.fn.expand('~/.config/herdr/herdr.sock')
    end
    local SOCKET_TIMEOUT_MS = 150

    -- Newline-delimited JSON. The body only varies by direction, so encode the
    -- four payloads once rather than on every keystroke.
    local FOCUS_PAYLOAD = {}
    for _, d in ipairs({ 'left', 'down', 'up', 'right' }) do
      FOCUS_PAYLOAD[d] = vim.json.encode({
        id = 'nvim.nav',
        method = 'pane.focus_direction',
        params = { direction = d, pane_id = vim.env.HERDR_PANE_ID },
      }) .. '\n'
    end

    ---@return boolean reached  false means fall back to the CLI
    local function focus_via_socket(dir)
      local pipe = uv.new_pipe(false)
      if not pipe then
        return false
      end

      local done, reached = false, false
      local function finish(ok)
        if done then
          return
        end
        done, reached = true, ok
        if not pipe:is_closing() then
          pipe:close()
        end
      end

      pipe:connect(HERDR_SOCKET, function(cerr)
        if cerr then
          return finish(false)
        end
        pipe:read_start(function(rerr, data)
          finish(not rerr and data ~= nil)
        end)
        pipe:write(FOCUS_PAYLOAD[dir])
      end)

      vim.wait(SOCKET_TIMEOUT_MS, function()
        return done
      end, 1)
      finish(false)
      return reached
    end

    local TMUX_DIR = { left = 'Left', down = 'Down', up = 'Up', right = 'Right' }

    local function nav(wincmd, dir)
      local prev = vim.api.nvim_get_current_win()
      vim.cmd('wincmd ' .. wincmd)
      if vim.api.nvim_get_current_win() ~= prev then
        return -- moved within Neovim
      end

      -- At a split edge: cross into the surrounding multiplexer.
      if in_herdr then
        if not focus_via_socket(dir) then
          vim.fn.system({ HERDR_BIN, 'pane', 'focus', '--direction', dir, '--current' })
        end
      elseif vim.env.TMUX and vim.env.TMUX ~= '' then
        pcall(vim.cmd, 'TmuxNavigate' .. TMUX_DIR[dir])
      end
    end

    local function map(lhs, wincmd, dir, desc)
      vim.keymap.set('n', lhs, function()
        nav(wincmd, dir)
      end, { silent = true, noremap = true, desc = desc })
    end

    map('<C-h>', 'h', 'left', 'Navigate left')
    map('<C-j>', 'j', 'down', 'Navigate down')
    map('<C-k>', 'k', 'up', 'Navigate up')
    map('<C-l>', 'l', 'right', 'Navigate right')
    map('<C-Left>', 'h', 'left', 'Navigate left')
    map('<C-Down>', 'j', 'down', 'Navigate down')
    map('<C-Up>', 'k', 'up', 'Navigate up')
    map('<C-Right>', 'l', 'right', 'Navigate right')
  end,
}
