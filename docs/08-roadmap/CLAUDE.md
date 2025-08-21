# Plans Directory - Agent Instructions

## Purpose
This directory contains Product Requirements Documents (PRDs) for Reflaxe.Elixir development. When working in this directory, agents should understand PRD workflows and requirements planning.

## Current Active PRD
- **ACTIVE_PRD.md** - The authoritative development plan
- Contains: Vision, requirements, roadmap, success metrics
- **ALWAYS read this first** when starting work sessions

## Agent Workflow for PRDs

### 1. PRD Reading Priority
1. Read ACTIVE_PRD.md for current priorities
2. Check archive/ for historical context if needed
3. Cross-reference with main CLAUDE.md for global rules

### 2. PRD Updates
- **Never modify ACTIVE_PRD.md lightly** - it's the source of truth
- For small updates: edit directly with clear justification
- For major changes: create new version, archive old one
- Always update dates and version numbers

### 3. Implementation Workflow
From PRD to execution:
1. **Identify phase** - Which phase in ACTIVE_PRD roadmap?
2. **Check requirements** - What are the specific requirements?
3. **Note success metrics** - How will completion be measured?
4. **Follow architecture decisions** - Don't deviate without reason
5. **Update progress** - Keep PRD status current

## PRD Quality Standards

### Executive Summary
- Clear vision statement
- Specific, measurable goals
- Strategic differentiators vs competitors

### Requirements
- Use R1, R2, R3 numbering for traceability
- Include acceptance criteria
- Specify priority levels (CRITICAL, HIGH, MEDIUM, LOW)

### Roadmap
- Phase-based organization
- Clear dependencies between phases
- Realistic timelines with buffer
- Risk mitigation for each phase

## Critical Focus Areas

Based on ACTIVE_PRD.md, current priorities are:

1. **Idiomatic Code Generation** - Parameter names (arg0/arg1 problem)
2. **Standard Library Completion** - Cross-platform capability
3. **Testing Framework Integration** - ExUnit support
4. **Documentation Enhancement** - LLM-optimized docs

## Directory Rules

- **ACTIVE_PRD.md**: Current authoritative plan
- **archive/**: Historical/completed PRDs (read-only)
- **PRD_README.md**: Directory index and guidelines

## Success Criteria

A good PRD session results in:
- ✅ Clear understanding of current phase priorities
- ✅ Specific actionable tasks identified
- ✅ Requirements traceability maintained
- ✅ Progress tracking updated
- ✅ Success metrics defined

## Context Integration

This CLAUDE.md provides PRD-specific guidance. For general project context:
- **Main CLAUDE.md**: Overall project rules and architecture
- **documentation/**: Technical implementation guides
- **src/**: Actual compiler implementation

Remember: PRDs define **what** and **why**, implementation defines **how**.