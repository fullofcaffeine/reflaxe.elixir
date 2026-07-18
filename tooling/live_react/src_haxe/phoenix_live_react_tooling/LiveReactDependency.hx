package phoenix_live_react_tooling;

import elixir.Base;
import elixir.Crypto;
import elixir.ElixirException;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Enum;
import elixir.ErlangFile;
import elixir.File;
import elixir.Jason;
import elixir.Keyword;
import elixir.Kernel;
import elixir.List;
import elixir.Path;
import elixir.Regex;
import elixir.System;
import elixir.Version;
import elixir.mix.DependencyLock;
import elixir.mix.Mix;
import elixir.mix.Project;
import elixir.mix.ProjectStack;
import elixir.mix.Task;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.NativeException;
import elixir.types.Term;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactDependency;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactDependencySource;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactResolvedDependency;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactResolverContext;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactTopology;

/**
 * Stock LiveReact dependency resolution and lockfile ownership.
 *
 * Mix remains the canonical resolver. This module validates the loaded
 * declaration, permits resolution of only `:live_react`, proves npm points at
 * the same checkout, and records enough state for exact removal.
 */
@:keep
@:native("HaxePhoenixLiveReact.Dependency")
class LiveReactDependencyResolver {
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final ENOENT:Atom = "enoent";
	static inline final LIVE_REACT:Atom = "live_react";
	static inline final GIT:Atom = "git";
	static inline final HEX:Atom = "hex";
	static inline final PATH_SOURCE:Atom = "path";
	static inline final ABSOLUTE:Atom = "absolute";
	static inline final RELATIVE:Atom = "relative";
	static inline final SHA256:Atom = "sha256";
	static inline final LOWER:Atom = "lower";
	static inline final CASE_KEY:Atom = "case";
	static inline final LIMIT:Atom = "limit";
	static inline final INFINITY:Atom = "infinity";
	static inline final WRITE:Atom = "write";
	static inline final EXCLUSIVE:Atom = "exclusive";
	static inline final POSITIVE:Atom = "positive";
	static inline final MONOTONIC:Atom = "monotonic";
	static inline final DEPS:Atom = "deps";
	static inline final LOCKFILE:Atom = "lockfile";
	static inline final DEPS_PATH:Atom = "deps_path";
	static inline final MIX_DEPENDENCIES:Atom = "mix_dependencies";
	static inline final DEPENDENCY_RESOLVER:Atom = "dependency_resolver";
	static inline final GIT_REVISION:Atom = "git_revision";
	static inline final LOCK_CONTENT:Atom = "lock_content";
	static inline final DEPENDENCY_PATH:Atom = "dependency_path";
	static inline final TRIM:Atom = "trim";
	static inline final STDERR_TO_STDOUT:Atom = "stderr_to_stdout";

	public static function defaultDependency():Term {
		var options:KeywordList<Term> = [
			{_0: GIT, _1: IntegrationCore.LIVE_REACT_REPOSITORY},
			{_0: "ref", _1: IntegrationCore.LIVE_REACT_REVISION}
		];
		return {_0: LIVE_REACT, _1: options};
	}

