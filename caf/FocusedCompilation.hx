package caf;

import caf.system.cml_authoring.CmlInlineMarkup.hxx;
import caf.system.concept.ConceptModelHxxAuthoring.*;
import caf.system.concept.ConceptModelMarkup;

/** Proposal for focused builds; compiler options own the native selection. */
@:build(caf.system.cml_authoring.CmlInlineMarkup.build())
class FocusedCompilation {
	public static final markup:ConceptModelMarkup = <conceptModel id="caf:concept:model:reflaxe-elixir:focused-compilation" title="Compile a small probe without the whole application">
    <owner label="Compiler maintainers" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/FocusedCompilation.hx" />
    <scope kind="caf.scope.project" id="caf:reflaxe-elixir:project:root" />
    <purpose>Let a small test compile its own dependencies without discovering unrelated application modules.</purpose>
    <stableName>focused-compilation</stableName>
    <proposalState>proposal</proposalState>
    <summary>Ordinary Phoenix builds discover annotated modules. A focused probe can instead select its entry points explicitly.</summary>
    <definitionBoundary>This proposal describes a compiler option, not a new build runner or persistent cache.</definitionBoundary>
    <authorityBoundary>CML owns this proposal. Native compiler options select compilation behavior. Tests own observations; Beads task haxe.elixir.codex-c0o.8 owns delivery status.</authorityBoundary>
    <evidenceRef id="caf:concept:evidence:focused-compilation:source" kind="source" ref="caf:concept:model:reflaxe-elixir:focused-compilation" role="proposal-source" authority="authored">This declaration does not prove output or speed.</evidenceRef>
    <fallbackJustification id="caf:concept:fallback:focused-compilation" result="partial-gap-after-reuse" reviewedTargetRefs={["caf:agentspec:rule:dependency-integration-lifecycle"]} evidenceRefs={["caf:concept:evidence:focused-compilation:source"]}>Reuse Haxe entry points, imports and compiler defines. Current automatic annotation discovery defeats a focused entry point when unrelated application files share its classpath.</fallbackJustification>
    <anchor id="caf:concept:anchor:focused-compilation:scope" name="Compilation scope" role="boundary" boundary="Selection controls discovery, not dependency typing or authorization." targetRefs={[]} evidenceRefs={[]}>A credential probe should include its credential code without automatically selecting an unrelated HTTP controller.</anchor>
    <statement id="caf:concept:statement:focused-compilation:selection" kind="intent" subjectAnchorRefs={["caf:concept:anchor:focused-compilation:scope"]} targetRefs={[]} evidenceRefs={[]} claimBoundary="Explicit selection can omit runtime-only modules that the caller forgot to name.">Keep automatic discovery by default. With elixir_discovery=explicit, compile named entry points and their dependencies. Keep annotations on included modules effective. Reject other mode values.</statement>
    <constraint id="caf:concept:constraint:focused-compilation:proof" kind="must" appliesToAnchorRefs={["caf:concept:anchor:focused-compilation:scope"]} evidenceRefs={[]} boundary="A smaller output is not sufficient proof of correct behavior.">Prove default discovery, omitted unrelated modules, explicitly included annotated modules, invalid settings and mode changes on a persistent compiler. Keep native consumer assertions and full application checks. Measure performance separately under comparable conditions.</constraint>
    <loweringHint id="caf:concept:lowering:focused-compilation:native" kind="use-native-opaque-wrapper" requiredEvidenceRefs={["caf:concept:evidence:focused-compilation:source"]}>Use the existing Haxe compiler configuration and discovery owner. Do not copy consumer sources or patch installed libraries.</loweringHint>
    <nonGoal>No faster-build, accepted release, consumer adoption or Caffeine graph import is claimed.</nonGoal>
    <migrationOrDeletionPlan>Existing builds keep default discovery. Consumers opt in only after an accepted compiler release and complete runtime verification.</migrationOrDeletionPlan>
    <sourceReference label="Focused compilation" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/FocusedCompilation.hx" />
    <provenance label="Focused compiler probe proposal" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/FocusedCompilation.hx" role="caf.provenance.authored-by" />
  </conceptModel>;
}
