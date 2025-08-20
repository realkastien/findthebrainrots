# Fusion 0.3.0 API Guide

## Overview

This guide covers the key differences between Fusion 0.2.x and Fusion 0.3.0 APIs, specifically focusing on the scope-based approach introduced in version 0.3.0.

## Key Changes from Fusion 0.2.x to 0.3.0

### 1. Scope-Based Architecture
In Fusion 0.3.0, all components must be created within a **scope**. This replaces the global function approach from earlier versions.

#### ❌ Old Way (Fusion 0.2.x)
```luau
local Fusion = require(ReplicatedStorage.Packages.fusion)
local New = Fusion.New
local Value = Fusion.Value
local Computed = Fusion.Computed

local function myComponent()
    local state = Value(false)
    return New("TextButton")({
        Text = "Click me",
        -- ...
    })
end
```

#### ✅ New Way (Fusion 0.3.0)
```luau
local Fusion = require(ReplicatedStorage.Packages.fusion)
local scoped = Fusion.scoped
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

-- Components accept scope as first parameter
local function MyComponent(scope, props)
    local State = scope:Value(false)
    
    return scope:New("TextButton")({
        Text = "Click me",
        -- ...
    })
end

-- Top-level interface creates and manages the scope
local function MyInterface()
    local scope = scoped(Fusion)
    
    return scope:New("ScreenGui")({
        [Children] = {
            MyComponent(scope, { text = "Hello" })
        }
    })
end
```

## Component Architecture Patterns

### Component Function Signature

All Fusion components should follow this signature pattern:

```luau
local function ComponentName(scope: Fusion.Scope, props: table): Instance
    -- Component implementation
end
```

**Key Points:**
- **First parameter**: Always accept `scope` as the first parameter
- **Second parameter**: Accept `props` table for configuration
- **Return type**: Return a Roblox Instance (Frame, TextButton, etc.)
- **No scope creation**: Never create a scope inside the component

### Scope Lifecycle Management

```luau
-- ✅ CORRECT: Interface manages scope
local function GameMenu()
    local scope = scoped(Fusion)  -- Create scope once at interface level
    
    return scope:New("ScreenGui")({
        [Children] = {
            -- Pass scope to all child components
            PlayButton(scope, { onClick = startGame }),
            SettingsButton(scope, { onClick = openSettings }),
            QuitButton(scope, { onClick = quitGame }),
        }
    })
end

-- ❌ WRONG: Each component creates its own scope
local function BadComponent(props)
    local scope = scoped(Fusion)  -- DON'T DO THIS
    -- This creates memory management issues and breaks cleanup
end
```

### Memory Benefits

By passing scopes from parent to child:
- **Single cleanup point**: When the interface is destroyed, all components clean up automatically
- **Better performance**: Fewer scope objects created
- **Predictable lifecycle**: Clear ownership of resources
- **Easier debugging**: Single scope to track for memory leaks

## Core API Changes

### Creating Components

Components should accept a scope as their first parameter and use it for all Fusion operations:

```luau
-- Component function signature: (scope, props) -> Instance
local function MyComponent(scope, props)
    -- Use provided scope instead of creating one
    local MyValue = scope:Value(false)
    local MyComputed = scope:Computed(function(use)
        return use(MyValue) and "On" or "Off"
    end)
    local MySpring = scope:Spring(MyValue, TweenInfo.new(0.3))

    -- Create instances through provided scope
    return scope:New("TextButton")({
        Text = MyComputed,
        BackgroundColor3 = MySpring,
        -- ...
    })
end

-- Usage in interface:
local function MainInterface()
    local scope = scoped(Fusion)
    
    return scope:New("ScreenGui")({
        [Children] = {
            MyComponent(scope, { enabled = true })
        }
    })
end
```

### State Management

State objects are created through the scope and use a `use` function in computed values:

```luau
local scope = scoped(Fusion)

-- Create state
local IsHovered = scope:Value(false)
local IsPressed = scope:Value(false)

-- Computed values use 'use' function parameter
local BackgroundColor = scope:Computed(function(use)
    if use(IsPressed) then
        return Color3.fromRGB(200, 200, 200)
    elseif use(IsHovered) then
        return Color3.fromRGB(230, 230, 230)
    else
        return Color3.fromRGB(255, 255, 255)
    end
end)
```

### Event Handling

Event handling remains similar but properties are accessed through scope:

```luau
scope:New("TextButton")({
    [OnEvent("MouseEnter")] = function()
        IsHovered:set(true)
    end,
    
    [OnEvent("MouseLeave")] = function()
        IsHovered:set(false)
    end,
    
    [OnEvent("Activated")] = function()
        if props.onClick then
            props.onClick()
        end
    end,
})
```

## Card Button Component Example

Here's a complete example of a Fusion 0.3.0 component following the coding guidelines:

