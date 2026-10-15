package caf;

import caf.system.cml_authoring.CmlInlineMarkup.hxx;
import caf.system.concept.ConceptModelHxxAuthoring.*;
import caf.system.concept.ConceptModelMarkup;

/** Explains a proposed dependency exception; native locks still select installed code. */
@:build(caf.system.cml_authoring.CmlInlineMarkup.build())
class ReleaseDependencyRepair {
	public static final markup:ConceptModelMarkup = <conceptModel id="caf:concept:model:reflaxe-elixir:braces-repair" title="Why compiler release tools need a maintained braces repair">
			<owner label="Compiler dependency maintainers" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/ReleaseDependencyRepair.hx" />
			<scope kind="caf.scope.project" id="caf:reflaxe-elixir:project:root" />
			<purpose>
				Let compiler fixes reach Caffeine while keeping the dependency security check intact.
			</purpose>
			<stableName>
				compiler-release-braces-repair
			</stableName>
			<proposalState>
				proposal
			</proposalState>
			<summary>
				Our compiler release tools use braces to process text patterns. A deeply nested pattern can crash that work. We need a reviewed repair because upstream has not released one.
			</summary>
			<definitionBoundary>
				This document explains one temporary dependency choice. It connects the problem, proposed repair and affected work. Installation remains with npm.
			</definitionBoundary>
			<authorityBoundary>
				CML owns this intent. Package locks own installed source selections. GitHub owns review and merge state. Beads owns task status. Native tests and audits own their observed results. Authoring this proposal proves none of those outcomes.
			</authorityBoundary>
			<evidenceRef id="caf:concept:evidence:braces-repair:task" kind="beads-task" ref="caf:task:beads:haxe-elixir-codex-7xd" role="repair-owner" authority="native">
				Use haxe.elixir.codex-7xd for current ownership, approval, blockers and exact verification evidence.
			</evidenceRef>
			<evidenceRef id="caf:concept:evidence:braces-repair:upstream" kind="source" ref="caf:source:braces:pr-87" role="candidate-patch" authority="native">
				Review upstream PR 87 at d44b9b1ee12e7804d4232d5a47a4a0c61d2fbefe. This is a candidate source, not an accepted fork pin or release.
			</evidenceRef>
			<fallbackJustification id="caf:concept:fallback:braces-repair" result="partial-gap-after-reuse" reviewedTargetRefs={["caf:agentspec:rule:dependency-integration-lifecycle"]} evidenceRefs={["caf:concept:evidence:braces-repair:task"]}>
				The existing dependency lifecycle covers review, exact pins, consumer checks and cleanup. Native package locks cover installation. This proposal adds the missing explanation and relationships for a temporary fork without creating another dependency manager.
			</fallbackJustification>
			<subjectRef>
				caf:reflaxe-elixir:project:root
			</subjectRef>
			<anchor id="caf:concept:anchor:braces-repair:release-tools" name="Compiler release tools" role="boundary" boundary="Build and release dependencies are not Caffeine runtime services." targetRefs={["caf:source:reflaxe-elixir:package-lock"]} evidenceRefs={[]}>
				semantic-release and its commit analyzer depend on micromatch, which depends on braces.
			</anchor>
			<anchor id="caf:concept:anchor:braces-repair:fork" name="Maintained braces repair" role="boundary" boundary="Preparation is approved; adoption still requires review and passing checks." targetRefs={["caf:source:braces:pr-87"]} evidenceRefs={["caf:concept:evidence:braces-repair:upstream"]}>
				Start from the exact candidate patch. Select the eventual maintained artifact by immutable revision and integrity evidence.
			</anchor>
			<statement id="caf:concept:statement:braces-repair:why" kind="intent" subjectAnchorRefs={["caf:concept:anchor:braces-repair:release-tools", "caf:concept:anchor:braces-repair:fork"]} targetRefs={["caf:task:beads:haxe-elixir-codex-bt9", "caf:task:beads:haxe-elixir-codex-dc6", "caf:task:beads:caffeine-g8z-41", "caf:task:beads:caffeine-g8z-23"]} evidenceRefs={["caf:concept:evidence:braces-repair:task"]} claimBoundary="These links explain what the repair enables. Beads records whether that work is complete.">
				The security check blocks two compiler fixes. One lets Caffeine reject invalid requests before routing. The other lets its backend read graph references correctly. Repair the shared dependency once, then test both Caffeine paths.
			</statement>
			<constraint id="caf:concept:constraint:braces-repair:proof" kind="must" appliesToAnchorRefs={["caf:concept:anchor:braces-repair:fork"]} evidenceRefs={["caf:concept:evidence:braces-repair:upstream"]} boundary="An audit that cannot identify a fork is not evidence that the fork is safe.">
				Independently test hostile nesting, caller-supplied syntax trees, cycles and normal pattern behavior. Run upstream tests and release-tool compatibility checks. Review the exact artifact and audit treatment before adoption. Do not suppress an advisory, invent a patched version, or treat a passing install as security proof.
			</constraint>
			<constraint id="caf:concept:constraint:braces-repair:exit" kind="must" appliesToAnchorRefs={["caf:concept:anchor:braces-repair:fork"]} evidenceRefs={["caf:concept:evidence:braces-repair:task"]} boundary="A future upstream release is a candidate until independently verified.">
				Compiler dependency maintainers own updates to the retained fork. Return to a supported upstream release when it contains the required repair and passes the same checks. Remove the override only after exact consumer adoption; preserve rollback source and evidence.
			</constraint>
			<statement id="caf:concept:statement:braces-repair:sources" kind="intent" subjectAnchorRefs={["caf:concept:anchor:braces-repair:fork"]} targetRefs={["caf:source:braces:pr-87"]} evidenceRefs={["caf:concept:evidence:braces-repair:upstream"]} claimBoundary="Links identify external evidence; they do not import or accept it." detailMarkdown="[Advisory](https://github.com/advisories/GHSA-vfj7-8cjw-p6xm). [Patch review](https://github.com/micromatch/braces/pull/87). [Exact candidate](https://github.com/micromatch/braces/commit/d44b9b1ee12e7804d4232d5a47a4a0c61d2fbefe). [Endpoint fix](https://github.com/fullofcaffeine/reflaxe.elixir/pull/61). [Enum fix](https://github.com/fullofcaffeine/reflaxe.elixir/pull/60).">
				Read the advisory, review the candidate patch, and inspect the compiler changes that depend on this repair.
			</statement>
			<loweringHint id="caf:concept:lowering:braces-repair:native-install" kind="use-native-opaque-wrapper" requiredEvidenceRefs={["caf:concept:evidence:braces-repair:task"]}>
				Keep npm and its lockfile responsible for dependency installation. CafOps toolset intent and its authority planner can describe a selected development toolset, but they do not install packages. Do not model this transitive library as a managed service or invent an installer for this exception. A future installation action must bind exact native inputs, authority, results and recovery.
			</loweringHint>
			<nonGoal>
				No package installation, fork publication, compiler merge, audit waiver or successful test result is asserted by this declaration.
			</nonGoal>
			<nonGoal>
				No claim that these external task and source references are already imported into the Caffeine graph.
			</nonGoal>
			<migrationOrDeletionPlan>
				Retire the temporary fork selection after a reviewed upstream release passes the same security and compatibility checks. Keep this explanation as historical rationale, with a link to the replacing selection. Do not retain a parallel installer or second lockfile authority.
			</migrationOrDeletionPlan>
			<sourceReference label="Dependency repair intent" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/ReleaseDependencyRepair.hx" />
			<provenance label="Owner-directed dependency repair" uri="caf://project/caf:reflaxe-elixir:project:root/source/caf/ReleaseDependencyRepair.hx" role="caf.provenance.authored-by" />
		</conceptModel>;
}
