require "nvchad.mappings"

local map = vim.keymap.set

map("n", ";", ":", { desc = "CMD enter command mode" })
map("i", "jk", "<ESC>")

map("n", "<leader>fm", function()
  require("conform").format()
end, { desc = "Format buffer" })

map("v", ">", ">gv", { desc = "Indent and keep selection" })

map("n", "<leader>oi", function()
    local file = vim.fn.expand("%")
    vim.fn.jobstart({ "sh", "-c", string.format(
      "qlmanage -p %q &>/dev/null & sleep 0.2 && osascript -e 'tell application \"System Events\" to set frontmost of (first process whose name is \"qlmanage\") to true' &>/dev/null",
      file
    )})
  end, { desc = "Quick Look current file" })
