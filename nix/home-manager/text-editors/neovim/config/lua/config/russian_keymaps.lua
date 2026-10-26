local M = {}

function M.add(keys)
  local translations = {}
  for _, group in ipairs(vim.split(vim.o.langmap, ",", { plain = true })) do
    local from, to = group:match("^(.-);(.*)$")
    if from then
      local sources = vim.fn.split(from, "\\zs")
      for i, target in ipairs(vim.fn.split(to, "\\zs")) do
        translations[target] = sources[i]
      end
    end
  end

  for key, binding in pairs(vim.deepcopy(keys)) do
    local lhs = type(binding) == "table" and binding[2] ~= nil and binding[1] or key
    if binding and not lhs:find("<", 1, true) then
      local spec = type(binding) == "table" and binding or { binding }
      local modes = type(spec.mode) == "table" and spec.mode or { spec.mode or "n" }
      modes = vim.tbl_filter(function(mode)
        return mode == "n" or mode == "x" or mode == "v"
      end, modes)

      if #modes > 0 then
        local plain, shifted = {}, {}
        for _, char in ipairs(vim.fn.split(lhs, "\\zs")) do
          local translated = translations[char] or char
          plain[#plain + 1] = translated
          shifted[#shifted + 1] = translations[char]
              and char ~= vim.fn.tolower(char)
              and ("<S-" .. vim.fn.tolower(translated) .. ">")
            or translated
        end
        for _, alias in ipairs({ table.concat(plain), table.concat(shifted) }) do
          if alias ~= lhs and keys[alias] == nil then
            local copy = vim.deepcopy(spec)
            copy.mode = modes
            if copy[2] ~= nil then
              copy[1] = alias
            end
            keys[alias] = copy
          end
        end
      end
    end
  end
end

return M
