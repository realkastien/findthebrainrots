local types = require("./types")
local flags = require("./flags")
local THROW = require("./throw")

type Store<T=any> = types.Store<T>
type Action<T=any, U...=...any> = (old: T, U...) -> T

local function ASSERT_ACTION<T>(store: Store<T>, action: Action<T>)
    local transaction_actions = store._transaction_actions
    local actions = store._allowed_actions

    if flags.processing_transaction and not transaction_actions[action] and actions[action] then
        THROW("transaction_invalid_action", debug.info(action, "sl"))
    elseif flags.processing_transaction and not transaction_actions[action] then
        THROW("transaction_invalid_function", debug.info(action, "sl"))
    elseif not flags.processing_transaction and transaction_actions[action] and not actions[action] then
        THROW("action_attempt_transaction", debug.info(action, "sl"))
    elseif not flags.processing_transaction and not actions[action] then
        THROW("action_invalid_function", debug.info(action, "sl"))
    end
end


local function register_action<T>(store: Store<T>, action: Action<T>)
    local actions = store._allowed_actions
    actions[action] = true
    return action
end


local function register_transaction_action<T>(store: Store<T>, name: string, action: Action<T>)
    local transaction_actions = store._transaction_actions
    local transaction_names = store._transaction_names
    local actions = store._allowed_actions
    
    transaction_actions[action] = name
    transaction_names[name] = action
    actions[action] = true
    return action
end

local function create_record(action: Action, ...: any)
    return { action, ... }
end

local function create_transaction_record<T>(store: Store<T>, action: Action<T>, ...: any)
    local transaction_actions = store._transaction_actions
    return { fn = transaction_actions[action], values = {...} }
end

local function obtain_transaction_action<T>(store: Store<T>, name: string)
    local transaction_names = store._transaction_names

    local action = transaction_names[name]
    if not action then THROW("unknown_transaction_action", name) end
    return action
end

return {
    ASSERT_ACTION = ASSERT_ACTION,
    
    register_action = register_action,
    register_transaction_action = register_transaction_action,

    create_record = create_record,
    create_transaction_record = create_transaction_record,

    obtain_transaction_action = obtain_transaction_action,
}