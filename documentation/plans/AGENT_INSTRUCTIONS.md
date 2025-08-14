# 📋 Agent Instructions: Task Management & PRD Reference

## Overview
This document provides instructions for AI agents on how to effectively use the Shrimp task management system alongside PRD (Product Requirements Document) files for comprehensive project understanding.

## 🔄 Workflow: Shrimp Tasks + PRD Integration

### 1. Starting a Work Session
```bash
# First, check current Shrimp tasks
mcp__shrimp-task-manager-global__list_tasks --status all

# Then, check for relevant PRDs
ls documentation/plans/staging/
ls documentation/plans/approved/
```

### 2. Task Execution Flow

#### Step 1: Get Task Details from Shrimp
```bash
# Get specific task details
mcp__shrimp-task-manager-global__get_task_detail --taskId <task-id>

# Execute task to get implementation guidance
mcp__shrimp-task-manager-global__execute_task --taskId <task-id>
```

#### Step 2: Reference PRD for Context
**IMPORTANT**: While Shrimp provides task-level details, always check the current PRD for:
- Overall project vision and goals
- Architectural decisions and constraints
- Success metrics and quality standards
- Phase dependencies and timeline
- Risk mitigation strategies

```bash
# Read relevant PRD
Read documentation/plans/staging/[current-prd].md
# or
Read documentation/plans/approved/[approved-prd].md
```

#### Step 3: Cross-Reference Documentation
```bash
# Check related documentation mentioned in PRD
Read documentation/guides/[relevant-guide].md
Read documentation/paradigms/[paradigm-doc].md
```

### 3. Task Updates and Progress

#### Update Shrimp Task
```bash
# Update task with progress
mcp__shrimp-task-manager-global__update_task --taskId <id> --prompt "Progress update..."

# Verify task completion
mcp__shrimp-task-manager-global__verify_task --taskId <id> --score 85 --summary "Implementation complete"
```

#### Update PRD Status (if needed)
- Move PRDs from `staging/` to `approved/` when finalized
- Archive completed PRDs to `archive/` with completion notes

## 📁 Directory Structure Reference

```
documentation/plans/
├── AGENT_INSTRUCTIONS.md    # This file - how to use tasks + PRDs
├── staging/                  # Work-in-progress plans
│   └── 2025-08-14_paradigm_todoapp_compiler_plan.md
├── approved/                 # Finalized, approved plans
└── archive/                  # Completed or obsolete plans
```

## 🎯 Key Principles

### 1. Shrimp is for Task Management
- **What**: Specific, actionable tasks
- **Granularity**: Implementation-level details
- **Tracking**: Progress, dependencies, verification
- **Memory**: Persistent across sessions

### 2. PRDs are for Strategic Context
- **What**: Overall project vision and requirements
- **Scope**: Phase planning and architecture
- **Reference**: Success metrics and constraints
- **Guidance**: Design decisions and patterns

### 3. Documentation is for Technical Details
- **What**: Implementation guides and patterns
- **Reference**: Code examples and best practices
- **Learning**: Paradigm bridges and transformations
- **Support**: Troubleshooting and FAQ

## 🔍 Example Workflow

### Scenario: Implementing Functional Helpers

1. **Check Shrimp Task**:
   ```
   Task: "Implement functional helper abstractions"
   Details: Create Option/Result types with map/flatMap operations
   ```

2. **Reference PRD**:
   ```
   Phase 2.1: Functional Helper Abstractions
   - Priority order: Option → Result → Pipeline
   - Testing requirements: 10+ snapshot tests
   - Performance targets: <15ms compilation
   ```

3. **Check Documentation**:
   ```
   FUNCTIONAL_HELPERS_IMPLEMENTATION.md
   - Detailed type signatures
   - Test strategy matrix
   - Integration points
   ```

4. **Implementation**:
   - Follow task specifics from Shrimp
   - Adhere to PRD constraints
   - Use documentation patterns

5. **Verification**:
   - Run tests as specified in PRD
   - Update Shrimp task status
   - Document in TASK_HISTORY.md

## 🚀 Best Practices

### DO:
- ✅ Always check both Shrimp tasks AND relevant PRDs
- ✅ Cross-reference documentation for patterns
- ✅ Update task status in real-time
- ✅ Keep PRDs as source of truth for requirements
- ✅ Use Shrimp for granular task tracking

### DON'T:
- ❌ Work solely from Shrimp without PRD context
- ❌ Ignore success metrics in PRDs
- ❌ Skip documentation references
- ❌ Modify approved PRDs (create new versions instead)
- ❌ Forget to verify tasks upon completion

## 📊 Task Priority Matrix

When multiple tasks exist, prioritize based on:

1. **Dependencies**: Tasks blocking others (check Shrimp dependencies)
2. **PRD Phase**: Current phase tasks take precedence
3. **Impact**: High-impact features from PRD success metrics
4. **Complexity**: Balance quick wins with complex tasks
5. **Feedback Loop**: Todo-app issues reveal compiler priorities

## 🔄 Continuous Improvement

### After Each Task:
1. Update Shrimp task with learnings
2. Note any PRD adjustments needed
3. Update relevant documentation
4. Add to TASK_HISTORY.md
5. Create new tasks for discovered issues

### Weekly Review:
1. Review all completed tasks in Shrimp
2. Check PRD progress against timeline
3. Move completed PRDs to archive
4. Create new PRDs for upcoming work
5. Adjust priorities based on feedback

## 💡 Tips for Agents

1. **Start with context**: Read PRD introduction before diving into tasks
2. **Understand dependencies**: Check task dependencies in Shrimp
3. **Verify assumptions**: PRDs contain architectural decisions - follow them
4. **Document discoveries**: Update PRDs with learnings for future agents
5. **Think holistically**: Tasks are parts of larger phases - understand the whole

## 🎯 Current Active PRD
**File**: `documentation/plans/staging/2025-08-14_paradigm_todoapp_compiler_plan.md`
**Focus**: Paradigm bridge, compiler enhancements, todo-app as living test
**Phase**: Phase 1 - Documentation & Paradigm Bridge
**Priority Tasks**: Functional helpers, compiler hints, todo-app fixes

---

**Remember**: Shrimp provides the "what" and "how" at task level, PRDs provide the "why" and "when" at project level, and documentation provides the "patterns" and "best practices" at technical level. Use all three for comprehensive understanding!