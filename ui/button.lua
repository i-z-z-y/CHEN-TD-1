local Button = {}

function Button.new(ui, label, x, y, w, h, onclick)
  local b = {label = label, x = x, y = y, w = w, h = h, onclick = onclick}
  ui.buttons = ui.buttons or {}
  table.insert(ui.buttons, b)
  return b
end

return Button
