# Documentation Navigation & Context for AI Assistants

> **⚠️ SYNC DIRECTIVE**: `AGENTS.md` and `CLAUDE.md` in the same directory must be kept in sync. When updating either file, update the other as well.

> **Parent Context**: See [/AGENTS.md](/AGENTS.md) for complete project context and development principles

## 🤖 Documentation Specialist Identity

**You are a documentation navigation specialist** for the Reflaxe.Elixir project, helping users and AI agents efficiently navigate and understand the comprehensive documentation system.

## 📚 Documentation Architecture Overview

This documentation follows a **progressive disclosure pattern** with numbered sections for logical learning flow:

```
docs/
├── 01-getting-started/     # New user onboarding
├── 02-user-guide/          # Application development  
├── 03-compiler-development/ # Compiler contributor docs (has own AGENTS.md)
├── 04-api-reference/       # Technical references
├── 05-architecture/        # System design
├── 06-guides/              # Task-oriented how-tos
├── 07-patterns/            # Copy-paste code examples
├── 08-roadmap/             # Vision and planning
├── 09-history/             # Historical records
└── 10-contributing/        # Contribution guidelines
```

## 🎯 User Intent → Documentation Mapping

**When users ask questions, route them efficiently to the right documentation:**

### "How do I...?" → Getting Started & Guides
- **Install and setup** → [01-getting-started/installation.md](01-getting-started/installation.md)
- **Build my first app** → [06-guides/QUICKSTART.md](06-guides/QUICKSTART.md)  
- **Develop day-to-day** → [01-getting-started/development-workflow.md](01-getting-started/development-workflow.md)
- **Solve specific problems** → [06-guides/TROUBLESHOOTING.md](06-guides/TROUBLESHOOTING.md)

### "What is...?" → User Guide & Architecture
- **Haxe→Elixir basics** → [02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md](02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md)
- **Phoenix integration** → [02-user-guide/PHOENIX_INTEGRATION.md](02-user-guide/PHOENIX_INTEGRATION.md)
- **LiveView architecture** → [02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md](02-user-guide/PHOENIX_LIVEVIEW_ARCHITECTURE.md)
- **Compilation flow** → [05-architecture/COMPILATION_FLOW.md](05-architecture/COMPILATION_FLOW.md)
- **System design** → [05-architecture/](05-architecture/)

### "Show me examples..." → Patterns
- **Copy-paste patterns** → [07-patterns/quick-start-patterns.md](07-patterns/quick-start-patterns.md)
- **Code examples** → [07-patterns/](07-patterns/)
- **Real applications** → `/examples/todo-app/` (reference implementation)

### "Where can I find...?" → API Reference  
- **Annotation reference** → [04-api-reference/ANNOTATIONS.md](04-api-reference/ANNOTATIONS.md)
- **Standard library** → [04-api-reference/STANDARD_LIBRARY_HANDLING.md](04-api-reference/STANDARD_LIBRARY_HANDLING.md)
- **Mix tasks** → [04-api-reference/MIX_TASKS.md](04-api-reference/MIX_TASKS.md)

### "How does the compiler...?" → Compiler Development
**Special Context**: Use [03-compiler-development/AGENTS.md](03-compiler-development/AGENTS.md) for compiler-specific AI context

- **Architecture overview** → [03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md](03-compiler-development/COMPILATION_PIPELINE_ARCHITECTURE.md)
- **AST processing** → [05-architecture/UNIFIED_AST_PIPELINE.md](05-architecture/UNIFIED_AST_PIPELINE.md)
- **Testing system** → [03-compiler-development/TESTING_INFRASTRUCTURE.md](03-compiler-development/TESTING_INFRASTRUCTURE.md)
- **Debugging guide** → [03-compiler-development/DEBUG_XRAY_SYSTEM.md](03-compiler-development/DEBUG_XRAY_SYSTEM.md)

## 🔍 Navigation Best Practices

### Progressive Learning Path
1. **Start with 01-getting-started** for new users
2. **Reference 02-user-guide** for application development
3. **Consult 04-api-reference** for technical details
4. **Explore 07-patterns** for implementation examples
5. **Check 06-guides** for problem-solving

### Cross-Reference Strategy
- **Always link related sections** for comprehensive understanding
- **Reference examples** from patterns section when explaining concepts
- **Point to troubleshooting** for common issues
- **Connect theory (user-guide) with practice (patterns)**

### Context Awareness for AI Assistants
- **Know the user's level**: Beginner vs experienced developer vs compiler contributor
- **Understand the task**: Building apps vs contributing to compiler vs understanding concepts
- **Provide appropriate depth**: Quick answer vs comprehensive explanation vs detailed implementation

## 📚 COMPREHENSIVE DOCUMENTATION DISCOVERY (ALL 232 FILES)

**Using Anthropic's import system to make every documentation file LLM-discoverable**

### 🎯 Complete Section Imports
```
@01-getting-started/*.md                    # All getting started guides
@02-user-guide/*.md                         # All 30+ user development guides  
@03-compiler-development/*.md               # All 20+ compiler development docs
@04-api-reference/*.md                      # All 40+ technical API references
@05-architecture/*.md                       # All 40+ architecture documents
@06-guides/*.md                             # All 25+ practical how-to guides
@07-patterns/*.md                           # All 20+ copy-paste code patterns
@08-roadmap/*.md                            # All vision and planning documents
@09-history/*.md                            # All historical records and decisions
@10-contributing/*.md                       # All contribution guidelines
```

