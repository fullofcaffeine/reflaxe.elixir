# RailsHx-to-PhoenixHx Migration Compiler RFC

Status: R&D proposal, not an implementation commitment.

This document captures the current architecture direction for a future general
RailsHx-to-PhoenixHx migration compiler and coexistence planner. It is separate
from the Reflaxe.Elixir compiler, separate from any PhoenixHx authoring profile,
and separate from the RailsHx todo example inventory.

The todo port remains a learning fixture and behavioral oracle. The future
migration compiler must be app-generic, evidence-driven, Haxe-first on the
target side, and conservative about semantics it cannot prove.

Related references:

- RailsHx / Reflaxe.Ruby: <https://github.com/fullofcaffeine/reflaxe.ruby>
- Todo fixture: `examples/17-railshx-to-phoenixhx-todo/`
- Tracking task: `haxe.elixir.codex-9gs`

## Goals

- Preserve product behavior while realizing the target with normal
  Phoenix/Ecto/OTP concepts.
- Let deterministic tooling extract, normalize, classify, generate, and verify
  only what it can prove.
- Put architectural judgment into explicit, versioned decision records instead
  of hidden heuristics.
- Support partial migration with exact ownership boundaries. Whole-app migration
  is "select all migration units," not a separate converter path.
- Generate Haxe-authored PhoenixHx code, then compile through Haxe.Elixir. Do not
  bypass Haxe by generating Elixir directly.
- Keep coexistence topology explicit enough that a selected route, component,
  job, data boundary, or service can move independently.

## Non-Goals

- No Rails compatibility mode inside Reflaxe.Elixir.
- No implicit Rails-to-Phoenix backend switch.
- No Rails annotations, Rails namespaces, Devise emulation, Turbo emulation, or
  Rails-cookie interpretation inside Haxe.Elixir.
- No todo-specific selectors, route names, fixtures, or heuristics in migration
  tooling.
- No machine-readable migration IR grown inside
  `examples/17-railshx-to-phoenixhx-todo/`.
- No CML dependency in the first migration MVP.
- No direct agent edits to application files. Agents produce validated decisions
  or repair proposals; deterministic tools apply approved plans.

## Architecture Sketch

```text
RailsHx typed source ----+
Rails runtime facts -----+--> Evidence IR --> deterministic rules --> Decision Requests
Database facts ----------+                                      |
                                                               v
                                                    approved Migration Plan
                                                               |
                          +------------------------------------+----------------+
                          v                                                     v
              PhoenixHx Haxe generator                         coexistence/topology plan
                          |                                                     |
                 Haxe.Elixir compiler                              optional CML projection
                          |
                    compile/tests
                          |
                 Verification Receipts
```

The important split is that extraction can be deterministic even when mapping is
not. A tool can establish that a RailsHx model declares a uniqueness validation;
it cannot automatically assert that a particular Ecto changeset plus database
constraint preserves the same semantics in every case.

## Invariants

- Facts are immutable and carry provenance.
- Architectural judgments are explicit, versioned decisions.
- Only approved migration plans produce application code.
- Generated target application code is Haxe-first and Phoenix-native.
- Every runtime boundary has exactly one declared active owner.
- Unsupported, ambiguous, or conflicting constructs stop generation.
- Re-running the same input versions produces byte-identical canonical evidence,
  plans, generated Haxe, and receipts.
- Tool-owned files are the only files the generator may overwrite, and ownership
  must be proven by a manifest.

## Deterministic Tooling Responsibilities

Deterministic code should own:

| Area | Responsibility |
| --- | --- |
| Source inventory | Files, declarations, symbols, source positions, generated ownership, checksums |
| Typed extraction | Haxe AST, metadata, route declarations, model fields, associations, params, template locals, hooks, migrations, tests |
| Runtime evidence | Realized Rails routes, database schema/catalog, application boot checks, route expansion |
| Normalization | Stable IDs, type normalization, dependency graph, declared-versus-observed reconciliation |
| Classification | `deterministic`, `review_required`, `decision_required`, or `opaque` statuses |
| Safe generation | Tool-owned PhoenixHx Haxe files based only on an approved plan |
| Verification | Haxe type-checking, Elixir compilation, formatting, tests, route/schema/contract comparison |
| Mechanical repair | Imports, generated names, formatting, and other fixes that do not change approved semantics |
| Auditability | Rule versions, decision references, input hashes, artifact lineage, verification receipts |

RailsHx extraction should consume structured source surfaces before generated
Ruby or regex scraping. Existing RailsHx fact surfaces are likely starting
points:

- `RailsRouteDecl.hx`, `RailsRouteManifest.hx`, `RailsRoutesExtractor.hx`
- model metadata from `ModelMacro.hx` and `RubyCompiler.hx`
- `ParamsMacro.hx`, `ViewMacro.hx`, `ControllerDsl.hx`, `RoutesDsl.hx`
- `MigrationOperation.hx`
- route parity and schema/runtime probes

