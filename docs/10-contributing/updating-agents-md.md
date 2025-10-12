# Updating AGENTS.md Files - Unified Documentation Strategy

## 🤖 Philosophy: User Docs = AI Context

**Vision**: Our documentation serves both human developers AND AI assistants. Every piece of user documentation should be structured to also provide excellent AI context, and vice versa.

### Unified Documentation Benefits
- **Single source of truth** - No duplicate maintenance 
- **Consistent knowledge** - Humans and AI get same information
- **Better documentation** - AI context forces clarity and completeness
- **Efficient maintenance** - Update once, benefits everyone

## 📋 AGENTS.md Architecture Overview

### Current Structure (8 files)
```
./AGENTS.md                               # 13.6K - Project root context
./docs/AGENTS.md                          # 8.1K  - Documentation navigation
./docs/03-compiler-development/AGENTS.md  # 7.4K  - Compiler-specific context
./docs/08-roadmap/AGENTS.md               # 2.8K  - PRD and planning context
./examples/todo-app/AGENTS.md             # 22.9K - Example integration context
./src/reflaxe/elixir/AGENTS.md            # 7.9K  - Compiler source context
./std/AGENTS.md                           # 17.9K - Standard library context
./test/AGENTS.md                          # 5.5K  - Testing context
```

### Import System (Anthropic Best Practice)
```markdown
# Instead of duplicating content, use imports:
@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md
@docs/claude-includes/code-style.md
```

## 🎯 When to Update AGENTS.md vs Documentation

### Update AGENTS.md When:
- **AI behavior needs changing** - Different responses or priorities
- **New development patterns** - Workflow changes or best practices  
- **Context-specific rules** - Directory-specific instructions
- **Command shortcuts** - Frequently used commands for that context

### Update Regular Documentation When:
- **Feature documentation** - New compiler capabilities or APIs
- **User guides** - Step-by-step tutorials and examples
- **Architecture explanations** - Technical deep dives
- **Historical records** - Implementation history and decisions

### Update Both When:
- **Core principles** - Fundamental project rules (import into AGENTS.md)
- **Common workflows** - Patterns used by both humans and AI
- **Quality standards** - Code style and testing requirements

## 🔧 Maintenance Best Practices

### Character Limit Management (40K per file)
```bash
# Check all AGENTS.md file sizes
for file in $(find . -name "AGENTS.md" -type f); do 
    echo "$file: $(wc -c < "$file") chars"; 
done | sort
```

### Import Strategy
1. **Extract shared content** to `docs/claude-includes/`
2. **Use imports** instead of duplicating principles
3. **Keep context-specific** content in local AGENTS.md
4. **Monitor character counts** after changes

### Hierarchy and Precedence
```
Root AGENTS.md (project-wide rules)
├── @docs/claude-includes/core-principles.md
├── Context-specific overrides
└── Child AGENTS.md files inherit and extend
```

## 📝 Template for New AGENTS.md Files

```markdown
# [Context Name] - AI Instructions

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for project-wide rules

## Import Shared Components
@docs/claude-includes/compiler-principles.md
@docs/claude-includes/testing-commands.md

## Context-Specific Instructions
[Add rules specific to this directory/component]

## Key Files and Locations
[Directory-specific navigation]

## Common Commands for This Context
[Context-relevant commands]
```

## 🚀 Migration Strategy

### Phase 1: Extract Shared Content (Current)
- ✅ Create `docs/claude-includes/` with modular components
- ✅ Extract compiler principles, testing commands, code style
- ✅ Extract framework integration patterns

### Phase 2: Implement Imports  
- Update root AGENTS.md to use imports
- Refactor large files (todo-app, std) to use shared components
- Add common commands sections

### Phase 3: Unified Documentation Integration
- Ensure user guides serve as AI context through imports
- Structure new documentation to be AI-friendly
- Regular audits to maintain alignment

## 🎯 Success Metrics

### Reduced Duplication
- **Before**: Repeated principles across 8 files
- **After**: Shared content imported, context-specific additions only

### Improved Maintainability  
- **Single update** propagates to all relevant contexts
- **Consistent behavior** across all AI interactions
- **Easier onboarding** for new contributors

### Enhanced User Experience
- **Better documentation** through AI-forced clarity
- **Consistent guidance** whether reading docs or asking AI
- **Comprehensive coverage** of both human and AI needs

---

**Remember**: Every documentation update should ask: "Does this help both humans AND AI assistants work effectively with our project?"

