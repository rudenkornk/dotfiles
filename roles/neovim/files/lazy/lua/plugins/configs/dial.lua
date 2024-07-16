local M = {}

-- credits: https://www.lazyvim.org/extras/editor/dial
--
M.config = function()
  local dial_config = require("dial.config")
  local augend = require("dial.augend")

  local create_constants = function(elements, word, cyclic)
    local capitalized_first = {}
    for i, v in ipairs(elements) do
      capitalized_first[i] = v:sub(1, 1):upper() .. v:sub(2)
    end
    local capitalized = {}
    for i, v in ipairs(elements) do
      capitalized[i] = v:upper()
    end

    return {
      augend.constant.new({ elements = elements, word = word, cyclic = cyclic }),
      augend.constant.new({ elements = capitalized_first, word = word, cyclic = cyclic }),
      augend.constant.new({ elements = capitalized, word = word, cyclic = cyclic }),
    }
  end

  local booleans = { "true", "false" }
  local boolean_ops = { "and", "or" }
  local on_off = { "on", "off" }
  local ordinals = {
    "first",
    "second",
    "third",
    "fourth",
    "fifth",
    "sixth",
    "seventh",
    "eighth",
    "ninth",
    "tenth",
  }
  local weekdays = {
    "monday",
    "tuesday",
    "wednesday",
    "thursday",
    "friday",
    "saturday",
    "sunday",
  }
  local months = {
    "january",
    "february",
    "march",
    "april",
    "may",
    "june",
    "july",
    "august",
    "september",
    "october",
    "november",
    "december",
  }
  local errors = { "error", "warning", "critical" }

  local boolean_augend = create_constants(booleans, false, true)
  local boolean_ops_augend = create_constants(boolean_ops, true, true)
  local on_off_augend = create_constants(on_off, true, true)
  local ordinal_augend = create_constants(ordinals, false, true)
  local weekday_augend = create_constants(weekdays, false, true)
  local month_augend = create_constants(months, false, true)
  local error_augend = create_constants(errors, false, true)

  dial_config.augends:register_group({
    default = {
      augend.constant.alias.alpha,
      augend.constant.alias.Alpha,
      augend.constant.alias.bool,
      augend.constant.new({ elements = { "&&", "||" } }),
      augend.integer.alias.binary,
      augend.integer.alias.decimal_int,
      augend.integer.alias.hex,
      augend.integer.alias.octal,
      augend.semver.alias.semver,
      unpack(boolean_augend),
      unpack(boolean_ops_augend),
      unpack(on_off_augend),
      unpack(ordinal_augend),
      unpack(weekday_augend),
      unpack(month_augend),
      unpack(error_augend),
    },
  })
end

return M
