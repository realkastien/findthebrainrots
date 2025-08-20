local flags = require("./flags")

local function LOG(...)
    if flags.print == false then return end
    print("[skilift]:", ...)
end

return LOG