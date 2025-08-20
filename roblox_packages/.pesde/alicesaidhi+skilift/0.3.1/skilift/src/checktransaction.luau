local flags = require("./flags")
local types = require("./types")
local retry = require("./retry")
local task = require("./task")

local TRANSACTION_NAME = "_$SKILIFT_TRANSACTION"
local TRANSACTION_SCOPE = "global"

local TRANSACTION_MAX_LIFETIME = 60 * 90
local MAX_STORED_TRANSACTIONS = 9000

local cached_transaction_status = {}
local cached_transaction_lifetime = {}

type TransactionInfo = types.TransactionInfo
type TransactionId = types.TransactionId
type CompletionStatus = "failed" | "completed" | "unknown"

local function set_transaction_status(id: TransactionId, ok: boolean, delay: number?)
    cached_transaction_status[id] = ok
    table.insert(cached_transaction_lifetime, { id = id, lifetime = os.clock() + TRANSACTION_MAX_LIFETIME })
end

local function request_for_transaction(id: TransactionId)
    local TRANSACTION_STORE = flags.datastoreservice:GetDataStore(TRANSACTION_NAME, TRANSACTION_SCOPE)

    local result: boolean? = retry.exponential_backoff(function()
        return TRANSACTION_STORE:GetAsync(id)
    end)

    set_transaction_status(id, if result then true else false)
end

local function is_transaction_complete(id: TransactionId): CompletionStatus
    local value = cached_transaction_status[id]
    if value == true then
        return "completed"
    elseif value == false then
        return "failed"
    else
        task.spawn(request_for_transaction, id)
        if cached_transaction_status[id] then return "completed" end -- the transaction was stored in the cache
        return "unknown"
    end
end

local function flush_transactions()
    while
        cached_transaction_lifetime[1]
        and cached_transaction_lifetime[1].lifetime < os.clock()
        or #cached_transaction_lifetime > MAX_STORED_TRANSACTIONS
    do
        table.remove(cached_transaction_lifetime, 1)
    end
end

return {
    request_for_transaction = request_for_transaction,
    is_transaction_complete = is_transaction_complete,
    set_transaction_status = set_transaction_status,
    flush_transactions = flush_transactions
}