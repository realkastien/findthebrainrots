local types = require("./types")

type TransactionInfo = types.TransactionInfo

local function inline_test(): string
    return debug.info(1, "n")
end

local is_O2 = inline_test() ~= "inline_test"

return {
    processing_transaction = false :: false | TransactionInfo,
    disable_new_actions = false,
    strict = not is_O2,
    print = false,

    datastoreservice = if game then game:GetService("DataStoreService") else nil
}