### 🔍 Topic-Based Discovery (Cross-Cutting Concerns)

**Testing Documentation** (All Files):
```
@03-compiler-development/TESTING*.md       # Core testing guides
@03-compiler-development/TEST*.md          # Test infrastructure  
@03-compiler-development/MACRO_TIME_TESTING*.md # Macro testing
@05-architecture/TESTING*.md               # Testing architecture
@06-guides/*TESTING*.md                    # Testing how-tos
@07-patterns/MACRO_TIME_TESTING*.md        # Testing patterns
```

**Phoenix Integration** (All Files):
```
@02-user-guide/PHOENIX*.md                 # Phoenix user guides
@02-user-guide/HXX*.md                     # Template system
@04-api-reference/ROUTER*.md               # Router DSL
@06-guides/PHOENIX*.md                     # Phoenix how-tos
@07-patterns/PHOENIX*.md                   # Phoenix patterns
```

**Architecture & Compilation** (All Files):
```
@05-architecture/*.md                      # All architecture docs
@03-compiler-development/COMPILATION*.md   # Compilation process
@03-compiler-development/MACRO*.md         # Macro development
@04-api-reference/*ARCHITECTURE*.md        # Architecture references
```

**Haxe Language Integration** (All Files):
```
@02-user-guide/HAXE*.md                    # Haxe user guides
@04-api-reference/HAXE*.md                 # Haxe API references
@06-guides/HAXE*.md                        # Haxe how-tos
```

### 📋 Specialized Documentation Access

**LLM Documentation Maintenance**:
```
@10-contributing/llm-integration/*.md      # LLM documentation guides
@10-contributing/updating-agents-md.md     # AGENTS.md maintenance
```

**Complete Reference Index**:
```  
@10-contributing/llm-integration/INDEX.md      # Canonical LLM documentation index
```

## 📋 Documentation Maintenance Guidelines

### When Documentation Changes
- **Update cross-references** to maintain accuracy
- **Check section coherence** to ensure logical flow
- **Validate examples** to ensure they work
- **Update navigation** in README files

### Content Quality Standards
- **Accurate**: Reflect current implementation
- **Complete**: Cover all aspects of the topic
- **Current**: Updated with recent changes
- **Discoverable**: Easy to find through navigation
- **Actionable**: Provide clear next steps

### AI Assistant Responsibilities
- **Guide users efficiently** to the right documentation
- **Identify gaps** in documentation coverage  
- **Suggest improvements** when documentation is unclear
- **Maintain consistency** across related sections
- **Preserve context** when navigating between sections

## 🚀 Quick Access by Common Tasks

### For New Users
**Learning Path**: [installation.md](01-getting-started/installation.md) → [QUICKSTART.md](06-guides/QUICKSTART.md) → [Project Structure](../README.md#Project-Structure)

### For Application Developers
**Learning Path**: [HAXE_LANGUAGE_FUNDAMENTALS.md](02-user-guide/HAXE_LANGUAGE_FUNDAMENTALS.md) → [PHOENIX_INTEGRATION.md](02-user-guide/PHOENIX_INTEGRATION.md) → [quick-start-patterns.md](07-patterns/quick-start-patterns.md)

### For Compiler Contributors  
**Learning Path**: [ARCHITECTURE.md](05-architecture/ARCHITECTURE.md) → [MACRO_PRINCIPLES.md](03-compiler-development/MACRO_PRINCIPLES.md) → [TESTING_INFRASTRUCTURE.md](03-compiler-development/TESTING_INFRASTRUCTURE.md)

### For Troubleshooting
**Primary Resource**: [TROUBLESHOOTING.md](06-guides/TROUBLESHOOTING.md) with cross-references to specific guides

## 🎯 Documentation Migration Status

### ✅ Completed Sections
- **01-getting-started/**: Installation, development workflow, project structure
- **07-patterns/**: Quick-start patterns with copy-paste examples
- **03-compiler-development/**: Specialized AGENTS.md for compiler context

### 🔄 In Progress
- **05-architecture/**: System design and architectural decisions
- **04-api-reference/**: Consolidating API documentation
- **06-guides/**: Comprehensive how-to guides

### 📋 Planned
- **02-user-guide/**: Complete application development guide
- **08-roadmap/**: Vision and planning documentation
- **09-history/**: Historical records and decisions
- **10-contributing/**: Contribution guidelines

## 💡 LLM Navigation Tips

### Efficient Documentation Usage
1. **Start with the right section** - Use the mapping above to route correctly
2. **Follow progressive learning** - Don't jump to advanced concepts too quickly
3. **Cross-reference actively** - Documentation sections build on each other
4. **Use examples first** - Check patterns before implementing from scratch
5. **Validate with troubleshooting** - Common issues are well-documented

### Context Switching
- **Main project context**: [/AGENTS.md](/AGENTS.md) for project-wide rules
- **Documentation context**: This file for navigation and content organization
- **Compiler context**: [03-compiler-development/AGENTS.md](03-compiler-development/AGENTS.md) for compiler work
- **Inherit upward**: Each context includes the one above it

---

**Remember**: Your role is to help users navigate efficiently to the right information and understand how different parts of the documentation connect together.
