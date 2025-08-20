local task = require("./task")

local EXPONENT_BACKOFF = 2

local function exponential_backoff<T...>(fn: () -> T...): T...
    local delay = 3
    local result

    while true do
        local ok = pcall(function()
            result = { fn() }
        end)

        if not ok then
            task.wait(delay)
            delay *= EXPONENT_BACKOFF
        else
            break
        end
    end

    return unpack(result)
end

local function regular_retry<T...>(fn: () -> T..., delay: number, amount: number?): T...

    local i = 0
    local ok, result

    while ok ~= true and i ~= amount do
        ok, result = pcall(function()
            return { fn() }
        end)
        i += 1
        task.wait(1)
    end

    return unpack(result)

end

return {

    exponential_backoff = exponential_backoff,
    regular_retry = regular_retry

}