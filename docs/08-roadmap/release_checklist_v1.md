# Reflaxe.Elixir v1.0 Release Checklist

## Gates
- [ ] Todo-app builds with Haxe and compiles/runs with mix (no errors)
- [ ] No leaked infrastructure variables in final code (InfraVarValidation)
- [ ] Unused parameters prefixed with `_` (no warnings for unused params)
- [ ] Reserved words escaped; no invalid identifiers
- [ ] Enum parameter extraction uses pattern binders; no `_g` assignments
- [ ] Loops emit idiomatic forms (Enum.each/map; with_index when index used)
- [ ] Target-conditional std bootstrap in effect; macros do not see `__elixir__()`

## Snapshot Coverage
- [ ] Enum parameter in switch (regression)
- [ ] With-index each + map (loop_desugaring)
- [ ] Phoenix presence/basic LiveView (existing)
- [ ] Typed assigns/events (to add if gaps found)

## Docs
- [ ] Hygiene & Validation (added)
- [ ] README “Haxe the Elixir Way” guidance (present)
- [ ] PRD and CHANGELOG updated

## Commands
```bash
# Build compiler tests
npm test

# Build and run todo-app
cd examples/todo-app
haxe build-server.hxml
mix deps.get && mix compile --force
mix phx.server
```

## Sign-off
- [ ] Code review of AST passes and LoopBuilder changes
- [ ] Phoenix/Ecto output reviewed for idioms
- [ ] Tag v1.0 and publish