	public static function resolve(root:String, topology:LiveReactTopology, existingManifest:Term, opts:KeywordList<Term>,
			allowResolution:Bool):LiveReactDependency {
		var dependencies:Array<Term> = Keyword.get(opts, MIX_DEPENDENCIES, []);
		var declaration:Term = Enum.find(dependencies, function(candidate:Term):Bool {
			var name = dependencyName(candidate);
			return name == LIVE_REACT;
		});

		var mixExs = File.readBang(Path.joinTwo(root, "mix.exs"));
		var markerOwned = ElixirString.contains(mixExs, "BEGIN reflaxe_elixir live_react_dependency");
		var textualDeclaration = Regex.match(rx("\\{\\s*:live_react\\b"), mixExs);
		if (textualDeclaration && declaration == null && !markerOwned)
			return
				Kernel.raiseValue("mix.exs declares :live_react, but the loaded Mix project did not expose that dependency. No writes occurred. Re-run the task in the project root after reloading Mix.");

		var dependencyOwned:Bool;
		if (existingManifest != null) {
			dependencyOwned = manifestManagedBool(existingManifest, "dependencyOwned");
		} else if (markerOwned) {
			return Kernel.raiseValue("mix.exs contains a PhoenixHx LiveReact dependency marker but "
				+ IntegrationCore.MANIFEST_FILENAME
				+ " is missing. No writes occurred. Restore the manifest or remove the stale marker manually.");
		} else {
			dependencyOwned = !textualDeclaration;
		}

		var expectedSource = dependencySource(declaration, dependencyOwned);
		var lockPath = Path.joinTwo(root, "mix.lock");
		var lockSource = readLockSource(lockPath);
		var initialLockContent:String = Kernel.elemAs(lockSource, 0);
		var lockExisted:Bool = Kernel.elemAs(lockSource, 1);
		var initialLock = readLockContent(initialLockContent, lockPath);

		var originalLockState:Term;
		if (existingManifest != null) {
			var restores = manifestRestores(existingManifest);
			LiveReactSourcePatcher.requireRestoreKey(restores, "mix.lockOriginalState");
			originalLockState = validateOriginalLockState(ElixirMap.fetchBangTerm(restores, "mix.lockOriginalState"));
		} else {
			originalLockState = originalLockStateFor(initialLockContent, initialLock, lockExisted);
		}

		if (dependencyOwned && existingManifest == null && ElixirMap.hasKeyTerm(initialLock, LIVE_REACT))
			return
				Kernel.raiseValue("mix.lock already contains an unowned :live_react entry while mix.exs has no matching dependency. No writes occurred. Remove the stale lock entry or declare the dependency explicitly before retrying.");

		var checkout = dependencyCheckout(root, expectedSource);
		var current = validateResolvedDependency(expectedSource, initialLock, checkout, topology, opts);
		var resolved:LiveReactResolvedDependency;
		var lockContent:String;
		var lockChanged:Bool;

		var currentTag = tag(current);
		if (currentTag == OK) {
			resolved = Kernel.elemAs(current, 1);
			lockContent = initialLockContent;
			lockChanged = false;
		} else if (!allowResolution) {
			return Kernel.raiseValue("LiveReact dependency drift: "
				+ Kernel.toString(Kernel.elem(current, 1))
				+ ". No writes occurred and --check did not access the network. Run `mix haxe.phoenix.live_react` to resolve the checked dependency.");
		} else {
			var resolver:LiveReactResolverContext->Term = Keyword.get(opts, DEPENDENCY_RESOLVER,
				function(context:LiveReactResolverContext):Term return resolveWithLoadedMix(context));
			var context:LiveReactResolverContext = {
				root: root,
				currentLockContent: initialLockContent,
				dependencies: dependencies,
				dependency: declaration == null ? defaultDependency() : declaration,
				dependencyOwned: dependencyOwned,
				dependencyPath: checkout
			};
			var resolution = resolver(context);
			var resolvedLockContent:String = ElixirMap.fetchBangTerm(resolution, LOCK_CONTENT);
			var resolvedCheckout:String = ElixirMap.getTypedWithDefault(resolution, DEPENDENCY_PATH, checkout);
			var resolvedLock = readLockContent(resolvedLockContent, "temporary LiveReact lock");
			if (ElixirMap.deleteTerm(resolvedLock, LIVE_REACT) != ElixirMap.deleteTerm(initialLock, LIVE_REACT))
				return
					Kernel.raiseValue("Mix changed lock entries unrelated to :live_react while resolving the integration. No tracked files were written. Converge the existing dependencies first, then retry.");

			var validated = validateResolvedDependency(expectedSource, resolvedLock, resolvedCheckout, topology, opts);
			var validatedTag = tag(validated);
			if (validatedTag != OK)
				return Kernel.raiseValue("Mix resolved :live_react, but its identity is not usable: "
					+ Kernel.toString(Kernel.elem(validated, 1))
					+ ". No tracked integration files were written.");
			resolved = Kernel.elemAs(validated, 1);
			var ownedLock = insertLockEntry(initialLockContent, initialLock, ElixirMap.fetchBangTerm(resolvedLock, LIVE_REACT));
			lockContent = ownedLock;
			lockChanged = ownedLock != initialLockContent;
		}

		if (existingManifest != null) {
			if (ElixirMap.get(existingManifest, "mixDependency") != resolved.identity
				|| ElixirMap.get(existingManifest, "npmReference") != resolved.npmReference)
				return
					Kernel.raiseValue("LiveReact dependency identity changed from the owned manifest. No writes occurred. Remove and re-apply the integration after reviewing the upstream change.");
		}

		return {
			identity: resolved.identity,
			npmReference: resolved.npmReference,
			checkout: resolved.checkout,
			source: resolved.source,
			owned: dependencyOwned,
			lockOwned: existingManifest == null ? dependencyOwned : manifestManagedBool(existingManifest, "lockOwned"),
			lockContent: lockContent,
			lockChanged: lockChanged,
			originalLockState: originalLockState
		};
	}

