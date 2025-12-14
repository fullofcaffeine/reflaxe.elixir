# Async/Await Documentation Migration Notes

## Migration from reflaxe.js.Async to genes.AsyncMacro

### Old Approach (DEPRECATED)
- Used `reflaxe.js.Async` and `AsyncJSGenerator`
- Required `Async.await()` function calls
- Custom JavaScript generator with wrapper functions

### New Approach (CURRENT)
- Uses `genes` library with `genes.AsyncMacro`
- Clean `@:async` and `@:await` metadata syntax
- Generates native ES6 async/await without wrappers

### Files to Update
The following documentation files contain outdated references and should be updated or removed:

1. `/docs/02-user-guide/JS_GENERATION_PHILOSOPHY.md` - Update to reference genes
2. `/docs/07-patterns/FULL_STACK_DEVELOPMENT.md` - Update AsyncJSGenerator references
3. `/docs/07-patterns/TODO_APP_CLEANUP_LESSONS.md` - Remove reflaxe.js.Async references
4. `/docs/06-guides/FULL_STACK_DEVELOPMENT.md` - Update to genes approach
5. `/docs/05-architecture/ASYNC_AWAIT_ARCHITECTURE.md` - Remove (outdated)
6. `/docs/09-history/task-history.md` - Historical, can keep as-is
7. `/docs/03-compiler-development/MACRO_PRINCIPLES.md` - Update examples
8. `/docs/03-compiler-development/MACRO_CASE_STUDIES.md` - Update examples

### Current Authoritative Documentation
- `/docs/04-api-reference/async-await-specification.md` - Complete specification with JavaScript/TypeScript comparison

### Migration Complete
- All tests updated to use genes.AsyncMacro
- Todo-app uses genes for client-side JavaScript
- AsyncAnonymousFunctions test removed (redundant with js_async_await)