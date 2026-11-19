package caf;

import caf.system.cml_authoring.CmlInlineMarkup.hxx;
import caf.system.concept.ConceptModelHxxAuthoring.*;
import caf.system.concept.ConceptModelMarkup;

/** Explains upstream dependency repairs; Mix locks remain the installed-source authority. */
@:build(caf.system.cml_authoring.CmlInlineMarkup.build())
class ExampleDependencyRepair {
	public static final markup:ConceptModelMarkup = <conceptModel id="caf:concept:model:reflaxe-elixir:example-dependency-repair" title="Keep the example servers on repaired dependencies">
    <owner label="Compiler example maintainers" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/ExampleDependencyRepair.hx" />
    <scope kind="caf.scope.project" id="caf:reflaxe-elixir:project:root" />
    <purpose>Keep example servers usable while rejecting dependency versions with known security defects.</purpose>
    <stableName>example-dependency-repair</stableName>
    <proposalState>proposal</proposalState>
    <summary>The required example audit found unsafe request handling in Bandit, unbounded rounding allocation in Decimal, and slow punycode decoding in idna, which Swoosh requires. Use their repaired upstream releases.</summary>
    <definitionBoundary>This proposal selects a dependency repair. Native Mix declarations and locks select installed versions and checksums.</definitionBoundary>
    <authorityBoundary>CML owns this intent. Native audits and tests own observed results. Beads task haxe.elixir.codex-bdc owns delivery status. Git owns accepted changes.</authorityBoundary>
    <evidenceRef id="caf:concept:evidence:example-dependency-repair:source" kind="source" ref="caf:concept:model:reflaxe-elixir:example-dependency-repair" role="proposal-source" authority="authored">This declaration records the requested selection, not a successful installation.</evidenceRef>
    <fallbackJustification id="caf:concept:fallback:example-dependency-repair" result="partial-gap-after-reuse" reviewedTargetRefs={["caf:agentspec:rule:dependency-integration-lifecycle"]} evidenceRefs={["caf:concept:evidence:example-dependency-repair:source"]}>Reuse native Mix installation and the existing dependency lifecycle. Concept markup supplies the missing explanation; no new installer is needed.</fallbackJustification>
    <anchor id="caf:concept:anchor:example-dependency-repair:servers" name="Example servers" role="boundary" boundary="These examples have native runtime dependencies separate from the compiler release tools." targetRefs={[]} evidenceRefs={[]}>Phoenix examples use Bandit for HTTP. Database examples also use Decimal through Ecto. Mailer examples use idna through Swoosh.</anchor>
    <statement id="caf:concept:statement:example-dependency-repair:selection" kind="intent" subjectAnchorRefs={["caf:concept:anchor:example-dependency-repair:servers"]} targetRefs={[]} evidenceRefs={["caf:concept:evidence:example-dependency-repair:source"]} claimBoundary="A selected version is not proof that the examples pass." detailMarkdown="[Bandit 1.14.1](https://hex.pm/packages/bandit/1.14.1) ([changelog](https://github.com/mtrudel/bandit/blob/main/CHANGELOG.md)), [Bandit 1.13.1](https://hex.pm/packages/bandit/1.13.1), [Decimal 3.1.2](https://hex.pm/packages/decimal/3.1.2), [Swoosh 1.30.0](https://hex.pm/packages/swoosh/1.30.0), [idna 8.0.0](https://hex.pm/packages/idna/8.0.0). [Request authority advisory](https://cna.erlef.org/cves/CVE-2026-105660.html), [HTTP/2 advisory](https://cna.erlef.org/cves/CVE-2026-105659.html), [Decimal advisory](https://cna.erlef.org/cves/CVE-2026-97853.html), [idna advisory](https://osv.dev/vulnerability/EEF-CVE-2026-117678). [Parser-error compatibility repair](https://github.com/mtrudel/bandit/pull/719).">Use Bandit 1.14.1 and a supported Decimal release at or above 3.1.2. Update only required dependency constraints and native locks. Keep minimum toolchain and Phoenix behavior intact. Bandit 1.13.0 turned malformed-body errors into HTTP 500 responses. Select 1.13.1 or later to preserve HTTP 400 for malformed JSON and HTTP 413 for oversized bodies. Bandit 1.14.1 fixes the HTTP/1, HTTP/2 and WebSocket advisories that the Hex audit reported for 1.13.1 in November 2026. Use Swoosh 1.30.0 or later and idna 8.0.0 or later: Swoosh releases before 1.30.0 require idna below 8.0.0, and idna releases below 8.0.0 have advisory EEF-CVE-2026-117678.</statement>
    <constraint id="caf:concept:constraint:example-dependency-repair:verification" kind="must" appliesToAnchorRefs={["caf:concept:anchor:example-dependency-repair:servers"]} evidenceRefs={[]} boundary="Audit and behavior checks remain independent.">Pass the existing Hex audit without a waiver. Compile the examples and test request handling and decimal rounding through native observers. Keep every required CI check. Exercise parser errors through a real HTTP listener; an in-process connection test cannot detect stale native connection state.</constraint>
    <loweringHint id="caf:concept:lowering:example-dependency-repair:native" kind="use-native-opaque-wrapper" requiredEvidenceRefs={["caf:concept:evidence:example-dependency-repair:source"]}>Use Mix to resolve and install exact upstream packages. Do not patch generated output or dependency source.</loweringHint>
    <nonGoal>No audit success, upstream merge, Caffeine adoption or graph import is asserted here.</nonGoal>
    <migrationOrDeletionPlan>Retain native lock and regression evidence. Revisit the selection when upstream changes or a test disproves compatibility; do not keep a custom workaround after the supported dependency satisfies the same contract.</migrationOrDeletionPlan>
    <sourceReference label="Example dependency repair" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/ExampleDependencyRepair.hx" />
    <provenance label="Required audit repair" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/ExampleDependencyRepair.hx" role="caf.provenance.authored-by" />
  </conceptModel>;
}