Generated Ruby and string scraping should be fallback evidence only for
explicitly unsupported or externally owned portions.

## Agent And Human Responsibilities

Agents and humans should own choices that require product, security, operations,
or architecture judgment:

- authentication and session strategy
- authorization policy
- controller versus LiveView versus function-component boundaries
- UI state ownership
- Turbo Stream versus LiveView/PubSub behavior
- data ownership and migration sequencing
- shared-database policy
- background-job retry and idempotency semantics
- rollout, fallback, and rollback policy
- semantic repairs after compile or test failures

Agents should not directly edit application files. Their output should be
schema-validated records:

```text
EvidenceSet
  -> CandidateMappings
  -> DecisionRequest
  -> DecisionRecord
  -> MigrationPlan
  -> GeneratedPatch
  -> VerificationReceipt
```

A decision record should reference:

- evidence IDs and migration unit IDs
- available options and the chosen option
- rejected options and rationale
- assumptions
- required verification
- risk level
- human approval when required

Compiler or test failures may trigger agent proposals. A repair that changes a
route boundary, public contract, authentication strategy, data owner, or UI
behavior must create a new decision. Agents must not weaken tests or reinterpret
source behavior silently.

## IR Layers

Do not build one enormous "universal web framework AST." Rails and Phoenix have
different semantics; a universal AST would either become Rails-shaped or erase
important behavior. Use four related typed Haxe IR layers with canonical JSON and
generated JSON Schema for interchange.

### Evidence IR

Evidence IR stores immutable facts about source and observed runtime state.
Rails concepts may remain Rails concepts here.

It should include:

- artifact and symbol IDs
- source framework, language, and runtime
- source spans and checksums
- extractor and compiler versions
- Haxe type identity, generic arguments, and nullability
- fact kind: declared, runtime-observed, inferred, or opaque
- conflicts between declared and observed facts
- source-specific typed extensions, such as Rails callbacks or route options

### Semantic / Capability IR

This is a smaller framework-neutral behavior graph. It should model observable
capability rather than source framework names.

Core nodes:

- `DataEntity`, `Field`, `Relation`, `Constraint`
- `Operation`, `Endpoint`, `InputContract`, `OutputContract`
- `Policy`, `SideEffect`, `Job`, `ExternalIntegration`
- `UIStateSurface`, `Interaction`, `Event`, `Subscription`
- `BehaviorScenario`, `OpaqueBehavior`

Important edges:

- reads, writes, invokes, validates, authorizes
- renders, redirects, publishes, subscribes, enqueues
- owns, depends-on

Operations should record inputs, outputs, status codes, redirects, transaction
boundaries, reads/writes, external calls, event/job behavior, idempotency, error
behavior, and authentication/authorization requirements.

### Decision / Migration Plan IR

This is the bridge from evidence to generated code.

It should include:

- selected migration units
- approved target realization
- target module names
- controller/LiveView/component choices
- data-access policy
- authentication/session strategy
- required adapters
- mapping disposition
- evidence and decision references
- generated artifact ownership
- required tests and verification gates
- explicit unresolved blockers

The same plan model must support moving one route or the entire application.

### Runtime / Coexistence IR

This describes a mixed Rails/Phoenix system while migration is partial or
permanently hybrid.

It should include:

- runtime/service owner
- ingress and proxy rules
- HTTP, RPC, and event contracts
- identity propagation
- session and CSRF policy
- data authority and write ownership
- timeout, retry, and idempotency policy
- observability and correlation
- rollout state
- fallback and rollback
- compatibility window

Cafetra/CML can later be a projection or authored representation of approved
coexistence topology. It should not parse RailsHx, classify declarations, act as
the agent protocol, or become a required dependency of the first MVP.

## Migration Units

Every move should be modeled as a `MigrationUnit` in a dependency graph.
Suggested unit kinds:

- endpoint
- route group
- interactive page
- resource or bounded context
- component/island
- background job
- event/topic
- external integration
- data boundary
- entire runtime/service

Every selected unit needs an explicit boundary contract:

- stable selector based on IR IDs
- current owner and target owner
- method/path/host or event selector
- request, response, or event contract
- contract version
- authentication/session policy
- data read/write authority
- timeout and retry policy
- idempotency policy
- observability
- rollout state
- fallback behavior
- rollback action
- verification gates

Route or API endpoint ownership is the safest initial granularity. An edge
router or proxy sends one exact host/method/path combination to Phoenix while
Rails retains all other routes. Route precedence is generated and testable.
Rollback changes the traffic rule back to Rails without deleting generated code.

