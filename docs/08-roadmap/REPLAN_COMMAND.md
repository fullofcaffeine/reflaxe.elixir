# Replan Command - Preserve and Refine Task Management

## Purpose
The replan command implements a "map->reduce" pattern for task management: take existing tasks and refine them with new knowledge gained during execution, rather than discarding and recreating from scratch.

## Key Principles

### 1. Preserve Planning Work
- **Always save current plan as reference PRD** before replanning
- Plans represent significant planning effort and insights
- Historical plans provide context for future decisions
- Never lose accumulated knowledge from planning sessions

### 2. Map->Reduce Pattern
- **Map**: Take current tasks and their status
- **Reduce**: Apply new knowledge to refine/reorganize
- **Result**: Better organized, more efficient task list
- **NO clearAllTasks by default** - selective refinement instead

## Implementation Rules

### When to Replan
1. **Task execution reveals architectural issues** (score < 80)
2. **Discovery of existing infrastructure** that should be leveraged
3. **Multiple systems need coordination** (not originally planned)
4. **Approach creates more problems** than it solves
5. **Context becomes too large** - need to consolidate/simplify

### Replan Workflow

```markdown
1. **Save Current Plan as Reference PRD**
   - Use timestamp in filename: `shrimp-plan-YYYY-MM-DD-description.md`
   - Save to `docs/08-roadmap/` directory
   - Include:
     - Original goals and context
     - Task list with completion status
     - Lessons learned during execution
     - Reasons for replanning

2. **Analyze Current State**
   - Use `mcp__shrimp-task-manager-global__list_tasks` to get all tasks
   - Document what was completed vs pending
   - Identify what knowledge was gained

3. **Consult Codex for Architecture Review**
   - Describe discoveries and issues
   - Get architectural guidance on new approach
   - Validate revised strategy

4. **Use process_thought for Deep Analysis**
   - Think through implications of new insights
   - Consider alternative approaches
   - Plan the refined task structure

5. **Apply Selective Task Updates**
   - Use `updateMode: "selective"` NOT `clearAllTasks`
   - Keep completed tasks for historical record
   - Refine pending tasks based on new knowledge
   - Add new tasks discovered during execution

6. **Document Replan Rationale**
   - Why replanning was necessary
   - What changed from original plan
   - Expected improvements from new approach
```

## Example Replan Scenario

### Original Plan (saved as reference PRD)
```markdown
# Shrimp Plan: Fix Pattern Variable Extraction
Date: 2025-01-23

Tasks:
1. ✅ Fix pattern extraction in one location
2. ⏸️ Test with todo-app
3. ⏸️ Document fix
```

### Discovery During Execution
- Pattern uses "value" but body references "v"
- Multiple systems aren't coordinating
- EnumBindingPlan needed as single source of truth

### Refined Plan (after replan)
```markdown
# Shrimp Plan: Coordinated Pattern Variable System
Date: 2025-01-23 (Revised)
Reference: shrimp-plan-2025-01-23-pattern-extraction.md

Tasks:
1. ✅ Fix pattern extraction in one location (completed)
2. 🆕 Create EnumBindingPlan as coordination point
3. 🔄 Refactor TEnumParameter to use binding plan
4. 🔄 Update ClauseContext to respect binding plan
5. 🔄 Test coordinated system with todo-app
6. 🔄 Document architectural pattern
```

## Benefits of This Approach

1. **Context Preservation**: Never lose planning context or rationale
2. **Learning Integration**: Each replan incorporates lessons learned
3. **Efficient Execution**: Refined plans are more focused and achievable
4. **Historical Record**: Can trace evolution of approach through PRDs
5. **Reduced Cognitive Load**: Selective updates keep manageable task lists

## Anti-Patterns to Avoid

❌ **Using clearAllTasks mode** - Loses completed task history
❌ **Not saving reference PRDs** - Loses planning context
❌ **Replanning too frequently** - Thrashing without progress
❌ **Ignoring architectural issues** - Band-aid fixes instead of replanning
❌ **Not consulting Codex** - Missing architectural insights

## Integration with Shrimp Task Manager

The replan command should integrate with the shrimp task management system:

```typescript
// Pseudocode for replan implementation
async function replan(reason: string) {
  // 1. Save current plan as reference PRD
  const currentTasks = await listTasks('all');
  const prdContent = generatePRD(currentTasks, reason);
  const filename = `shrimp-plan-${date}-${slugify(reason)}.md`;
  await saveFile(`docs/08-roadmap/${filename}`, prdContent);
  
  // 2. Analyze and think
  await processThought({
    thought: `Replanning because: ${reason}`,
    stage: "Planning"
  });
  
  // 3. Selective update (NOT clearAllTasks)
  await splitTasks({
    updateMode: "selective", // Key: selective, not clearAllTasks
    tasksRaw: refinedTasks
  });
}
```

## Summary

The replan command embodies intelligent task management: preserve what works, refine what doesn't, and never lose accumulated knowledge. By treating plans as valuable artifacts (PRDs) and using selective refinement instead of wholesale replacement, we maintain continuity while adapting to new insights.

**Remember**: Every plan represents hours of thinking and analysis. Save it, learn from it, and build upon it.