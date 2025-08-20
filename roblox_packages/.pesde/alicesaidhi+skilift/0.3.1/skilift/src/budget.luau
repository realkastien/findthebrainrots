local task = require("./task")
local flags = require("./flags")

local MINIMUM = 5

type BudgetUsage = 
    | "get"
    | "get_version"
    | "update"
    | "set"

local function get_budget(key: BudgetUsage)
    if not game then return 1000 end
    
    local budget = flags.datastoreservice:GetRequestBudgetForRequestType(
        if key == "get" then Enum.DataStoreRequestType.GetAsync
        elseif key == "get_version" then Enum.DataStoreRequestType.GetVersionAsync
        elseif key == "update" then Enum.DataStoreRequestType.UpdateAsync
        elseif key == "set" then Enum.DataStoreRequestType.SetIncrementAsync
        else error(`{key} is not valid`)
    )
    return budget
end

local function has_budget_and_delta(key: BudgetUsage, amount: number)
    return get_budget(key) - MINIMUM > amount
end

local function delay_until_meets_budget(key: BudgetUsage, minimum: number)
    while has_budget_and_delta(key, minimum) == false do
        task.wait()
    end
end

return {
    has_budget_and_delta = has_budget_and_delta,
    delay_until_meets_budget = delay_until_meets_budget,
    get_budget = get_budget
}