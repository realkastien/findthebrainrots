local types = require("./types")
local retry = require("./retry")
local budget = require("./budget")

type StoredData<T> = types.StoredData<T>
type Store<T> = types.Store<T>
type View<T> = types.View<T>

local function view_key<T>(self: Store<T>, key: string): View<T>
    local view = {}
    local datastore = self._store

    function view:latest()
        local value: StoredData<T> = retry.exponential_backoff(function()
            budget.delay_until_meets_budget("get", 1)
            return datastore:GetAsync(key) or { data = nil }
        end)

        return value.data
    end

    function view:version(version: string)
        local value: StoredData<T> = retry.exponential_backoff(function()
            budget.delay_until_meets_budget("get_version", 1)
            return datastore:GetVersionAsync(key, version) or { data = nil }
        end)

        return value.data
    end

    function view:timestamp(timestamp: number)
        local value: StoredData<T> = retry.exponential_backoff(function()
            budget.delay_until_meets_budget("get_version", 1)
            return datastore:GetVersionAtTimeAsync(key, timestamp) or { data = nil }
        end)

        return value.data
    end

    return view
end

return {
    view_key = view_key
}