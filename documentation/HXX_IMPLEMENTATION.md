# HXX Template Processing Implementation

## Overview
HXX (Haxe JSX) provides JSX-like syntax for creating Phoenix HEEx templates directly in Haxe code. This document details the complete implementation of HXX template processing in Reflaxe.Elixir.

## Architecture

### Template Processing Pipeline
```
HXX Source → Haxe AST → Raw String Extraction → HEEx Conversion → Phoenix Template
```

### Core Components

#### 1. HXX Call Detection (ElixirCompiler.hx)
```haxe
case TCall(e, args):
    if (isHxxCall(e)) {
        return compileHxxCall(e, args);
    }

private function isHxxCall(e: TypedExpr): Bool {
    return switch (e.expr) {
        case TField(_, field): field.name == "HXX";
        case _: false;
    };
}
```

#### 2. Template Content Extraction
```haxe
private function compileHxxCall(e: TypedExpr, args: Array<TypedExpr>): String {
    // Extract raw template content before any escaping
    var rawContent = extractRawStringFromTBinop(args[0]);
    if (rawContent != null) {
        var processed = processHxxTemplate(rawContent);
        return formatHxxTemplate(processed);
    }
    // Fallback to compiled version if extraction fails
    var compiled = compileExpression(args[0]);
    return compiled;
}
```

#### 3. Critical TBinop Handling
**Problem**: Multiline HXX templates are parsed as TBinop(OpAdd) expressions that concatenate string literals. Standard compilation escapes quotes before processing, breaking HTML attribute syntax.

**Solution**: Extract raw strings directly from AST before any escaping occurs.

```haxe
case TBinop(OpAdd, _, _):
    // Handle string concatenation (multiline strings with interpolation)
    // 
    // When HXX templates contain multiline strings, Haxe parses them as TBinop(OpAdd)
    // expressions that concatenate string literals. The old approach compiled these
    // expressions first, which escaped quotes (class="x" -> class=\"x\"), then 
    // extracted content from the escaped string. This caused invalid HEEx syntax.
    //
    // NEW APPROACH: Extract raw string content directly from the AST before any
    // escaping occurs, then process it as HXX template. This preserves HTML 
    // attribute quotes in the correct HEEx format.
    var rawContent = extractRawStringFromTBinop(args[0]);
    if (rawContent != null) {
        var processed = processHxxTemplate(rawContent);
        return formatHxxTemplate(processed);
    }
    // Fallback to compiled version if extraction fails (non-string expressions)
    var compiled = compileExpression(args[0]);
    return compiled;
```

#### 4. Raw String Extraction
```haxe
private function extractRawStringFromTBinop(expr: TypedExpr): Null<String> {
    return switch (expr.expr) {
        case TBinop(OpAdd, e1, e2):
            var left = extractRawStringFromTBinop(e1);
            var right = extractRawStringFromTBinop(e2);
            if (left != null && right != null) {
                return left + right;
            }
            return null;
            
        case TConst(TString(s)):
            return s;
            
        case _:
            return null;
    };
}
```

#### 5. HEEx Syntax Conversion
```haxe
private function processHxxTemplate(content: String): String {
    var processed = content;
    
    // Convert Haxe interpolation ${} to HEEx interpolation {}
    processed = ~/\$\{([^}]+)\}/g.replace(processed, '{$1}');
    
    // Preserve HTML attributes and proper HEEx formatting
    return processed;
}

private function formatHxxTemplate(content: String): String {
    return '~H"""\n$content\n"""';
}
```

## Usage Examples

### Basic HXX Template
**Haxe Code**:
```haxe
function render(assigns: Dynamic): String {
    return HXX('
        <div class="user-management" data-test="user-form">
            <h1>User Management</h1>
            <p>Welcome, ${assigns.current_user.name}!</p>
        </div>
    ');
}
```

**Generated Elixir**:
```elixir
def render(assigns) do
    ~H"""
    <div class="user-management" data-test="user-form">
        <h1>User Management</h1>
        <p>Welcome, {assigns.current_user.name}!</p>
    </div>
    """
end
```

### Multiline Templates with Interpolation
**Haxe Code**:
```haxe
function userCard(user: User): String {
    return HXX('
        <div class="user-card" id="user-${user.id}">
            <h3>${user.name}</h3>
            <p class="email">${user.email}</p>
            <span class="status ${user.active ? "active" : "inactive"}">
                ${user.active ? "Active" : "Inactive"}
            </span>
        </div>
    ');
}
```

**Generated Elixir**:
```elixir
def user_card(user) do
    ~H"""
    <div class="user-card" id={"user-#{user.id}"}>
        <h3>{user.name}</h3>
        <p class="email">{user.email}</p>
        <span class={"status #{if user.active, do: "active", else: "inactive"}"}>
            {if user.active, do: "Active", else: "Inactive"}
        </span>
    </div>
    """
end
```

## Technical Insights

### Why Raw String Extraction is Critical
1. **HTML Attribute Preservation**: Prevents escaping of quotes in HTML attributes
2. **HEEx Compatibility**: Maintains proper syntax for Phoenix LiveView templates
3. **Interpolation Handling**: Allows proper conversion from Haxe ${} to HEEx {} syntax

### AST Processing Strategy
1. **Early Extraction**: Process strings before standard compilation escaping
2. **Recursive Handling**: Support complex nested string concatenations
3. **Fallback Safety**: Use compiled version if raw extraction fails

### Integration with Phoenix LiveView
- **Template Format**: Generates proper ~H sigil format
- **Interpolation Syntax**: Uses HEEx {} instead of EEx <%= %>
- **Attribute Handling**: Preserves HTML attribute quotes correctly
- **LiveView Compatibility**: Full integration with Phoenix LiveView rendering

## Known Limitations
1. **String Literals Only**: Currently supports only string literal templates (no dynamic template construction)
2. **Simple Interpolation**: Basic ${} to {} conversion (complex expressions may need manual handling)
3. **No Validation**: Template syntax is not validated at compile time

## Future Enhancements
1. **Template Validation**: Add HEEx syntax validation during compilation
2. **Dynamic Templates**: Support for dynamically constructed templates
3. **Component Integration**: Better integration with Phoenix LiveView components
4. **Error Reporting**: Enhanced error messages for template syntax issues

## Testing
HXX implementation is tested through:
- **Snapshot Tests**: Verify proper code generation
- **Integration Tests**: Ensure templates compile in Phoenix projects
- **Todo App Example**: Real-world usage validation

See `test/tests/hxx_template/` for comprehensive test cases.