# Product Requirements Documents (PRDs)

This directory contains Product Requirements Documents for Reflaxe.Elixir development.

## Current Active PRD

- **[ACTIVE_PRD.md](./ACTIVE_PRD.md)** - The current authoritative plan for Reflaxe.Elixir development

## Directory Structure

```
documentation/plans/
├── ACTIVE_PRD.md           # Current authoritative development plan
├── PRD_README.md           # This file - index and guidelines
└── archive/                # Historical/completed plans
    └── 2025-08-14_paradigm_todoapp_compiler_plan.md
```

## PRD Guidelines

PRDs in this directory should follow this structure:

1. **Executive Summary** - Vision, goals, and differentiators
2. **Current State Analysis** - What's working, critical gaps, technical debt
3. **Requirements** - Detailed functional and non-functional requirements
4. **Architecture Decisions** - Technology choices with rationale
5. **Success Metrics** - Measurable outcomes
6. **Implementation Roadmap** - Prioritized timeline

## Relationship to Documentation

- **PRDs** define **what** we need to build and **why**
- **CLAUDE.md** contains agent instructions and current project truth
- **documentation/** contains implementation guides and technical details

## Agent Instructions

For AI agents: All agent instructions are now in [CLAUDE.md](../../CLAUDE.md). Use ACTIVE_PRD.md for current priorities and requirements.