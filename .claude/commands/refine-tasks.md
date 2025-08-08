# Refine Tasks Command

## Purpose
Analyze existing tasks and improve granularity through strategic splitting, focusing on better implementability and risk reduction while preserving existing work.

## Usage
`/refine-tasks [--focus=area] [--max-days=N] [--dry-run]`

## Description
This command analyzes the current task list to identify tasks that need further splitting for better granularity and implementability. It emphasizes **adding resolution through splitting** rather than deletion, only suggesting deletion when absolutely justified.

## Analysis Framework

### 1. Task Complexity Assessment
Evaluate each task on multiple dimensions:
- **Scope Breadth**: Does it cover multiple functional areas?
- **Technical Diversity**: Does it require different technical skills?
- **Implementation Time**: Would it take more than 2-3 days to complete?
- **Risk Level**: Does it contain high-risk components that should be isolated?
- **Testability**: Can it be tested as a single unit effectively?

### 2. Split Identification Criteria
A task should be split if it exhibits ANY of these characteristics:

#### **Multi-System Tasks**
- Covers multiple architectural layers (frontend + backend + database)
- Involves different technology stacks or frameworks
- Spans multiple services or components

#### **Multi-Pattern Tasks** 
- Combines different implementation patterns (GenServer + Oban Worker + Module)
- Mixes synchronous and asynchronous operations
- Includes both infrastructure and business logic

#### **Sequential Workflow Tasks**
- Contains clearly sequential steps that could be separate tasks
- Has phases that build upon each other
- Includes setup + implementation + optimization phases

#### **High-Risk Aggregations**
- Combines critical and non-critical components
- Mixes proven patterns with experimental approaches
- Includes both core functionality and edge cases

### 3. Split Strategy Guidelines

#### **Functional Decomposition**
```
Large Task: "User Authentication System"
Split Into:
- "User Registration and Validation"
- "Login and Session Management" 
- "Password Reset and Security"
- "Authentication Middleware Integration"
```

#### **Technical Layer Separation**
```
Large Task: "Full-Stack Feature Implementation"
Split Into:
- "Backend API and Data Layer"
- "Frontend Components and State Management"
- "Integration and E2E Testing"
```

#### **Risk-Based Isolation**
```
Large Task: "Payment Processing with Analytics"
Split Into:
- "Core Payment Processing (Critical)"
- "Payment Analytics and Reporting (Non-Critical)"
- "Payment Security and Compliance"
```

#### **Workflow Phase Separation**
```
Large Task: "Search System Implementation" 
Split Into:
- "Search Infrastructure Setup"
- "Search Algorithm Implementation"
- "Search Performance Optimization"
```

## Implementation Process

### Step 1: Analysis Phase
1. **Load Current Tasks**: Get all pending and in-progress tasks
2. **Complexity Scoring**: Rate each task on complexity dimensions (1-10 scale)
3. **Split Opportunity Detection**: Identify specific split points and rationale
4. **Dependency Impact Analysis**: Assess how splits affect the dependency graph

### Step 2: Split Planning Phase  
1. **Split Proposal Generation**: Create specific split proposals with clear rationale
2. **Dependency Restructuring**: Plan how new tasks will connect to existing ones
3. **Resource Estimation**: Estimate effort for each new granular task
4. **Risk Assessment**: Identify risks reduced through splitting

### Step 3: Implementation Phase
1. **Create New Granular Tasks**: Use split_tasks with "append" mode to add refined tasks
2. **Update Dependencies**: Ensure proper dependency chains between new tasks
3. **Preserve Context**: Maintain all important context from original tasks
4. **Validate Structure**: Ensure the new structure is implementable and logical

## Split Quality Criteria

### ✅ Good Splits
- **Single Responsibility**: Each new task has one clear purpose
- **Clear Interfaces**: Well-defined inputs/outputs between split tasks
- **Independent Testing**: Each split can be tested independently
- **Parallel Potential**: Splits enable parallel development where possible
- **Risk Isolation**: High-risk components separated from stable ones

### ❌ Poor Splits  
- **Over-Granulation**: Tasks so small they create coordination overhead
- **Artificial Boundaries**: Splits that don't reflect natural implementation boundaries
- **Dependency Explosion**: Creating too many interdependencies
- **Context Loss**: Losing important context through excessive splitting

## Deletion Guidelines

### When Deletion is Justified
**RARE CASES ONLY** - Deletion should be the last resort:

1. **True Duplication**: Task is genuinely identical to another existing task
2. **Obsolete Requirements**: Task addresses requirements that are no longer valid
3. **Impossible Dependencies**: Task has circular or unresolvable dependencies
4. **Scope Creep**: Task was added outside the project scope and timeline