Do not put an application-level "maybe dispatch to Rails" switch inside
PhoenixHx.

## Safe Mapping Policy

Classification should happen per declaration or behavioral construct, not per
file.

Mechanically safe facts:

- modules, symbols, names, and source locations
- Haxe types and nullability
- database columns and primitive types
- primary keys, indexes, foreign keys, and database constraints
- HTTP method, path, and path parameters
- controller/action association
- strong-parameter allowlists
- typed template locals
- declared associations
- route nesting
- hook names, event names, and typed payloads
- test names and behavior scenarios
- migration operations
- declared callbacks and side effects

Safe target generation needs strict preconditions. Examples:

| Source fact | Possible PhoenixHx output | Preconditions |
| --- | --- | --- |
| Primitive scalar database field | Ecto schema field | Exact supported type/null/default mapping |
| Primary key, simple index, foreign key | Ecto migration declaration | Target owns migration and no conflicting DDL exists |
| Simple HTTP method/path | Phoenix controller route stub | Target boundary already selected |
| Path parameter | Typed route parameter contract | Same parsing and rejection behavior |
| Strong-parameter scalar allowlist | Changeset cast allowlist | Does not imply requiredness or validation |
| Pure Haxe enum/value structure | Target Haxe type | No Ruby runtime behavior attached |
| Typed template locals | Component input/assign contract | Does not generate the template itself |
| Simple route request test | Phoenix contract-test skeleton | Assertions remain behavior-oriented |

Review-required mappings include belongs-to/has-many shapes, common validations,
timestamp conventions, resource-route expansion, simple JSON serialization,
query filters, non-interactive server-rendered views, and straightforward
stateless JSON controller actions.

Even basic validations can differ. For example, Ecto uniqueness usually relies
on a real database unique constraint, while Rails uniqueness validation behavior
depends on lookup timing and application semantics. A Rails declaration must not
be converted by name alone.

## High-Risk Surfaces

Always require explicit decisions for identity and security:

- Devise/Warden behavior
- password hashing and credential migration
- confirmation, reset, and lockout flows
- Rails session-cookie compatibility
- Phoenix session/token strategy
- cross-runtime logout
- CSRF boundaries
- authorization scopes
- impersonation and administrative access

Do not automatically map UI architecture:

- Rails controller action to LiveView callback
- view partial to function component
- Turbo Frame to LiveComponent
- Turbo Stream to LiveView stream
- Action Cable broadcast to Phoenix PubSub

Turbo Streams transmit HTML fragments that target page regions. LiveView owns a
server process, receives events, and renders diffs over a connected lifecycle.
Similar user-visible outcomes do not make their state, failure, and reconnection
semantics equivalent.

Require decisions for persistence/lifecycle features:

- callbacks and transaction hooks
- default scopes and custom scopes
- raw SQL
- optimistic or pessimistic locking
- nested attributes
- dependent deletion behavior
- polymorphic associations
- single-table inheritance
- counter caches
- soft deletion
- database-generated values
- read replicas
- multi-tenancy

Other high-risk surfaces include jobs, mail, storage, engines, gem-contributed
routes, route constraints, optional/glob segments, form helpers, DOM identity
relied on by hooks, external API calls, realtime ordering, shared writes,
dual-write synchronization, and historical data migrations.

## Partial Migration And Coexistence

Partial migration is the default model. Whole-app migration is simply every
unit selected, with generation blocked until all required decisions are resolved.

Preferred boundary patterns:

- Route/API endpoint: exact proxy ownership for one host/method/path selector.
- Resource/context: move operations, persistence, authorization, events, and
  route set together where possible.
- Controller: treat as a source grouping, not necessarily a target boundary.
  Individual actions may become controllers, LiveViews, services, or blockers.
- Interactive route: move the whole stateful page to Phoenix when possible.
- Component/island: use explicit isolation modes only, such as Phoenix-hosted
  full route, iframe, custom element/client island, or stateless fragment
  endpoint where lifecycle permits.
- Background job: define producer, consumer, queue/transport, typed envelope,
  retry owner, idempotency key, dead-letter handling, and side-effect owner.

Prefer one writer. Transitional shared database access may allow read-only use
from both runtimes, but authoritative writes should remain singular. Field-level
or row-level split ownership is an advanced exception.

A useful rollout lifecycle is:

```text
disabled -> shadow-read -> canary -> primary -> retired
```

Mirroring should generally be limited to reads or side-effect-free evaluation.
Mirrored writes require a separate high-risk decision and reconciliation plan.

## First MVP

The first MVP should prove the architecture and coexistence mechanics, not broad
conversion.

Scope:

- one RailsHx-authored simple model
- one `GET /resource/:id` JSON endpoint
- one request/contract test
- primitive scalar fields
- Phoenix controller target, not LiveView
- Ecto schema and context
- generated PhoenixHx Haxe source
- compilation through Haxe.Elixir
- explicit route ownership rule
- verification receipts