	public static function writeLockIfChanged(plan:PatchPlan, root:String, dependency:LiveReactDependency):PatchPlan {
		return dependency.lockChanged ? ProjectPatch.writeFileBang(plan, Path.joinTwo(root, "mix.lock"), dependency.lockContent) : plan;
	}

	public static function removeOwnedLock(plan:PatchPlan, root:String, manifest:Term, retainLiveReact:Bool):PatchPlan {
		if (retainLiveReact || !manifestManagedBool(manifest, "lockOwned"))
			return plan;
		var path = Path.joinTwo(root, "mix.lock");
		var restores = manifestRestores(manifest);
		LiveReactSourcePatcher.requireRestoreKey(restores, "mix.lockOriginalState");
		var originalState = validateOriginalLockState(ElixirMap.fetchBangTerm(restores, "mix.lockOriginalState"));
		var currentContent = File.readBang(path);
		var currentLock = readLockContent(currentContent, path);
		if (!ElixirMap.hasKeyTerm(currentLock, LIVE_REACT))
			return
				Kernel.raiseValue("the task-owned :live_react lock entry is missing. No writes occurred. Restore the lock entry or retain LiveReact as hand-owned before retrying.");
		var retainedLock = ElixirMap.deleteTerm(currentLock, LIVE_REACT);
		var retainedContent = removeLockEntryLine(currentContent, LIVE_REACT);
		var kind:String = ElixirMap.fetchBangTerm(originalState, "kind");
		if (Kernel.mapSize(retainedLock) == 0 && kind == "missing")
			return ProjectPatch.deleteFileBang(plan, path);
		if (Kernel.mapSize(retainedLock) == 0 && kind == "empty")
			return ProjectPatch.writeFileBang(plan, path, ElixirMap.fetchBangTerm(originalState, "content"));
		return ProjectPatch.writeFileBang(plan, path, retainedContent);
	}

	public static function validateOriginalLockState(state:Term):Term {
		if (!Kernel.isMap(state))
			return invalidOriginalLockState();
		var kind:Null<String> = ElixirMap.getTyped(state, "kind");
		if (kind == "missing")
			return state;
		if (kind == "empty") {
			var content:Null<String> = ElixirMap.getTyped(state, "content");
			if (content != null && supportedEmptyLock(content))
				return state;
		}
		if (kind == "populated") {
			var digest:Null<String> = ElixirMap.getTyped(state, "sha256");
			if (digest != null && Kernel.byteSize(digest) == 64)
				return state;
		}
		return invalidOriginalLockState();
	}

