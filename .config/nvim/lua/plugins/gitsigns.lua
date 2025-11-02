return {
  'lewis6991/gitsigns.nvim',
  event = { 'BufReadPre', 'BufNewFile' },
  config = function()
    require('gitsigns').setup({
      current_line_blame = true, -- Toggle with <leader>ghB
      current_line_blame_opts = {
        virt_text_pos = 'eol', -- eol | overlay | right_align
        delay = 500,
      },
      preview_config = {
        border = 'rounded',
      },
      current_line_blame_formatter = '<author>, <author_time:%R> - <summary>',
      on_attach = function(bufnr)
        local gitsigns = require('gitsigns')

        local function map(mode, l, r, opts)
          opts = opts or {}
          opts.buffer = bufnr
          vim.keymap.set(mode, l, r, opts)
        end

        -- Navigation
        map('n', '<leader>gh]', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gitsigns.nav_hunk('next')
          end
        end, { desc = 'Next Hunk' })

        map('n', '<leader>gh[', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gitsigns.nav_hunk('prev')
          end
        end, { desc = 'Prev Hunk' })

        -- Alternative navigation with ] and [
        map('n', ']h', function()
          if vim.wo.diff then
            vim.cmd.normal({ ']c', bang = true })
          else
            gitsigns.nav_hunk('next')
          end
        end, { desc = 'Next Hunk' })

        map('n', '[h', function()
          if vim.wo.diff then
            vim.cmd.normal({ '[c', bang = true })
          else
            gitsigns.nav_hunk('prev')
          end
        end, { desc = 'Prev Hunk' })

        -- Actions
        map('n', '<leader>ghs', gitsigns.stage_hunk, { desc = 'Stage Hunk' })
        map('v', '<leader>ghs', function()
          gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, { desc = 'Stage Hunk' })
        map('n', '<leader>ghu', gitsigns.undo_stage_hunk, { desc = 'Undo Stage Hunk' })
        map('n', '<leader>ghr', gitsigns.reset_hunk, { desc = 'Reset Hunk' })
        map('v', '<leader>ghr', function()
          gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
        end, { desc = 'Reset Hunk' })
        map('n', '<leader>ghS', gitsigns.stage_buffer, { desc = 'Stage Buffer' })
        map('n', '<leader>ghR', gitsigns.reset_buffer, { desc = 'Reset Buffer' })
        map('n', '<leader>ghp', gitsigns.preview_hunk, { desc = 'Preview Hunk' })
        map('n', '<leader>ghb', function()
          gitsigns.blame_line({ full = true })
        end, { desc = 'Blame Line' })
        map('n', '<leader>ghB', function()
          gitsigns.toggle_current_line_blame()
        end, { desc = 'Toggle Blame Line' })
        map('n', '<leader>ghd', gitsigns.diffthis, { desc = 'Diff This' })
        map('n', '<leader>ghD', function()
          gitsigns.diffthis('~')
        end, { desc = 'Diff This ~' })

        -- Text object
        map({ 'o', 'x' }, 'ih', ':<C-U>Gitsigns select_hunk<CR>', { desc = 'GitSigns Select Hunk' })
      end,
    })
  end,
}
