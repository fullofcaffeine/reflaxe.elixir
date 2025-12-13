# Documentation Philosophy for Reflaxe.Elixir

## Overview
This document explains the documentation architecture, the purpose of each document type, and guidelines for maintaining clear, focused documentation that serves both human developers and AI agents effectively.

## Documentation Categories

### 1. Agent Instruction Manual
**File**: `AGENTS.md`
- **Purpose**: Central truth source for AI agents working on the project
- **Size Limit**: Must stay under 40k characters for optimal performance  
- **Content**: Essential instructions, critical rules, architecture references
- **What belongs**: Agent execution instructions, testing rules, commit standards, known issues
- **What doesn't belong**: Historical task completions, duplicated content from other docs

### 2. Feature Documentation
**Location**: `docs/` organized in numbered sections
- **Purpose**: Comprehensive guides for specific features and capabilities
- **Organization**:
  - `01-getting-started/` - Setup, quickstart, project structure
  - `02-user-guide/` - Application developer docs (Phoenix/Ecto/LiveView)
  - `03-compiler-development/` - Compiler internals and contributor docs
  - `04-api-reference/` - API + annotation reference
  - `05-architecture/` - System design and architectural decisions
  - `06-guides/` - Task-focused how-to guides
  - `07-patterns/` - Patterns and best practices
  - `08-roadmap/` + `prds/` - Roadmaps and PRDs
  - `09-history/` - Historical records and learnings
  - `10-contributing/` - Contribution process and LLM integration docs

### 3. Architecture Documentation
**Location**: `docs/05-architecture/`
- **Purpose**: Explain system design, compilation flow, and architectural decisions
- **Key Files**:
  - `ARCHITECTURE.md` - Complete system architecture
  - `TESTING.md` - Testing philosophy and infrastructure
  - `TESTING_ARCHITECTURE_COMPLETE.md` - Comprehensive testing details

### 4. User Documentation
**Location**: `docs/01-getting-started/`, `docs/02-user-guide/`, and `docs/06-guides/`
- **Purpose**: Help users get started and use the project effectively
- **Key Files**:
  - `GETTING_STARTED.md` - First steps with Reflaxe.Elixir
  - `EXAMPLES.md` - Working example walkthroughs
  - `COOKBOOK.md` - Common patterns and recipes
  - `QUICKSTART.md` - Rapid onboarding guide
  - `TUTORIAL_FIRST_PROJECT.md` - Step-by-step tutorial

### 5. Product Requirements Documentation
**Location**: `docs/08-roadmap/` and `docs/prds/`
- **Purpose**: Strategic vision, requirements analysis, and product roadmap
- **Key Files**:
  - `PRD_VISION_ALIGNMENT.md` - Core vision and architecture requirements
  - `PRD_README.md` - Index of PRDs with guidelines
- **Content**: Executive summaries, requirement specifications, success metrics, implementation roadmaps
- **Audience**: Project stakeholders, senior developers, strategic planners

### 6. Reference Documentation
**Location**: `docs/04-api-reference/`
- **Purpose**: API references and feature specifications
- **Key Files**:
  - `ANNOTATIONS.md` - Annotation usage and reference
  - `FEATURES.md` - Production readiness and capability status
  - `MIX_TASKS.md` - Mix task reference documentation
  - `EXTERN_CREATION_GUIDE.md` - Creating extern definitions

### 6. Historical Documentation
**Location**: `docs/09-history/`
- **Purpose**: Preserve record of completed tasks and learnings
- **Key Files**:
  - `TASK_HISTORY.md` - Completed tasks and architectural decisions
  - `LEARNINGS.md` - Consolidated implementation learnings and patterns

### 7. LLM-Specific Guides
**Location**: `docs/10-contributing/llm-integration/`
- **Purpose**: Guide AI agents in specific tasks
- **Key Files**:
  - `LLM_DOCUMENTATION_GUIDE.md` - How to write and maintain documentation
  - `LLM_WORKFLOW_COMPATIBILITY.md` - AI agent workflow patterns
  - `LLM_DEBUGGING_STRATEGY.md` - Debugging approach for agents
  - `LLM_STACKTRACE_DEBUGGING_COMPLETE.md` - Complete debugging methodology