Explicit exclusions:

- authentication
- writes
- callbacks
- Turbo
- HTML templates
- browser hooks
- background jobs
- mail
- storage
- polymorphism
- custom SQL
- dual writes
- historical migration conversion

Acceptance criteria for the MVP:

- identical source/config/tool versions produce byte-identical canonical IR,
  plan, generated Haxe, and receipts
- every fact includes provenance, extractor version, and source location or
  runtime observation
- declared RailsHx routes/schema facts reconcile against Rails runtime/database
  facts
- conflicts block generation
- no rule refers to Todo, User, ChatMessage, fixture route names, or app
  selectors
- the same pipeline succeeds on a second non-todo fixture
- only deterministic constructs generate automatically
- review-required output is staged but not applied without approval
- decision-required constructs produce no application code until a decision
  record exists
- generated Elixir passes formatting, compilation, and tests
- target code uses normal Phoenix controller/context/Ecto conventions
- method, path, path params, status behavior, and JSON shape have contract tests
- rollback is reverting the traffic rule
- re-running after successful generation produces no diff

Good next experiments after that MVP:

1. One write endpoint with one-writer cutover.
2. One full interactive route with explicit controller-versus-LiveView decision.
3. One session/authentication boundary.
4. One background job.
5. One CML topology projection.

## Cafetra / CML Relationship

CML fits best after source analysis and planning, not as the migration IR.

Good CML responsibilities:

- Rails and Phoenix services/runtimes
- entry points
- proxy and ingress ownership
- HTTP/RPC/event contracts
- environment and deployment dependencies
- shared identity strategy
- database connections
- data authority
- rollout/canary rules
- observability
- rollback topology

CML should not:

- parse RailsHx
- hold source AST facts
- classify individual Rails declarations
- decide controller versus LiveView
- act as the agent protocol
- pretend observed runtime state is authored architecture

Direction:

```text
Approved Migration Plan -> Coexistence IR -> optional CML projection
```

Possible future generic CML vocabulary after concrete experiments:

- boundary
- traffic policy
- identity bridge
- data authority
- contract version
- coexistence phase
- rollout gate
- rollback condition

## Repo Inspection Priorities

Priority 1: RailsHx fact surfaces in `reflaxe.ruby`.

- route declarations, manifests, extractors, and emitters
- Rails compiler/model metadata macros
- params, controller, view, and routes DSL macros
- migration operation model

Design question: what stable exporter can expose these facts before they become
Ruby? Do not reuse Rails route declarations as neutral endpoint records; adapt
them while retaining the original typed Rails extension.

Priority 2: RailsHx runtime parity and ownership.

- route parity scripts
- generated-artifact ownership manifests
- schema adoption and runtime probes

Useful precedents: discover before generating, reconcile authored and realized
routes, fail closed on ambiguity, and prove file ownership before overwriting.

Priority 3: PhoenixHx target seams in this repository.

- `src/reflaxe/elixir/macros/RouterDsl.hx`
- route extraction/lowering in `src/reflaxe/elixir/ElixirCompiler.hx`
- LiveView event/template registries
- `std/ecto/**`
- `std/phoenix/**`
- `lib/mix/tasks/haxe.gen.*`
- structured diagnostic tasks such as `haxe.errors` and `haxe.status`

Treat `SchemaRegistrar.hx` and `SchemaIntrospection.hx` as cautionary or
transitional areas, not foundations for authoritative migration evidence.

Priority 4: both todo applications.

Use the RailsHx and PhoenixHx todo apps to produce manual decision records:

- why a route became LiveView
- why PubSub was used
- where controllers remained appropriate
- how session state was bridged
- which behavior intentionally changed

Those decisions become fixture expectations, not global mapping rules.

Priority 5: Cafetra/CML.

First deliverable should be a mapping document from Coexistence IR to current
CML concepts, not new CML code.

Priority 6: Genes/browser compilation.

Review browser-hook migration only after the server-side route MVP. Model hook
identity, lifecycle, DOM contracts, events, typed payloads, browser
capabilities, and build target independently of a particular Genes version.

## Haxe.Elixir Boundary

Reasonable generic additions to Haxe.Elixir are only those independently useful
for ordinary PhoenixHx tooling:

- stable target capability/version manifest
- exportable router facts
- exportable Ecto schema facts
- LiveView event/hook/component manifests
- structured machine-readable diagnostics
- generated-artifact ownership metadata

Do not add Rails-specific migration logic to Haxe.Elixir. If a future adapter
layer is explored, it must be opt-in, named, documented, and configurable at the
most practical granularity: per module, feature, route, schema, or runtime
boundary.
