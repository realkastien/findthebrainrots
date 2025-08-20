# Variables
- Variables are written in snake_case
- Variables that reference ROBLOX SERVICES are written in PascalCase
- Constants are written in SCREAMING_SNAKE_CASE
## Example
```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- ROBLOX SERVICE
local client_assets = ReplicatedStorage:WaitForChild("Assets") -- VARIABLE

local cache = {} -- VARIABLE

local ASSETS_TO_CACHE = 10 -- CONSTANT, NEVER CHANGES VALUE

for index: number, asset: Instance in client_assets:GetChildren() do 
    if index > ASSETS_TO_CACHE then 
        break 
    end

    table.insert(cache, asset)
end
```

# Local Functions
- Local functions are written in snake_case
## Example
```lua
local function my_function(my_parameter: string): ()
    print(my_parameter)
end
```

# Classes
- Class constructors are written in camelCase
- Class methods are written in PascalCase
- Strictly type the class, object and methods
## Example
```lua 
type MyClassMethods = {
    Destroy: ()->()
}

type MyClass = {
    __index: MyClassMethods,
    doSomething: (some_parameter: number)->MyObject
}

-- setmetatable<> is a type function which takes two parameters, both should be tables, the first one is the table and the second one is the metatable
type MyObject = setmetatable<{
    parameter: number
}, MyClass>

local MyClassMethods = {}

local MyClass = {}
MyClass.__index = MyClassMethods

function MyClass.doSomething(some_parameter: number): MyObject
    local self: MyObject = setmetatable({
        parameter = some_parameter
    }, MyClass)

    return self
end

function MyClassMethods.Destroy(self: MyObject): ()

end
```

# Files 
- Files are written in snake_case
- Folders are written in snake_case