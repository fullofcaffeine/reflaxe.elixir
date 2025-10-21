# HXX Type Safety System - Complete Guide

## Overview

The HXX Type Safety System provides **TypeScript JSX-equivalent type safety** for Phoenix HEEx templates in Haxe. This means you get the same compile-time validation, IntelliSense support, and developer experience as React developers enjoy with TypeScript.

## Table of Contents
- [Quick Start](#quick-start)
- [Core Concepts](#core-concepts)
- [Type System Architecture](#type-system-architecture)
- [HTML Element Types](#html-element-types)
- [Phoenix LiveView Integration](#phoenix-liveview-integration)
- [Attribute Naming Convention](#attribute-naming-convention)
- [Error Messages and Validation](#error-messages-and-validation)
- [Comparison with React/TypeScript](#comparison-with-react-typescript)
- [Advanced Patterns](#advanced-patterns)
- [API Reference](#api-reference)

## Quick Start

### Basic Usage

```haxe
import reflaxe.elixir.macro.HXX;
import phoenix.types.HXXTypes;

class MyComponent {
    static function render() {
        // Type-safe template with full IntelliSense
        return HXX.hxx('
            <div className="container">
                <h1>Welcome</h1>
                <input type="email" 
                       name="userEmail"
                       placeholder="Enter email"
                       required
                       phxChange="validate" />
                <button type="submit" 
                        phxClick="submit">
                    Submit
                </button>
            </div>
        ');
    }
}
```

### Type-Safe Attributes

```haxe
// Define attributes with full type safety
var inputAttrs: InputAttributes = {
    type: Email,              // Enum value, not string
    name: "userEmail",        // camelCase naming
    required: true,           // Boolean type
    placeholder: "Email",     // String type
    phxChange: "validate"     // Phoenix directive
};

// Compile-time error for invalid attributes
var invalid: InputAttributes = {
    unknownAttr: "value"  // ❌ Compiler error: unknownAttr doesn't exist
};
```

## Core Concepts

### 1. Zero Runtime Overhead

All type checking happens at compile time. The type definitions are completely removed from the generated Elixir code, resulting in zero runtime overhead.

### 2. Complete HTML5 Coverage

Every standard HTML5 element and attribute is typed:
- Form elements: input, button, select, textarea, form
- Text content: p, div, span, h1-h6
- Media: img, video, audio
- Tables: table, tr, td, th
- Lists: ul, ol, li
- Semantic: article, section, nav, header, footer

### 3. Phoenix LiveView First-Class Support

All Phoenix LiveView directives are fully typed:
- Events: phxClick, phxChange, phxSubmit, phxFocus, phxBlur
- Keyboard: phxKeydown, phxKeyup
- Mouse: phxMouseenter, phxMouseleave
- Hooks: phxHook
- Navigation: phxLink, phxLinkState
- Performance: phxDebounce, phxThrottle
- Updates: phxUpdate, phxTrackStatic

## Type System Architecture

### Layer 1: Global Attributes

```haxe
typedef GlobalAttributes = {
    // Core HTML
    ?id: String,
    ?className: String,      // Maps to 'class'
    ?style: String,
    ?title: String,
    
    // Accessibility
    ?role: String,
    ?ariaLabel: String,      // Maps to 'aria-label'
    ?ariaHidden: Bool,
    ?tabIndex: Int,
    
    // Phoenix LiveView
    ?phxClick: String,       // Maps to 'phx-click'
    ?phxChange: String,      // Maps to 'phx-change'
    // ... all phx-* directives
}
```

### Layer 2: Element-Specific Attributes

```haxe
typedef InputAttributes = GlobalAttributes & {
    ?type: InputType,        // Enum for type safety
    ?name: String,
    ?value: Dynamic,
    ?placeholder: String,
    ?required: Bool,
    ?disabled: Bool,
    // ... input-specific attributes
}
```

### Layer 3: Component Registry

The registry validates elements and attributes at compile time:

```haxe
// Registry knows all valid HTML elements
HXXComponentRegistry.isRegisteredElement("input");  // true
HXXComponentRegistry.isRegisteredElement("fake");   // false

// Validates attribute combinations
HXXComponentRegistry.validateAttribute("input", "type");      // true
HXXComponentRegistry.validateAttribute("input", "href");      // false (href is for <a>)
```

## HTML Element Types

### Form Elements

```haxe
// Input with type safety
var emailInput: InputAttributes = {
    type: Email,
    name: "email",
    required: true,
    pattern: "[a-z0-9._%+-]+@[a-z0-9.-]+\\.[a-z]{2,}$"
};

// Select with options
var countrySelect: SelectAttributes = {
    name: "country",
    required: true,
    multiple: false
};

// Button with type enum
var submitButton: ButtonAttributes = {
    type: Submit,        // Not "submit" string
    disabled: false,
    phxClick: "save"
};
```

### Enums for Type Safety

```haxe
enum abstract InputType(String) to String {
    var Text = "text";
    var Email = "email";
    var Password = "password";
    var Number = "number";
    var Date = "date";
    var Checkbox = "checkbox";
    var Radio = "radio";
    var Submit = "submit";
    // ... all HTML5 input types
}

enum abstract ButtonType(String) to String {
    var Button = "button";
    var Submit = "submit";
    var Reset = "reset";
}
```

## Phoenix LiveView Integration

### Event Handlers

```haxe
HXX.hxx('
    <div phxClick="clicked"
         phxChange="changed"
         phxSubmit="submitted"
         phxFocus="focused"
         phxBlur="blurred"
         phxKeydown="keyPressed"
         phxKeyup="keyReleased">
        Interactive content
    </div>
');
```

### Live Navigation

```haxe
HXX.hxx('
    <a href="/users" 
       phxLink="patch"           // or "redirect"
       phxLinkState="push">      // or "replace"
        View Users
    </a>
');
```

### Performance Optimization

```haxe
HXX.hxx('
    <input phxDebounce="300"     // Debounce input by 300ms
           phxThrottle="1000"     // Throttle to once per second
           phxUpdate="stream"     // Update strategy
           phxTrackStatic="true"  // Track static content
           phxChange="search" />
');
```

## Attribute Naming Convention

### Flexible Naming: camelCase, snake_case, or kebab-case

The system supports all three naming conventions and automatically converts to kebab-case for HTML output:

| Input Style | Examples | HTML Output |
|-------------|----------|-------------|
| **camelCase** | `className`, `phxClick`, `ariaLabel` | `class`, `phx-click`, `aria-label` |
| **snake_case** | `class_name`, `phx_click`, `aria_label` | `class`, `phx-click`, `aria-label` |
| **kebab-case** | `data-test-id`, `phx-hook` | `data-test-id`, `phx-hook` (preserved) |

### Conversion Examples

| Your Code | HTML Output |
|-----------|-------------|
| `className="container"` | `class="container"` |
| `class_name="container"` | `class="container"` |
| `htmlFor="email"` | `for="email"` |
| `html_for="email"` | `for="email"` |
| `ariaLabel="Submit"` | `aria-label="Submit"` |
| `aria_label="Submit"` | `aria-label="Submit"` |
| `dataTestId="btn"` | `data-test-id="btn"` |
| `data_test_id="btn"` | `data-test-id="btn"` |
| `phxClick="save"` | `phx-click="save"` |
| `phx_click="save"` | `phx-click="save"` |
| `phx-click="save"` | `phx-click="save"` |

### Example: Mixed Naming Styles

```haxe
// You can mix camelCase, snake_case, and kebab-case freely
HXX.hxx('
    <div className="container"           // camelCase
         data_user_id="123"              // snake_case  
         phx-hook="ScrollTracker">       // kebab-case (preserved)
        
        <label htmlFor="email">Email</label>      // camelCase
        <input phx_change="validate"              // snake_case
               aria-label="Email input"           // kebab-case
               dataTestId="emailField" />         // camelCase
               
        <button phxClick="submit"                 // camelCase
                aria_describedby="help_text">     // snake_case
            Submit
        </button>
    </div>
');
```

All styles generate valid HEEx:

```heex
<div class="container"
     data-user-id="123"
     phx-hook="ScrollTracker">
    
    <label for="email">Email</label>
    <input phx-change="validate"
           aria-label="Email input"
           data-test-id="email-field" />
           
    <button phx-click="submit"
            aria-describedby="help-text">
        Submit
    </button>
</div>
```

### Developer Choice

Use whichever style you prefer or mix them based on context:
- **camelCase**: Traditional Haxe/JavaScript style
- **snake_case**: Comfortable for Elixir/Phoenix developers  
- **kebab-case**: Direct HTML attribute style

The type safety system validates all styles equally!

## Error Messages and Validation

### Compile-Time Validation

The system catches errors at compile time with helpful messages:

```haxe
// Unknown attribute error
HXX.hxx('<input invalidAttr="test" />');
// Error: Unknown attribute "invalidAttr" for <input>. 
// Did you mean: disabled, id, name? Available: type, value, placeholder...

// Unknown element error
HXX.hxx('<customElement>Content</customElement>');
// Error: Unknown HTML element: <customElement>. 
// If this is a custom component, register it first.

// Typo suggestions
HXX.hxx('<input placeHolder="text" />');
// Error: Unknown attribute "placeHolder" for <input>.
// Did you mean: placeholder?
```

### Type Mismatch Errors

```haxe
var input: InputAttributes = {
    type: "invalid",     // ❌ Error: String not assignable to InputType
    required: "yes",     // ❌ Error: String not assignable to Bool
    tabIndex: "1"        // ❌ Error: String not assignable to Int
};
```

## Comparison with React/TypeScript

### Feature Parity

| Feature | React/TypeScript JSX | HXX Type Safety |
|---------|---------------------|-----------------|
| **Type Checking** | ✅ Full element/attribute validation | ✅ Full element/attribute validation |
| **IntelliSense** | ✅ Complete IDE support | ✅ Complete IDE support |
| **Error Messages** | ✅ Helpful compile-time errors | ✅ Helpful compile-time errors |
| **Custom Components** | ✅ Component definitions | ✅ Phoenix components |
| **Event Types** | ✅ Typed event handlers | ✅ Typed phx-* handlers |
| **Generic Components** | ✅ `<T>` generics | ✅ Generic support |
| **Conditional Rendering** | ✅ JSX expressions | ✅ HXX expressions |
| **Lists/Loops** | ✅ `array.map()` | ✅ `array.map()` |
| **Fragments** | ✅ `<>...</>` | ✅ Template composition |
| **Refs** | ✅ `useRef` | 🔄 Phoenix hooks |
| **Context** | ✅ React Context | 🔄 Phoenix assigns |
| **Zero Runtime Cost** | ✅ Types erased | ✅ Types erased |

### Code Comparison

**React/TypeScript:**
```tsx
const MyComponent: React.FC<Props> = ({ user }) => {
    return (
        <div className="container">
            <input 
                type="email"
                onChange={handleChange}
                aria-label="Email"
            />
        </div>
    );
};
```

**HXX/Haxe:**
```haxe
function render(user: User) {
    return HXX.hxx('
        <div className="container">
            <input 
                type="email"
                phxChange="handleChange"
                ariaLabel="Email"
            />
        </div>
    ');
}
```

## Advanced Patterns

### Typed Component Props

```haxe
typedef TodoItemProps = {
    todo: Todo,
    onToggle: Int -> Void,
    onDelete: Int -> Void
}

function TodoItem(props: TodoItemProps) {
    return HXX.hxx('
        <div className="todoItem">
            <input type="checkbox"
                   checked="${props.todo.completed}"
                   phxClick="toggle"
                   phxValue="${props.todo.id}" />
            <span>${props.todo.title}</span>
            <button phxClick="delete"
                    phxValue="${props.todo.id}">
                Delete
            </button>
        </div>
    ');
}
```

### Dynamic Attributes

```haxe
function renderInput(attrs: InputAttributes) {
    // Merge default and custom attributes
    var finalAttrs = Reflect.copy(attrs);
    finalAttrs.className = "form-control " + (attrs.className ?? "");
    
    return HXX.hxx('<input {...finalAttrs} />');
}
```

### Conditional Classes

```haxe
HXX.hxx('
    <div className="${isActive ? "active" : "inactive"} ${isPrimary ? "primary" : ""}">
        Content
    </div>
');
```

### List Rendering

```haxe
HXX.hxx('
    <ul>
        ${items.map(item -> HXX.hxx('
            <li key="${item.id}" className="${item.done ? "completed" : ""}">
                ${item.text}
            </li>
        ')).join("")}
    </ul>
');
```

## API Reference

### Core Types

```haxe
// Main template macro
class HXX {
    public static macro function hxx(template: Expr): Expr;
}

// Component registry
class HXXComponentRegistry {
    public static function isRegisteredElement(name: String): Bool;
    public static function validateAttribute(element: String, attr: String): Bool;
    public static function getAllowedAttributes(element: String): Array<String>;
    public static function toHtmlAttribute(name: String): String;
}

// Type definitions
typedef GlobalAttributes = { /* ... */ }
typedef InputAttributes = GlobalAttributes & { /* ... */ }
typedef ButtonAttributes = GlobalAttributes & { /* ... */ }
// ... all HTML elements
```

### Registering Custom Components

```haxe
// Register a Phoenix component
HXXComponentRegistry.registerComponent({
    name: "button",
    attributes: [
        {name: "type", type: "String", values: ["primary", "secondary", "danger"]},
        {name: "size", type: "String", values: ["sm", "md", "lg"]},
        {name: "loading", type: "Bool"}
    ],
    slots: [
        {name: "inner_block", required: true}
    ]
});

// Now you can use it type-safely
HXX.hxx('<.button type="primary" size="lg">Click me</.button>');
```

## Best Practices

### 1. Use Type Definitions

Always define types for complex attribute sets:

```haxe
typedef FormFieldProps = {
    label: String,
    name: String,
    value: String,
    error: Null<String>,
    required: Bool
}
```

### 2. Leverage IntelliSense

Let your IDE help you:
- Start typing an attribute to see all options
- Hover over attributes to see their types
- Use Go to Definition to explore type definitions

### 3. Keep Templates Readable

Break complex templates into smaller functions:

```haxe
function renderHeader() { /* ... */ }
function renderBody() { /* ... */ }
function renderFooter() { /* ... */ }

function render() {
    return HXX.hxx('
        <div className="app">
            ${renderHeader()}
            ${renderBody()}
            ${renderFooter()}
        </div>
    ');
}
```

### 4. Type Your Event Handlers

Define types for event parameters:

```haxe
typedef FormEvent = {
    target: {
        name: String,
        value: String
    }
}

function handleChange(event: FormEvent) {
    // Type-safe event handling
}
```

## Troubleshooting

### Common Issues

**Issue**: Attribute not recognized
```haxe
// Problem
HXX.hxx('<input onclick="handler" />');  // onclick is React, not Phoenix

// Solution
HXX.hxx('<input phxClick="handler" />'); // Use Phoenix directive
```

**Issue**: Case sensitivity
```haxe
// Problem
HXX.hxx('<div classname="container" />');  // lowercase 'n'

// Solution  
HXX.hxx('<div className="container" />');   // camelCase
```

**Issue**: Custom components not recognized
```haxe
// Problem
HXX.hxx('<MyComponent />');  // Not registered

// Solution
// Either use Phoenix component syntax
HXX.hxx('<.my_component />');

// Or register the component first
HXXComponentRegistry.registerComponent(myComponentDef);
```

## Summary

The HXX Type Safety System brings the full power of TypeScript JSX-like type checking to Phoenix HEEx templates. With zero runtime overhead, comprehensive HTML5 coverage, and first-class Phoenix LiveView support, you get the best possible developer experience for building type-safe Phoenix applications in Haxe.

Key benefits:
- ✅ **Compile-time validation** catches errors before runtime
- ✅ **Full IntelliSense** support in your IDE
- ✅ **Automatic conversions** from camelCase to kebab-case
- ✅ **Helpful error messages** with suggestions
- ✅ **Zero runtime cost** - types are compile-time only
- ✅ **React/TypeScript equivalent** developer experience

## HEEx Assigns Linter (raw ~H)

HXX templates can contain both typed HXX expressions and raw HEEx (EEx) content:

- Typed HXX expression (checked by Haxe):
  ```haxe
  return HXX.hxx('<div>${assigns.user.name}</div>');
  ```

- Raw HEEx inside HXX (checked by linter):
  ```haxe
  return HXX.hxx('<div><%= @user.name %></div>');
  ```

Because raw HEEx is inside a string literal, the Haxe typer cannot see it. To keep safety, the compiler runs a pass — HEEx Assigns Type Linter — which scans `~H` content for:

- Unknown `@assigns` fields
- Obvious literal type mismatches using `@field`

Errors are reported at Haxe compile-time. See docs/03-compiler-development/heex-assigns-type-linter.md for details and examples.