### 8. Special Directories
**Location**: `.claude/`
- **Purpose**: Claude-specific configuration and rules
- **Content**: Project-specific rules and commands for AI agents
- **Note**: Keep separate from main documentation

## Documentation Maintenance Rules

### 1. Documentation Accuracy Rules ⚠️
**Prevent documentation rot and ensure accuracy:**
- **ALWAYS remove deprecated/outdated documentation** - Don't let incorrect info accumulate
- **Verify claims against actual code** - Check implementation before documenting issues
- **Update Known Issues immediately** when issues are fixed - remove solved problems
- **Delete obsolete sections entirely** rather than marking them as outdated
- **Test claims in real code** - If documenting a limitation, verify it actually exists
- **Remove fixed TODOs and resolved items** - Keep only current actionable items
- **Documentation updates are part of implementation** - Update docs when changing code

### 2. AGENTS.md Maintenance
- **Size Check**: Run `wc -c AGENTS.md` after major updates
- **Target**: Keep under 40,000 characters
- **Actions when over limit**:
  1. Move historical content to TASK_HISTORY.md
  2. Remove duplicated content (reference other docs instead)
  3. Consolidate redundant sections
  4. Archive completed task descriptions

### 3. Cross-Reference Strategy
- **Don't duplicate**: If content exists in another doc, reference it
- **Use links**: `See [docs/FEATURE.md](../FEATURE.md)`
- **Keep references current**: Update links when files move or rename

### 4. Documentation Updates with Code Changes
- **Rule**: Documentation is part of the implementation
- **When changing code**: Update relevant documentation immediately
- **New features**: Create or update feature documentation
- **Breaking changes**: Update all affected documentation

### 5. File Naming Conventions
- **Feature docs**: `FEATURE_NAME.md` (e.g., `SOURCE_MAPPING.md`)
- **Guides**: `ACTION_GUIDE.md` (e.g., `GETTING_STARTED.md`)
- **LLM docs**: `LLM_PURPOSE.md` (e.g., `LLM_DOCUMENTATION_GUIDE.md`)
- **Architecture**: `COMPONENT.md` (e.g., `ARCHITECTURE.md`, `TESTING.md`)

## Documentation Quality Standards

### 1. Structure
Every major documentation file should include:
- **Purpose statement** at the top
- **Table of contents** for files >100 lines
- **Clear section headers** using markdown hierarchy
- **Code examples** with syntax highlighting
- **Cross-references** to related documentation

### 2. Writing Style
- **Be concise** but complete
- **Use examples** to illustrate concepts
- **Include "why"** not just "what"
- **Test instructions** - ensure they work
- **Keep current** - outdated docs are worse than no docs

### 3. Code Examples
```haxe
// Always provide context
@:liveview("/counter/:id")
class CounterLive {
    // Explain what the code does
    public function mount(params: Map<String, String>, session: Map<String, String>, socket: Socket): Socket {
        // Implementation
    }
}
```

### 4. Version Tracking
- Document which version features were added
- Note breaking changes clearly
- Keep compatibility notes when relevant

## Documentation Review Checklist

Before committing documentation changes:
- [ ] Is AGENTS.md still under 40k characters?
- [ ] Are all cross-references valid?
- [ ] Do code examples compile/work?
- [ ] Is the content in the right file?
- [ ] Are related docs updated?
- [ ] Is the language clear and concise?
- [ ] Are there unnecessary duplications?

## The Living Documentation Principle

Documentation in Reflaxe.Elixir is **living documentation**:
- It evolves with the code
- It's tested and validated
- It serves multiple audiences (users, developers, AI agents)
- It's part of the implementation, not an afterthought

By maintaining this documentation philosophy, we ensure that knowledge is preserved, discoverable, and actionable for all project stakeholders.
