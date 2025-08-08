# Context7 Documentation Tool Usage Rules

## When to Use Context7

### ALWAYS Use Context7 For:
1. **Library/Framework Documentation Requests**
   - User asks: "How do I use X library?"
   - User asks: "Show me examples of Y framework"
   - User asks: "What's the API for Z package?"

2. **Setup and Configuration Requests**
   - User asks: "How do I set up X?"
   - User asks: "What's the configuration for Y?"
   - User asks: "How do I install Z?"

3. **Code Examples Requests**
   - User asks: "Give me an example of X"
   - User asks: "Show me how to implement Y"
   - User asks: "What's the syntax for Z?"

## How to Use Context7

### Step 1: Resolve Library ID
```
Use: mcp__context7__resolve-library-id
Input: The library/package name from user's request
Output: Context7-compatible library ID
```

### Step 2: Get Documentation
```
Use: mcp__context7__get-library-docs
Input: The library ID from step 1
Optional: topic (specific area of focus)
Optional: tokens (amount of documentation to retrieve)
```

## Examples

### Example 1: User asks about React hooks
1. Call: `resolve-library-id` with `libraryName: "react"`
2. Get library ID like `/facebook/react`
3. Call: `get-library-docs` with `context7CompatibleLibraryID: "/facebook/react"` and `topic: "hooks"`

### Example 2: User asks about Next.js routing
1. Call: `resolve-library-id` with `libraryName: "next.js"` 
2. Get library ID like `/vercel/next.js`
3. Call: `get-library-docs` with `context7CompatibleLibraryID: "/vercel/next.js"` and `topic: "routing"`

### Example 3: User asks about MongoDB queries
1. Call: `resolve-library-id` with `libraryName: "mongodb"`
2. Get library ID like `/mongodb/docs`
3. Call: `get-library-docs` with `context7CompatibleLibraryID: "/mongodb/docs"` and `topic: "queries"`

## Important Notes

- **ALWAYS use Context7 BEFORE** attempting to provide documentation from memory
- **ALWAYS use Context7 BEFORE** generating code examples that might be outdated
- **ALWAYS use Context7 WHEN** user explicitly asks for library/API documentation
- **Context7 provides up-to-date documentation** - prefer it over general knowledge

## Integration with Task Execution

When executing tasks that require library documentation:
1. Check if task involves external libraries/frameworks
2. Use Context7 to get latest documentation before implementation
3. Reference the documentation in your implementation
4. Include relevant documentation snippets in comments if helpful

This ensures all code implementations use the latest, most accurate library documentation.