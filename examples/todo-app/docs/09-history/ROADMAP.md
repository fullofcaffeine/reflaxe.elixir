# Todo App Development Roadmap

## Current: Standard Haxe JS Compilation

We're starting with Haxe's standard JavaScript target for solid foundation and compatibility.

**Current Benefits:**
- ✅ Stable and mature compilation target
- ✅ Good TypeScript/ES6 output with `-D js-es=6`
- ✅ Dead code elimination with `-D dce=full`
- ✅ Source map support for debugging
- ✅ Compatible with esbuild and Phoenix asset pipeline

## Future: Genes Compiler Integration

**Why Genes would be beneficial:**

### 1. **Modern JavaScript Output**
- **Cleaner ES6+ syntax**: More readable generated code
- **Better async/await support**: Native Promise handling vs Haxe's callback approach
- **Modern module system**: Better ES6 module integration

### 2. **Performance Benefits**
- **Smaller bundle sizes**: More efficient code generation
- **Better tree-shaking**: Improved dead code elimination
- **Optimized runtime**: Reduced overhead from Haxe runtime

### 3. **Developer Experience**
- **Better source maps**: More accurate debugging experience
- **Faster compilation**: Potential compilation speed improvements
- **Modern tooling integration**: Better compatibility with modern JS tools

### 4. **Phoenix/LiveView Integration**
- **Cleaner hook exports**: More native JavaScript hook patterns
- **Better esbuild compatibility**: Modern module loading
- **Reduced runtime dependencies**: Lighter Phoenix app bundles

### 5. **Type Safety Maintained**
- **Same Haxe type system**: Full type safety preserved
- **Shared types**: Client/server type sharing still works
- **Better error messages**: Potentially improved error reporting

## Implementation Plan for Genes

### Phase 1: Evaluation (Future)
- [ ] Set up Genes compiler in parallel build
- [ ] Compare bundle sizes (Haxe vs Genes output)
- [ ] Benchmark performance differences
- [ ] Test LiveView hook compatibility

### Phase 2: Migration (Future)
- [ ] Migrate client code to Genes compilation
- [ ] Update build scripts and esbuild configuration
- [ ] Verify all tests pass with Genes output
- [ ] Update documentation with new patterns

### Phase 3: Optimization (Future)
- [ ] Leverage Genes-specific optimizations
- [ ] Optimize bundle splitting and lazy loading
- [ ] Enhance development workflow

## Current Focus

For now, we're focusing on:
1. ✅ Establishing solid Haxe→JS compilation pipeline
2. ✅ Creating type-safe LiveView hooks
3. ✅ Demonstrating pure-Haxe architecture benefits
4. ⏳ Comprehensive testing infrastructure
5. ⏳ Beautiful UI with Tailwind integration

The Genes compiler upgrade will be pursued once we have a solid foundation demonstrating the pure-Haxe approach for Phoenix LiveView development.