```luau
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Fusion = require(ReplicatedStorage.Packages.fusion)

-- Fusion imports
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

-- Constants using SCREAMING_SNAKE_CASE
local CARD_COLORS = {
    BACKGROUND = Color3.fromRGB(45, 50, 65),
    BACKGROUND_HOVER = Color3.fromRGB(55, 60, 75),
    BACKGROUND_PRESSED = Color3.fromRGB(35, 40, 55),
    BORDER = Color3.fromRGB(70, 80, 100),
    TEXT = Color3.fromRGB(255, 255, 255),
    TEXT_DISABLED = Color3.fromRGB(150, 150, 150),
}

local ANIMATION_INFO = TweenInfo.new(
    0.15,
    Enum.EasingStyle.Quad,
    Enum.EasingDirection.Out
)

-- PascalCase for local function
-- Component accepts scope as parameter instead of creating its own
local function CardButton(scope, props)
    -- PascalCase for variables
    local IsHovered = scope:Value(false)
    local IsPressed = scope:Value(false)
    local Enabled = if props.enabled ~= nil then props.enabled else true
    
    -- Computed styles using 'use' function
    local BackgroundColor = scope:Computed(function(use)
        if not Enabled then
            return CARD_COLORS.BACKGROUND
        elseif use(IsPressed) then
            return CARD_COLORS.BACKGROUND_PRESSED
        elseif use(IsHovered) then
            return CARD_COLORS.BACKGROUND_HOVER
        else
            return CARD_COLORS.BACKGROUND
        end
    end)
    
    local TextColor = scope:Computed(function()
        return if Enabled then CARD_COLORS.TEXT else CARD_COLORS.TEXT_DISABLED
    end)
    
    -- Animated properties
    local AnimatedBackground = scope:Spring(BackgroundColor, ANIMATION_INFO)
    
    -- Create the component
    return scope:New("TextButton")({
        Name = "CardButton",
        Size = props.size or UDim2.new(0, 120, 0, 40),
        BackgroundColor3 = AnimatedBackground,
        
        [OnEvent("MouseEnter")] = function()
            if Enabled then
                IsHovered:set(true)
            end
        end,
        
        [OnEvent("MouseLeave")] = function()
            IsHovered:set(false)
            IsPressed:set(false)
        end,
        
        [Children] = {
            scope:New("UICorner")({
                CornerRadius = UDim.new(0, 8),
            }),
            
            -- Additional children...
        }
    })
end

return CardButton
```

### Using Components in Interfaces

When using components within an interface, create the scope at the interface level and pass it to components:

```luau
-- In a top-level interface module
local function GameInterface()
    local scope = scoped(Fusion)
    
    return scope:New("ScreenGui")({
        [Children] = {
            -- Pass scope to component instead of letting it create its own
            CardButton(scope, {
                text = "Play",
                size = UDim2.new(0, 200, 0, 50),
                onClick = function()
                    print("Play button clicked!")
                end
            }),
            
            CardButton(scope, {
                text = "Settings", 
                size = UDim2.new(0, 200, 0, 50),
                onClick = function()
                    print("Settings button clicked!")
                end
            }),
        }
    })
end
```

## Best Practices

### 1. Scope Management
- **Components should accept a scope as a parameter** rather than creating their own scope
- This allows parent interfaces to manage the scope lifecycle and memory cleanup
- Only create scopes in top-level interface modules, not in individual components
- Access all Fusion functions through the provided scope (e.g., `scope:New`, `scope:Value`)

### 2. State Naming
- Use **PascalCase** for state variables (following the coding guidelines)
- Use descriptive names: `IsHovered`, `CurrentIndex`, `SelectedItem`

### 3. Computed Functions
- Always use the `use` function parameter in computed values
- Call `use(stateObject)` to read state values
- Keep computed functions pure (no side effects)

### 4. Event Handlers
- Use `OnEvent` for all Roblox events
- Handle state updates in event callbacks
- Remember to clean up state when components unmount

### 5. Memory Management
- Scopes automatically handle cleanup when components are destroyed
- No need for manual cleanup in most cases
- Scope-based architecture prevents memory leaks

## Common Errors and Solutions

### Error: "scopeMissing"
```
External.logError("scopeMissing", nil, "instances using New", "myScope:New \"" .. scope .. "\" { ... }")
```

**Solution:** Always create a scope first:
```luau
local scope = scoped(Fusion)
local MyButton = scope:New("TextButton")({}) -- ✅ Correct
```

### Error: "Unknown global 'New'"
This happens when trying to use the old global API.

**Solution:** Use scope methods:
```luau
-- ❌ Wrong
local Button = New("TextButton")({})

-- ✅ Correct
local scope = scoped(Fusion)
local Button = scope:New("TextButton")({})
```

### Error: "Variable 'someImport' is never used"
This happens when importing functions that are now scope-based.

**Solution:** Remove unused imports and use scope methods:
```luau
-- ❌ Remove unused imports
local New = Fusion.New
local Value = Fusion.Value

-- ✅ Use scope methods instead
local scope = scoped(Fusion)
local myValue = scope:Value(false)
```

## Conclusion

Fusion 0.3.0's scope-based approach provides better memory management and cleaner component architecture. While it requires updating existing code, the benefits include:

- Automatic cleanup and memory management
- Better component isolation
- Improved debugging capabilities
- More explicit dependency management

Always use scopes for new components and gradually migrate existing components when possible.