### Deletion Process
If deletion is considered:
1. **Document Justification**: Clear explanation of why deletion is necessary
2. **Impact Analysis**: Assess what functionality/value is lost
3. **Alternative Solutions**: Explore task merging or scope reduction instead
4. **Stakeholder Review**: Ensure deletion doesn't remove critical functionality

## Command Parameters

### `--focus=area`
Limit analysis to specific areas:
- `--focus=memory` - Only analyze memory-related tasks
- `--focus=testing` - Only analyze testing tasks  
- `--focus=integration` - Only analyze integration tasks
- `--focus=week1,week2` - Analyze specific implementation phases

### `--max-days=N`
Set maximum task size threshold:
- `--max-days=2` - Split tasks estimated > 2 days
- `--max-days=1` - Aggressive splitting for very granular tasks
- `--max-days=5` - Conservative splitting for larger tasks

### `--dry-run`
Preview splits without making changes:
- Shows proposed splits and rationale
- Displays impact on dependencies
- Allows review before implementation

## Output Format

### Analysis Summary
```
📊 Task Refinement Analysis
==========================

Current Tasks: 23
Tasks Needing Splits: 5
Proposed New Tasks: 12
Final Task Count: 30

Risk Reduction: High → Medium (3 high-risk tasks isolated)
Parallel Opportunities: +40% (6 additional parallel paths)
Average Task Size: 4.2 days → 2.1 days
```

### Split Proposals
```
🔄 Task Split Proposal: "Three-Tier Memory System Implementation"
================================================================

Current Complexity: 8/10 (HIGH)
Estimated Effort: 5-7 days
Risk Level: High

Proposed Splits:
├── "Episodic Memory Implementation" (2-3 days, Medium risk)
│   └── Focus: Event recording, temporal queries, decay algorithms
├── "Working Memory GenServer" (1-2 days, Low risk)  
│   └── Focus: Context tracking, session management
└── "Memory Consolidation Worker" (2 days, Medium risk)
    └── Focus: Pattern extraction, daily jobs

Benefits:
✅ Enables parallel development of memory tiers
✅ Isolates complex decay algorithm from simpler components  
✅ Separates GenServer patterns from Oban worker patterns
✅ Reduces individual task risk while preserving functionality

Dependencies Updated:
- "Task Intelligence System" now depends on all 3 split tasks
- "Smart Save System" dependencies automatically restructured
```

### Implementation Commands
```
🚀 Implementation Commands
=========================

# Add new granular tasks
shrimp split-tasks --mode=append [task definitions...]

# Update dependencies for existing tasks  
shrimp update-task [task-id] --dependencies="new,dependency,list"

# Validate new structure
shrimp validate-dependencies
```

## Best Practices

### 1. Split Progressively
- Start with the most complex tasks first
- Split 3-5 tasks per iteration to avoid overwhelming changes
- Validate each split batch before proceeding

### 2. Maintain Context
- Preserve all important technical details in split tasks
- Ensure implementation guides remain comprehensive
- Keep verification criteria specific and measurable

### 3. Optimize Dependencies
- Minimize dependency chains while maintaining logical order
- Create opportunities for parallel work where possible
- Avoid creating circular dependencies through splits

### 4. Preserve Strategic Vision
- Ensure splits maintain the overall project architecture
- Don't lose sight of integration points through over-splitting
- Keep end-to-end workflows traceable through split tasks

## Example Usage

```bash
# Analyze all tasks and propose splits
/refine-tasks

# Focus on memory system tasks only
/refine-tasks --focus=memory

# Conservative splitting (only >3 day tasks)  
/refine-tasks --max-days=3

# Preview splits without implementing
/refine-tasks --dry-run --focus=testing

# Aggressive granularity for specific area
/refine-tasks --focus=taskmaster --max-days=1
```

## Success Metrics

### Quantitative Measures
- **Average Task Size**: Target 1-2 days per task
- **Risk Distribution**: <20% high-risk tasks
- **Parallel Opportunities**: >50% tasks can run in parallel
- **Dependency Depth**: <5 levels of dependencies

### Qualitative Measures  
- **Implementability**: Each task has clear, actionable implementation steps
- **Testability**: Each task can be validated independently
- **Context Preservation**: No loss of critical technical context
- **Strategic Alignment**: Splits support overall project architecture

---

*This command emphasizes surgical precision in task refinement - adding resolution where needed while preserving the valuable work already done in task planning.*