	static function invalidOriginalLockState():Term {
		return Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " has invalid original mix.lock ownership metadata. No writes occurred.");
	}

	static function dependencyName(declaration:Term):Null<Atom> {
		if (!Kernel.isTuple(declaration))
			return null;
		var size = Kernel.tupleSize(declaration);
		if ((size == 2 || size == 3) && Kernel.isAtom(Kernel.elem(declaration, 0)))
			return Kernel.elemAs(declaration, 0);
		return null;
	}

	static function dependencySource(declaration:Term, owned:Bool):LiveReactDependencySource {
		if (owned) {
			var expected:LiveReactDependencySource = {
				kind: GIT,
				repository: normalizeGitRepository(IntegrationCore.LIVE_REACT_REPOSITORY),
				ref: IntegrationCore.LIVE_REACT_REVISION
			};
			if (declaration == null)
				return expected;
			var actual = declaredDependencySource(declaration);
			if (sameSource(actual, expected))
				return expected;
			return Kernel.raiseValue("the task-owned :live_react declaration changed from " + Kernel.inspect(defaultDependency()) + " to "
				+ Kernel.inspect(declaration) + ". No writes occurred.");
		}
		if (declaration == null)
			return
				Kernel.raiseValue("the LiveReact manifest says the Mix dependency is hand-owned, but the loaded project has no :live_react dependency. No writes occurred.");
		return declaredDependencySource(declaration);
	}

	static function declaredDependencySource(declaration:Term):LiveReactDependencySource {
		var name = dependencyName(declaration);
		if (!Kernel.isTuple(declaration) || name != LIVE_REACT)
			return unsupportedDeclaration(declaration);
		var size = Kernel.tupleSize(declaration);
		return
			size == 2 ? dependencySourceFromTwoTuple(declaration) : size == 3 ? dependencySourceFromThreeTuple(declaration) : unsupportedDeclaration(declaration);
	}

	static function dependencySourceFromTwoTuple(declaration:Term):LiveReactDependencySource {
		var second = Kernel.elem(declaration, 1);
		return Kernel.isBinary(second) ? {
			kind: HEX,
			packageName: "live_react",
			requirement: Kernel.toString(second)
		} : Kernel.isList(second) ? dependencySourceFromOptions(null, Kernel.elemAs(declaration, 1)) : unsupportedDeclaration(declaration);
	}

	static function dependencySourceFromThreeTuple(declaration:Term):LiveReactDependencySource {
		var requirement = Kernel.elem(declaration, 1);
		var options = Kernel.elem(declaration, 2);
		return Kernel.isBinary(requirement)
			&& Kernel.isList(options) ? dependencySourceFromOptions(Kernel.toString(requirement),
				Kernel.elemAs(declaration, 2)) : unsupportedDeclaration(declaration);
	}

	static function unsupportedDeclaration(declaration:Term):LiveReactDependencySource {
		return Kernel.raiseValue("unsupported :live_react dependency declaration "
			+ Kernel.inspect(declaration)
			+ ". No writes occurred. Use a Git, Hex, or project-relative path dependency.");
	}

	static function dependencySourceFromOptions(requirement:Null<String>, options:KeywordList<Term>):LiveReactDependencySource {
		var git:Term = Keyword.get(options, GIT, null);
		if (git != null)
			return {
				kind: GIT,
				repository: normalizeGitRepository(Kernel.toString(git)),
				ref: Keyword.get(options, "ref", null)
			};
		var path:Term = Keyword.get(options, PATH_SOURCE, null);
		if (path != null)
			return {kind: PATH_SOURCE, path: Kernel.toString(path)};
		if (requirement != null) {
			var packageValue:Term = Keyword.get(options, HEX, LIVE_REACT);
			return {kind: HEX, packageName: Kernel.toString(packageValue), requirement: requirement};
		}
		return Kernel.raiseValue("unsupported :live_react dependency options " + Kernel.inspect(options) + ". No writes occurred.");
	}

	static function sameSource(left:LiveReactDependencySource, right:LiveReactDependencySource):Bool {
		if (left.kind != right.kind)
			return false;
		if (left.kind == GIT)
			return left.repository == right.repository && left.ref == right.ref;
		if (left.kind == HEX)
			return left.packageName == right.packageName && left.requirement == right.requirement;
		return left.path == right.path;
	}

	static function dependencyCheckout(root:String, source:LiveReactDependencySource):String {
		return source.kind == PATH_SOURCE ? Path.expandRelativeTo(source.path, root) : Path.join([root, "deps", "live_react"]);
	}

	static function validateResolvedDependency(source:LiveReactDependencySource, lock:Term, checkout:String, topology:LiveReactTopology,
			opts:KeywordList<Term>):Term {
		var directoryResult = validateCheckoutDirectory(checkout);
		if (directoryResult != OK)
			return directoryResult;
		var identityResult = identityFromLock(source, lock, checkout, topology.root);
		var identityTag = tag(identityResult);
		if (identityTag != OK)
			return identityResult;
		var identity = Kernel.elem(identityResult, 1);
		var checkoutResult = validateCheckoutIdentity(identity, checkout, opts);
		if (checkoutResult != OK)
			return checkoutResult;
		var npmResult = npmReference(topology, checkout);
		var npmTag = tag(npmResult);
		if (npmTag != OK)
			return npmResult;
		var resolved:LiveReactResolvedDependency = {
			identity: identity,
			npmReference: Kernel.elemAs(npmResult, 1),
			checkout: checkout,
			source: source
		};
		return {_0: OK, _1: resolved};
	}

	static function validateCheckoutDirectory(checkout:String):Term {
		if (!File.dir(checkout))
			return {_0: ERROR, _1: "dependency checkout is missing at " + checkout};
		if (!File.regular(Path.joinTwo(checkout, "package.json")))
			return {_0: ERROR, _1: checkout + " is missing stock LiveReact package.json"};
		if (!File.regular(Path.joinTwo(checkout, "mix.exs")))
			return {_0: ERROR, _1: checkout + " is missing stock LiveReact mix.exs"};
		return OK;
	}

	static function identityFromLock(source:LiveReactDependencySource, lock:Term, checkout:String, root:String):Term {
		if (source.kind == GIT)
			return gitIdentity(source, ElixirMap.get(lock, LIVE_REACT));
		if (source.kind == HEX)
			return hexIdentity(source, ElixirMap.get(lock, LIVE_REACT));
		return pathIdentity(source, checkout, root);
	}

	static function gitIdentity(source:LiveReactDependencySource, entry:Term):Term {
		if (entry == null)
			return {_0: ERROR, _1: "mix.lock has no :live_react entry"};
		if (!Kernel.isTuple(entry)
			|| Kernel.tupleSize(entry) != 4
			|| Kernel.elem(entry, 0) != GIT
			|| !Kernel.isBinary(Kernel.elem(entry, 1))
			|| !Kernel.isBinary(Kernel.elem(entry, 2)))
			return {_0: ERROR, _1: "mix.lock contains " + Kernel.inspect(entry) + " instead of a Git LiveReact lock"};
		var normalized = normalizeGitRepository(Kernel.elemAs(entry, 1));
		var revision:String = Kernel.elemAs(entry, 2);
		if (normalized != source.repository)
			return {_0: ERROR,
				_1: "Mix lock repository "
				+ Kernel.inspect(normalized)
				+ " does not match "
				+ Kernel.inspect(source.repository)};
		if (!Regex.match(rxWithOptions("^[0-9a-f]{40}$", "i"), revision))
			return {_0: ERROR, _1: "Mix lock revision is not a full Git commit"};
		if (source.ref != null
			&& Regex.match(rxWithOptions("^[0-9a-f]{40}$", "i"), source.ref)
			&& ElixirString.downcase(source.ref) != ElixirString.downcase(revision))
			return {_0: ERROR, _1: "Mix lock revision does not match the declared Git ref"};
		var identity = jsonObject([
			{_0: "name", _1: "live_react"},
			{_0: "sourceKind", _1: "git"},
			{_0: "repository", _1: normalized},
			{_0: "resolvedRevision", _1: ElixirString.downcase(revision)}
		]);
		return {_0: OK, _1: identity};
	}

	static function hexIdentity(source:LiveReactDependencySource, entry:Term):Term {
		if (entry == null)
			return {_0: ERROR, _1: "mix.lock has no :live_react entry"};
		if (!Kernel.isTuple(entry)
			|| Kernel.tupleSize(entry) != 8
			|| Kernel.elem(entry, 0) != HEX
			|| !Kernel.isBinary(Kernel.elem(entry, 2))
			|| !Kernel.isBinary(Kernel.elem(entry, 3)))
			return {_0: ERROR, _1: "mix.lock contains " + Kernel.inspect(entry) + " instead of a Hex LiveReact lock"};
		var packageName = Kernel.toString(Kernel.elem(entry, 1));
		var version:String = Kernel.elemAs(entry, 2);
		if (packageName != source.packageName)
			return {_0: ERROR, _1: "Hex package " + packageName + " does not match " + source.packageName};
		var requirementResult = validateHexRequirement(version, source.requirement);
		if (requirementResult != OK)
			return requirementResult;
		var identity = jsonObject([
			{_0: "name", _1: "live_react"},
			{_0: "sourceKind", _1: "hex"},
			{_0: "package", _1: packageName},
			{_0: "repository", _1: Kernel.toString(Kernel.elem(entry, 6))},
			{_0: "resolvedVersion", _1: version},
			{_0: "checksum", _1: normalizeLockChecksum(Kernel.elem(entry, 3))},
			{_0: "outerChecksum", _1: normalizeLockChecksum(Kernel.elem(entry, 7))}
		]);
		return {_0: OK, _1: identity};
	}

	static function validateHexRequirement(version:String, requirement:String):Term {
		try {
			return Version.matches(version, requirement) ? OK : {_0: ERROR, _1: "Hex version " + version + " does not satisfy " + requirement};
		} catch (error:NativeException) {
			return {_0: ERROR, _1: ElixirException.message(error)};
		}
	}

	static function pathIdentity(source:LiveReactDependencySource, checkout:String, root:String):Term {
		var declared = source.path;
		var expanded = Path.expandRelativeTo(declared, root);
		var declaredType = Path.typeAtom(declared);
		if (declaredType == ABSOLUTE)
			return {_0: ERROR, _1: "path dependencies must be project-relative"};
		if (!insideRoot(root, expanded))
			return {_0: ERROR, _1: "path dependency escapes the Phoenix project"};
		if (Path.expand(checkout) != expanded)
			return {_0: ERROR, _1: "resolved checkout does not match the declared path dependency"};
		var packageValue = Jason.decodeStrict(File.readBang(Path.joinTwo(checkout, "package.json")));
		var version:Term = ElixirMap.get(packageValue, "version");
		if (!Kernel.isBinary(version))
			return {_0: ERROR, _1: "path dependency package.json has no string version"};
		var identity = jsonObject([
			{_0: "name", _1: "live_react"},
			{_0: "sourceKind", _1: "path"},
			{_0: "path", _1: Path.relativeTo(expanded, root)},
			{_0: "packageVersion", _1: version}
		]);
		return {_0: OK, _1: identity};
	}

	static function validateCheckoutIdentity(identity:Term, checkout:String, opts:KeywordList<Term>):Term {
		if (ElixirMap.get(identity, "sourceKind") != "git")
			return OK;
		var expected:String = ElixirMap.fetchBangTerm(identity, "resolvedRevision");
		var revisionReader:String->String = Keyword.get(opts, GIT_REVISION, function(path:String):String return gitRevision(path));
		try {
			return ElixirString.downcase(revisionReader(checkout)) == expected ? OK : {_0: ERROR, _1: "dependency checkout HEAD does not match mix.lock"};
		} catch (error:NativeException) {
			return {_0: ERROR, _1: "cannot verify dependency checkout: " + ElixirException.message(error)};
		}
	}

	static function gitRevision(checkout:String):String {
		var options:KeywordList<Term> = [{_0: STDERR_TO_STDOUT, _1: true}];
		var command = System.cmdWithKeywordOptions("git", ["-C", checkout, "rev-parse", "HEAD"], options);
		if (command._1 == 0)
			return ElixirString.trim(command._0);
		return Kernel.raiseValue("git rev-parse failed: " + ElixirString.trim(command._0));
	}

	static function npmReference(topology:LiveReactTopology, checkout:String):Term {
		var physical = LiveReactHost.physicalDirectory(Path.expand(checkout));
		var physicalTag = tag(physical);
		if (physicalTag != OK)
			return {_0: ERROR, _1: "cannot resolve npm LiveReact checkout: " + LiveReactHost.formatPathError(Kernel.elem(physical, 1))};
		return buildNpmReference(topology, Kernel.elemAs(physical, 1));
	}

	static function buildNpmReference(topology:LiveReactTopology, absoluteCheckout:String):Term {
		var fromRoot = Path.relativeTo(absoluteCheckout, topology.root);
		if (!insideRoot(topology.root, absoluteCheckout))
			return {_0: ERROR, _1: "npm LiveReact checkout escapes the Phoenix project"};
		var fromRootType = Path.typeAtom(fromRoot);
		if (fromRootType != RELATIVE)
			return {_0: ERROR, _1: "npm LiveReact path is not project-relative"};
		if (fromRoot == ".")
			return {_0: ERROR, _1: "npm LiveReact checkout cannot be the package root"};
		var prefix = topology.packageRootRelative == "." ? "" : "../";
		return {_0: OK, _1: "file:" + prefix + fromRoot};
	}

	static function insideRoot(root:String, path:String):Bool {
		var relative = Path.relativeTo(path, root);
		var relativeType = Path.typeAtom(relative);
		return relative == "." || (relativeType == RELATIVE && !ElixirString.startsWith(relative, ".."));
	}

	static function normalizeGitRepository(repository:String):String {
		var normalized = ElixirString.trim(repository);
		normalized = Regex.replace(rx("^git://"), normalized, "https://");
		normalized = Regex.replace(rx("^git@github\\.com:"), normalized, "https://github.com/");
		normalized = ElixirString.trimTrailingWith(normalized, "/");
		return Regex.replace(rx("\\.git$"), normalized, "");
	}

	static function normalizeLockChecksum(checksum:Term):Term {
		if (checksum == null)
			return null;
		if (Kernel.isBinary(checksum)) {
			var value:String = Kernel.toString(checksum);
			if (Regex.match(rxWithOptions("^[0-9a-f]+$", "i"), value) && Kernel.remainder(Kernel.byteSize(value), 2) == 0)
				return ElixirString.downcase(value);
		}
		var options:KeywordList<Term> = [{_0: CASE_KEY, _1: LOWER}];
		return Base.encode16(checksum, options);
	}

	static function readLockSource(path:String):Term {
		var result = File.readResult(path);
		var resultTag = tag(result);
		if (resultTag == OK)
			return {_0: Kernel.elem(result, 1), _1: true};
		var reason = Kernel.elem(result, 1);
		if (reason == ENOENT)
			return {_0: "%{}\n", _1: false};
		return Kernel.raiseValue("cannot read " + path + ": " + ErlangFile.formatError(reason));
	}

	static function originalLockStateFor(content:String, lock:Term, existed:Bool):Term {
		if (!existed)
			return jsonObject([{_0: "kind", _1: "missing"}]);
		if (Kernel.mapSize(lock) == 0) {
			if (!supportedEmptyLock(content))
				return
					Kernel.raiseValue("mix.lock uses an unsupported empty-map layout. No writes occurred. Run `mix deps.get` to normalize it before enabling LiveReact.");
			return jsonObject([{_0: "kind", _1: "empty"}, {_0: "content", _1: content}]);
		}
		return jsonObject([{_0: "kind", _1: "populated"}, {_0: "sha256", _1: sha256(content)}]);
	}

	static function supportedEmptyLock(content:String):Bool {
		return content == "%{}" || content == "%{}\n" || content == "%{\n}" || content == "%{\n}\n";
	}

	static function insertLockEntry(content:String, lock:Term, entry:Term):String {
		if (ElixirMap.hasKeyTerm(lock, LIVE_REACT))
			return Kernel.raiseValue("cannot insert an owned :live_react lock entry over an existing entry. No writes occurred.");
		var updated:String;
		if (Kernel.mapSize(lock) == 0) {
			updated = renderLock(ElixirMap.putTerm(lock, LIVE_REACT, entry));
		} else {
			var lines = splitLines(content);
			var closing = canonicalLockClosingIndex(lines);
			var insertion = lockEntryInsertionIndex(lines, closing, "live_react");
			updated = Enum.join(List.insertAt(lines, insertion, lockEntryLine(LIVE_REACT, entry)), "\n");
		}
		var expected = ElixirMap.putTerm(lock, LIVE_REACT, entry);
		if (readLockContent(updated, "planned LiveReact lock") != expected)
			return Kernel.raiseValue("could not preserve mix.lock while inserting the LiveReact entry. No writes occurred.");
		return updated;
	}

	static function canonicalLockClosingIndex(lines:Array<String>):Int {
		var indexed = Enum.reverse(Enum.withIndex(lines));
		var index = Enum.findValue(indexed, -1, function(entry:Term):Null<Int> {
			var line:String = Kernel.elemAs(entry, 0);
			return ElixirString.trim(line) == "" ? null : Kernel.elemAs(entry, 1);
		});
		if (index >= 0 && ElixirString.trim(lines[index]) == "}")
			return index;
		return
			Kernel.raiseValue("mix.lock is not in the canonical multiline map shape. No writes occurred. Run `mix deps.get` to normalize it before enabling LiveReact.");
	}

	static function lockEntryInsertionIndex(lines:Array<String>, closing:Int, name:String):Int {
		var entries:Array<{_0:String, _1:Int}> = [];
		var pattern = rx("^\\s*\"([^\"]+)\":\\s+");
		for (index in 0...closing) {
			var match = Regex.run(pattern, lines[index]);
			if (match != null && match.length == 2)
				entries.push({_0: match[1], _1: index});
		}
		if (entries.length == 0)
			return
				Kernel.raiseValue("mix.lock contains dependencies but not canonical one-entry-per-line lock entries. No writes occurred. Run `mix deps.get` to normalize it before enabling LiveReact.");
		for (entry in entries)
			if (Kernel.greaterThan(entry._0, name))
				return entry._1;
		return closing;
	}

	static function lockEntryLine(name:Atom, entry:Term):String {
		var options:KeywordList<Term> = [{_0: LIMIT, _1: INFINITY}];
		return "  \"" + Kernel.toString(name) + "\": " + Kernel.inspectWithKeywordOptions(entry, options) + ",";
	}

	static function removeLockEntryLine(content:String, name:Atom):String {
		var lines = splitLines(content);
		var pattern = rx("^\\s*\"" + Regex.escape(Kernel.toString(name)) + "\":\\s+.*,$");
		var indices:Array<Int> = [];
		for (index in 0...lines.length)
			if (Regex.match(pattern, lines[index]))
				indices.push(index);
		if (indices.length != 1)
			return Kernel.raiseValue("mix.lock must contain exactly one canonical " + Kernel.toString(name) + " entry line. No writes occurred.");
		return Enum.join(List.deleteAt(lines, indices[0]), "\n");
	}

	static function sha256(content:String):String {
		var options:KeywordList<Term> = [{_0: CASE_KEY, _1: LOWER}];
		return Base.encode16(Crypto.hash(SHA256, content), options);
	}

	static function readLockContent(content:String, label:String):Term {
		var directory = Path.joinTwo(System.tmpDirBang(), "reflaxe_live_react_lock_read");
		File.mkdirRecursiveBang(directory);
		var id = System.uniqueIntegerWithAtomOptions([POSITIVE, MONOTONIC]);
		var path = Path.joinTwo(directory, Kernel.toString(id) + ".lock");
		try {
			File.writeBangWithAtomModes(path, content, [WRITE, EXCLUSIVE]);
			var result = DependencyLock.read(path);
			File.rmResult(path);
			return result;
		} catch (error:NativeException) {
			File.rmResult(path);
			return Kernel.raiseValue("cannot parse " + label + ": " + ElixirException.message(error));
		}
	}

	static function renderLock(lock:Term):String {
		var entries:Array<{_0:Atom, _1:Term}> = ElixirMap.toListTerm(lock);
		entries = Enum.sortBy(entries, function(entry:{_0:Atom, _1:Term}):String return Kernel.toString(entry._0));
		var body = Enum.mapJoin(entries, "\n", function(entry:{_0:Atom, _1:Term}):String {
			return lockEntryLine(entry._0, entry._1);
		});
		return Enum.join(["%{", body, "}", ""], "\n");
	}

	static function resolveWithLoadedMix(context:LiveReactResolverContext):Term {
		var projectFile = Project.projectFile();
		if (projectFile == null || Path.dirname(Path.expand(projectFile)) != context.root)
			return Kernel.raiseValue("dependency resolution must run from the target Mix project root");
		var directory = Path.joinTwo(System.tmpDirBang(),
			"reflaxe_live_react_resolve_" + Kernel.toString(System.uniqueIntegerWithAtomOptions([POSITIVE, MONOTONIC])));
		File.mkdirBang(directory);
		var lockfile = Path.joinTwo(directory, "mix.lock");
		File.writeBang(lockfile, context.currentLockContent);
		var dependencies = context.dependencies;
		var found = Enum.any(dependencies, function(dependency:Term):Bool {
			var name = dependencyName(dependency);
			return name == LIVE_REACT;
		});
		if (!found)
			dependencies = Enum.concatTwo([context.dependency], dependencies);
		Mix.ensureApplicationBang(HEX);
		var config:KeywordList<Term> = [
			{_0: DEPS, _1: dependencies},
			{_0: LOCKFILE, _1: lockfile},
			{_0: DEPS_PATH, _1: Path.joinTwo(context.root, "deps")}
		];
		ProjectStack.postConfig(config);
		try {
			Task.reenable("deps.get");
			Task.run("deps.get", ["live_react"]);
			var result = ElixirMap.new_();
			result = ElixirMap.putTerm(result, LOCK_CONTENT, File.readBang(lockfile));
			result = ElixirMap.putTerm(result, DEPENDENCY_PATH, context.dependencyPath);
			cleanupResolution(lockfile, directory);
			return result;
		} catch (error:NativeException) {
			cleanupResolution(lockfile, directory);
			return Kernel.raiseValue("could not resolve the checked stock LiveReact dependency: "
				+ ElixirException.message(error)
				+ ". No tracked integration files were written; ignored dependency downloads may remain in deps/.");
		}
	}

	static function cleanupResolution(lockfile:String, directory:String):Void {
		Enum.each([DEPS, LOCKFILE, DEPS_PATH], function(key:Atom):Void ProjectStack.popPostConfig(key));
		File.rmResult(lockfile);
		File.rmdirResult(directory);
	}

	static function manifestManagedBool(manifest:Term, key:String):Bool {
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		return ElixirMap.fetchBangTerm(managed, key);
	}

	static function manifestRestores(manifest:Term):Term {
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		return ElixirMap.fetchBangTerm(managed, "restores");
	}

	static function splitLines(content:String):Array<String> {
		var options:KeywordList<Term> = [{_0: TRIM, _1: false}];
		return ElixirString.splitWithKeywordOptions(content, "\n", options);
	}

	static function jsonObject(entries:Array<{_0:String, _1:Term}>):Term {
		var value = ElixirMap.new_();
		for (entry in entries)
			value = ElixirMap.putTerm(value, entry._0, entry._1);
		return value;
	}

	static function tag(value:Term):Atom {
		return Kernel.isTuple(value) ? Kernel.elemAs(value, 0) : value;
	}

	static function rx(pattern:String):Term {
		return Regex.compileBang(pattern);
	}

	static function rxWithOptions(pattern:String, options:String):Term {
		return Regex.compileBangWithOptions(pattern, options);
	}
}
