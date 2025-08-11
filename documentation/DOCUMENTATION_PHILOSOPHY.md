# Documentation Philosophy for Reflaxe.Elixir

## Overview
This document explains the documentation architecture, the purpose of each document type, and guidelines for maintaining clear, focused documentation that serves both human developers and AI agents effectively.

## Documentation Categories

### 1. Agent Instruction Manual
**File**: `CLAUDE.md`
- **Purpose**: Central truth source for AI agents working on the project
- **Size Limit**: Must stay under 40k characters for optimal performance  
- **Content**: Essential instructions, critical rules, architecture references
- **What belongs**: Agent execution instructions, testing rules, commit standards, known issues
- **What doesn't belong**: Historical task completions, duplicated content from other docs

### 2. Feature Documentation
**Location**: `documentation/*.md`
- **Purpose**: Comprehensive guides for specific features and capabilities
- **Pattern**: Follow SOURCE_MAPPING.md structure - thorough, example-rich, user-focused
- **Examples**:
  - `SOURCE_MAPPING.md` - Complete source mapping implementation guide
  - `WATCHER_WORKFLOW.md` - File watching and incremental compilation
  - `MIX_TASKS.md` - Mix task reference documentation
  - `FEATURES.md` - Production readiness and capability status
  - `ANNOTATIONS.md` - Annotation usage and reference guide

### 3. Architecture Documentation
**Location**: `documentation/ARCHITECTURE.md`, `documentation/TESTING.md`
- **Purpose**: Explain system design, compilation flow, and architectural decisions
- **Content**: 
  - Macro-time vs runtime distinction
  - Compilation pipeline
  - Helper system architecture
  - Testing philosophy and infrastructure

### 4. User Documentation
**Location**: Project root and `documentation/`
- **Purpose**: Help users get started and use the project effectively
- **Key Files**:
  - `README.md` - Project overview and quick start
  - `INSTALLATION.md` - Detailed setup instructions
  - `GETTING_STARTED.md` - First steps with Reflaxe.Elixir
  - `EXAMPLES.md` - Working example walkthroughs
  - `QUICKSTART.md` - Rapid onboarding guide

### 5. Development Documentation
**Location**: `documentation/` and root
- **Purpose**: Guide contributors and developers working on the compiler
- **Key Files**:
  - `DEVELOPMENT.md` - Developer workflow and contribution guide
  - `DEVELOPMENT_TOOLS.md` - Toolchain and infrastructure details
  - `DEBUGGING.md` - Debugging strategies and tools
  - `TROUBLESHOOTING.md` - Common issues and solutions

### 6. Historical Documentation
**Location**: `documentation/TASK_HISTORY.md`
- **Purpose**: Preserve record of completed tasks and architectural decisions
- **Content**: Task completions moved from CLAUDE.md to reduce size
- **Value**: Reference for understanding implementation evolution

### 7. Memory Files
**Location**: `.llm-memory/`
- **Purpose**: Implementation learnings and patterns discovered during development
- **Content**: Specific lessons learned, patterns, and insights
- **Management**: Archive redundant files when content is consolidated into main docs

### 8. LLM-Specific Guides
**Location**: `documentation/LLM_*.md`
- **Purpose**: Guide AI agents in specific tasks
- **Examples**:
  - `LLM_DOCUMENTATION_GUIDE.md` - How to write and maintain documentation
  - `LLM_WORKFLOW_COMPATIBILITY.md` - AI agent workflow patterns
  - `LLM_DEBUGGING_STRATEGY.md` - Debugging approach for agents
  - `LLM_STACKTRACE_DEBUGGING_COMPLETE.md` - Complete debugging methodology

## Documentation Maintenance Rules

### 1. CLAUDE.md Maintenance
- **Size Check**: Run `wc -c CLAUDE.md` after major updates
- **Target**: Keep under 40,000 characters
- **Actions when over limit**:
  1. Move historical content to TASK_HISTORY.md
  2. Remove duplicated content (reference other docs instead)
  3. Consolidate redundant sections
  4. Archive completed task descriptions

### 2. Cross-Reference Strategy
- **Don't duplicate**: If content exists in another doc, reference it
- **Use links**: `See [documentation/FEATURE.md](documentation/FEATURE.md)`
- **Keep references current**: Update links when files move or rename

### 3. Documentation Updates with Code Changes
- **Rule**: Documentation is part of the implementation
- **When changing code**: Update relevant documentation immediately
- **New features**: Create or update feature documentation
- **Breaking changes**: Update all affected documentation

### 4. File Naming Conventions
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
- [ ] Is CLAUDE.md still under 40k characters?
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