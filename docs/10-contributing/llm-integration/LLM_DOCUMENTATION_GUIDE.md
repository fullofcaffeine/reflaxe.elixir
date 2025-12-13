# LLM Documentation Guide for Reflaxe.Elixir

## 🎯 Purpose
This guide teaches LLMs how to efficiently query, write, and maintain documentation for the Reflaxe.Elixir project. Follow these patterns to ensure consistency and discoverability.

**CRITICAL**: Always keep documentation updated when making system changes. Documentation is part of the implementation.

## Table of Contents
1. [Quick Reference](#quick-reference)
2. [Documentation Patterns](#documentation-patterns)
3. [Feature Documentation Template](#feature-documentation-template)
4. [AGENTS.md Integration](#claudemd-integration)
5. [Memory Files](#memory-files)
6. [Cross-referencing](#cross-referencing)
7. [Maintenance Responsibilities](#maintenance-responsibilities)

## Quick Reference

### Where to Find Documentation

```
Project Root/
├── AGENTS.md                          # LLM execution instructions & project truth  
├── README.md                          # User-facing project overview
├── docs/                              # All feature documentation (organized structure)
│   ├── 01-getting-started/           # Installation, quickstart, workflows
│   ├── 02-user-guide/               # Complete application development guides
│   ├── 03-compiler-development/     # Compiler contributor documentation  
│   ├── 04-api-reference/            # Technical references and APIs
│   ├── 05-architecture/             # System design documentation
│   ├── 06-guides/                   # Task-oriented how-to guides
│   ├── 07-patterns/                 # Copy-paste code patterns
│   ├── 08-roadmap/                  # Vision and planning documents
│   ├── 09-history/                  # Historical records and decisions
│   ├── 10-contributing/             # Contribution guidelines
│   ├── claude-includes/             # Shared AGENTS.md components for imports
│   ├── AGENTS.md                    # Documentation navigation for AI
│   └── README.md                    # Documentation index and entry point
```

### Import System for AGENTS.md Files
```
@docs/claude-includes/compiler-principles.md   # Shared compiler concepts
@docs/claude-includes/testing-commands.md      # Common test commands  
@docs/claude-includes/code-style.md           # Project-wide code style
@docs/claude-includes/framework-integration.md # Phoenix/LiveView patterns
```

### Documentation Priority Levels

1. **AGENTS.md** - Always check first, contains project truth
2. **Feature Docs** - docs/**/*.md for specific features
3. **Memory Files** - .llm-memory/*.md for implementation details
4. **README.md** - For user-facing feature status

## Documentation Patterns

### Standard Document Structure

Every major documentation file should follow this structure:

```markdown
# Feature Name

## 🎯 Overview
Brief description highlighting unique value proposition.
**Bold key achievements** or **industry-first features**.

## Table of Contents
1. [Section 1](#section-1)
2. [Section 2](#section-2)
3. [Section 3](#section-3)

## Section 1
### Subsection
Content with code examples

## Section 2
### Subsection
Technical details

## Troubleshooting
Common issues and solutions

## Summary
Key takeaways with emoji indicators
```

### Status Indicators

Use these consistently across all documentation:

- ✅ **Complete/Working** - Feature fully implemented and tested
- 🎯 **Pioneering/First** - Industry-first or unique feature
- ⚠️ **Warning/Critical** - Important information requiring attention
- ❌ **Not Working/Deprecated** - Broken or removed features
- 🚀 **Performance** - Performance metrics or optimizations
- 📋 **Task/Todo** - Pending work items
- 💡 **Tip/Best Practice** - Helpful suggestions

### Code Block Standards

Always specify language and include helpful comments:

```haxe
// Haxe code example
class Example {
    public static function main() {
        trace("Always include context");
    }
}
```

```bash
# Bash commands with descriptions
npm test  # Run all tests
mix compile.haxe --watch  # Start file watcher
```

```elixir
# Generated Elixir code example
defmodule Example do
  def main do
    IO.puts("Show what gets generated")
  end
end
```

## Feature Documentation Template

When documenting a new feature, create FOUR interconnected pieces:

### 1. User Guide (`docs/02-user-guide/FEATURE_NAME.md`)

```markdown
# Feature Name Guide

## 🎯 Overview
[What it does from user perspective]
[Why it's valuable - highlight if industry-first]

## Table of Contents
[Standard TOC]

## Quick Start
[Minimal working example]

## Setup & Configuration
[How to enable and configure]

## Usage Examples
### Basic Usage
[Code example]

### Advanced Usage
[Code example]

## Workflow Integration
[How it fits into development workflow]

## API Reference
[If applicable - Mix tasks, functions, etc.]

## Performance Characteristics
[Metrics, benchmarks if relevant]

## Troubleshooting
### Common Issue 1
**Symptoms**: [Description]
**Solution**: [Steps to fix]

## Summary
[Key benefits and capabilities]
```

### 2. Technical Implementation (in AGENTS.md)

Add to "Recent Task Completions" section:

```markdown
### Feature Name Implementation Complete ✅
Successfully implemented [feature] with [key characteristics]:

**Implementation Results**:
- **Key Component 1**: [What it does]
- **Key Component 2**: [Technical details]
- **Performance**: [Metrics]
- **Test Coverage**: [X/Y tests passing]

**Technical Architecture**:
- **Design Pattern**: [Pattern used]
- **Integration Points**: [How it connects]
- **Key Files**: [Important files created/modified]

**Documentation Created**:
- [`docs/02-user-guide/FEATURE_NAME.md`](/docs/02-user-guide/FEATURE_NAME.md) - User guide
- [Other docs updated]

[Brief summary of significance]
```

### 3. Architecture Details (linked from main docs)

If complex architecture, create separate doc or add section:

```markdown
## Architecture

### Components
#### Component 1
- Purpose
- Implementation
- Integration points

### Data Flow
```
[Diagram or description]
```

### Technical Decisions
- Why this approach
- Alternatives considered
- Trade-offs
```

### 4. Memory File (`.llm-memory/feature-name.md`)

```markdown
# Feature Name Implementation Memory

## Implementation Status: ✅ COMPLETED

[Brief summary of what was implemented]

## Key Learnings
- **Pattern 1**: [What worked well]
- **Challenge 1**: [What was difficult and how solved]
- **Insight 1**: [Important realization]

## Technical Details
[Implementation specifics that future LLMs need to know]

## Files Modified
- `src/reflaxe/elixir/FeatureCompiler.hx`: [What was added]
- `test/FeatureTest.hx`: [Test coverage]

## Integration Points
[How it connects with other features]

## Future Considerations
[What could be improved or extended]

## Common Pitfalls
[What to avoid when modifying this feature]
```

## AGENTS.md Integration

### When to Update AGENTS.md

**ALWAYS update AGENTS.md when**:
- Completing a major feature
- Discovering critical architectural insights
- Learning important patterns or anti-patterns
- Changing core compilation behavior

### What Goes in AGENTS.md

1. **User Documentation References** - Links to all major guides
2. **Recent Task Completions** - Implementation summaries
3. **Critical Rules** - Testing rules, patterns to follow
4. **Architecture Knowledge** - How the compiler works
5. **Known Issues** - Current limitations

### Update Pattern

```markdown
## Recent Task Completions

### [Previous completion stays here]

### Your New Feature Complete ✅ [emoji if pioneering]
[Follow template from section above]
```

## Memory Files

### Purpose of .llm-memory/

Memory files store:
- Implementation details too specific for main docs
- Lessons learned during development
- Debugging strategies that worked
- Performance optimization notes
- Failed approaches (to avoid repeating)

### When to Create Memory Files

Create a memory file when:
- Implementing complex features
- Solving difficult bugs
- Discovering non-obvious patterns
- Completing major refactoring

### Memory File Naming

```
.llm-memory/
├── feature-name-implementation.md    # Feature implementation notes
├── bug-fix-strategy.md              # How a bug was solved
├── performance-optimization.md       # Optimization techniques
└── testing-lessons.md               # Testing insights
```

## Cross-referencing

### Critical Rule: Review and Link When Adding New Documentation

**When adding any new documentation file, you MUST**:

1. **Review the entire documentation structure** to understand where your doc fits
2. **Search for related documentation** that should cross-reference your new doc
3. **Update all relevant existing docs** with links to your new documentation
4. **Add your doc to appropriate index files** (README.md, ARCHITECTURE.md, etc.)
5. **Check for duplicate content** that could be consolidated

### Documentation Review Checklist

When adding `NEW_FEATURE.md`, review and update:

- [ ] **README.md** - Add to documentation section if major feature
- [ ] **ARCHITECTURE.md** - Add to relevant architecture section
- [ ] **Related feature docs** - Add "See Also" cross-references
- [ ] **Parent category index** - e.g., guides/README.md
- [ ] **AGENTS.md** - Add reference if critical for development
- [ ] **Paradigm/pattern docs** - If introducing new patterns
- [ ] **FEATURES.md** - Update feature status
- [ ] **EXAMPLES.md** - Add usage examples

### Example: Adding BEAM_TYPE_ABSTRACTIONS.md

When this doc was added, these files needed updates:
```markdown
# In FUNCTIONAL_PATTERNS.md:
## See Also
- [BEAM Type Abstractions](BEAM_TYPE_ABSTRACTIONS.md) - Option and Result types

# In PARADIGM_BRIDGE.md:
## Related Documentation
- [BEAM Type Abstractions](BEAM_TYPE_ABSTRACTIONS.md) - Type-safe null handling

# In STANDARD_LIBRARY_HANDLING.md:
## Option Type Compilation
See [BEAM Type Abstractions](BEAM_TYPE_ABSTRACTIONS.md) for Option patterns

# In README.md:
### Core Documentation
- [BEAM Type Abstractions](/docs/05-architecture/BEAM_TYPE_ABSTRACTIONS.md) - Option/Result types
```

### Internal Links

Always use relative paths:
```markdown
See [`/docs/04-api-reference/SOURCE_MAPPING.md`](/docs/04-api-reference/SOURCE_MAPPING.md)
```

### Section Links

For same-file sections:
```markdown
See [Architecture](#architecture) section below
```

For other-file sections:
```markdown
See [Architecture](/docs/05-architecture/ARCHITECTURE.md) in the feature guide
```

### Code References

When referencing code:
```markdown
Implementation in `src/reflaxe/elixir/SourceMapWriter.hx:45`
Test coverage in `test/tests/source_map_basic/`
```

## Maintenance Responsibilities

### LLM Documentation Duties

**When you modify the system, you MUST**:

1. **Update affected documentation immediately**
   - Don't wait for a "documentation pass"
   - Documentation is part of the implementation

2. **Check these files for needed updates**:
   - AGENTS.md - Update task completions, known issues
   - README.md - Update feature list, test count, status
   - Feature guides - Update usage, examples, troubleshooting
   - docs/01-getting-started/installation.md - Update if setup changes
   - Memory files - Add lessons learned

3. **Update test counts**:
   ```markdown
   # When tests change, update:
   - README.md badge: [![Tests](https://img.shields.io/badge/tests-XX%2FXX%20passing-brightgreen)]
   - README.md test section: **XX/XX tests passing**
   - TESTING.md: Test suite overview
   ```

4. **Version documentation changes**:
   ```markdown
   ## Recent Updates
   - 2025-08-11: Added source mapping support
   - 2025-08-10: Enhanced error handling
   ```

5. **Maintain cross-references**:
   - If you rename/move files, grep for references
   - Update all links to point to new locations
   - Ensure no broken links remain

### Documentation Quality Checklist

Before completing any task, verify:

- [ ] AGENTS.md updated with task completion
- [ ] User-facing docs explain the feature
- [ ] Examples compile and work
- [ ] Troubleshooting covers common issues
- [ ] Memory file created for complex implementations
- [ ] Cross-references are valid
- [ ] Test counts are accurate
- [ ] Status indicators (✅ ❌ ⚠️) are current

### Discovering Existing Documentation

Before writing new docs, search for existing content:

```bash
# Find all references to a feature
rg -n "source map" docs/

# Find specific documentation files
find documentation -name "*SOURCE*"

# Check memory files
ls -la .llm-memory/

# Search AGENTS.md for completions
grep "Complete ✅" AGENTS.md
```

## Best Practices

### DO ✅

- **Keep docs next to code** - Update both together
- **Use consistent formatting** - Follow patterns in this guide
- **Include real examples** - Working code > abstract descriptions
- **Highlight unique features** - Especially industry-firsts
- **Explain the "why"** - Not just "what" and "how"
- **Test your examples** - Ensure code blocks actually work
- **Link extensively** - Connect related documentation

### DON'T ❌

- **Leave outdated information** - Remove or update old content
- **Create orphan docs** - Always link from somewhere
- **Skip troubleshooting** - Document known issues
- **Forget performance** - Include metrics where relevant
- **Use absolute paths** - Always relative for portability
- **Document without testing** - Verify your documentation works

## Documentation Templates

### Mix Task Documentation

```markdown
### mix task.name

Description of what the task does.

\```bash
# Basic usage
mix task.name

# With options
mix task.name --option value
\```

**Options:**
- `--option` - What it does
- `--flag` - What it enables

**Examples:**
\```bash
mix task.name input.file --verbose
\```

**Output:**
\```json
{
  "result": "example"
}
\```
```

### Configuration Documentation

```markdown
## Configuration

### Required Settings
\```elixir
config :app_name,
  required_key: value
\```

### Optional Settings
\```elixir
config :app_name,
  optional_key: default_value  # Description
\```

### Environment Variables
\```bash
EXPORT_VAR=value mix command
\```
```

## Summary

This guide ensures LLMs can:
- ✅ **Find documentation quickly** using the quick reference
- ✅ **Write consistent documentation** following templates
- ✅ **Maintain documentation** as the system evolves
- ✅ **Create comprehensive feature docs** with 4-layer approach
- ✅ **Cross-reference effectively** with proper linking
- ✅ **Keep AGENTS.md current** as the source of truth

**Remember**: Documentation is not separate from implementation - it IS part of the implementation. Always update docs when changing code, and always check existing docs before implementing new features.

When in doubt, look at these exemplary documentation files:
- [`/docs/04-api-reference/SOURCE_MAPPING.md`](/docs/04-api-reference/SOURCE_MAPPING.md) - Comprehensive feature guide
- [`/docs/06-guides/WATCHER_WORKFLOW.md`](/docs/06-guides/WATCHER_WORKFLOW.md) - Workflow documentation
- [`/docs/04-api-reference/MIX_TASKS.md`](/docs/04-api-reference/MIX_TASKS.md) - Reference documentation

**Final Rule**: If another LLM would struggle to understand or maintain your feature, your documentation is incomplete.
