package phoenix_live_react_tooling;

import elixir.ElixirException;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Enum;
import elixir.ErlangFile;
import elixir.File;
import elixir.IO;
import elixir.Jason;
import elixir.Keyword;
import elixir.Kernel;
import elixir.Path;
import elixir.Regex;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.NativeException;
import elixir.types.Term;
import phoenix_live_react_tooling.LiveReactDependency.LiveReactDependencyResolver;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactComponent;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactComponentPlan;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactDependency;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactLifecyclePlan;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactManifestData;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactPackageRoot;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactRootLayout;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactSources;
import phoenix_live_react_tooling.LiveReactTypes.LiveReactTopology;
import phoenix_live_react_tooling.PatchTypes.PatchFileState;

/** Complete Haxe-authored setup/check/remove lifecycle for stock LiveReact. */
@:keep
@:native("HaxePhoenixLiveReact")
class LiveReactLifecycle {
	static inline final APPLY:Atom = "apply";
	static inline final CHECK:Atom = "check";
	static inline final REMOVE:Atom = "remove";
	static inline final CANCELLED:Atom = "cancelled";
	static inline final CLEAN:Atom = "clean";
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final ENOENT:Atom = "enoent";
	static inline final OWNED:Atom = "owned";
	static inline final UNOWNED:Atom = "unowned";
	static inline final REGULAR:Atom = "regular";
	static inline final MISSING:Atom = "missing";
	static inline final DELETE:Atom = "delete";
	static inline final ABSOLUTE:Atom = "absolute";
	static inline final RELATIVE_PATH:Atom = "relative";
	static inline final ROOT_LAYOUT:Atom = "root_layout";
	static inline final GENES:Atom = "genes";
	static inline final PLAIN_JS:Atom = "plain_js";
	static inline final HEEX_LAYOUT:Atom = "heex";
	static inline final HAXE_LAYOUT:Atom = "haxe";
	static inline final PACKAGE_ROOT:Atom = "package_root";
	static inline final CLIENT_MODE:Atom = "client_mode";
	static inline final YES:Atom = "yes";
	static inline final CONFIRM:Atom = "confirm";
	static inline final REPORT:Atom = "report";
	static inline final RECOVER:Atom = "recover";
	static inline final MANIFEST_QUESTION:Atom = "manifest?";
	static inline final PLAN:Atom = "plan";
	static inline final ACTION:Atom = "action";
	static inline final RELATIVE:Atom = "relative";
	static inline final PRETTY:Atom = "pretty";
	static inline final ADD_COMPONENT:Atom = "add_component";
	static inline final REMOVE_COMPONENT:Atom = "remove_component";
	static inline final APP_NAME:Atom = "app_name";
	static inline final MODULE_PATH:Atom = "module_path";
	static inline final EXPORT_NAME:Atom = "export_name";
	static inline final EXISTING:Atom = "existing";
	static inline final LEGACY_REGISTRY_FILE = "assets/react-components/registry.generated.js";

	@:native("apply!")
	public static function applyBang(projectRoot:String, opts:Null<KeywordList<Term>> = null):Term {
		return executeBang(projectRoot, APPLY, opts);
	}

	@:native("check!")
	public static function checkBang(projectRoot:String, opts:Null<KeywordList<Term>> = null):Term {
		return executeBang(projectRoot, CHECK, opts);
	}

	@:native("remove!")
	public static function removeBang(projectRoot:String, opts:Null<KeywordList<Term>> = null):Term {
		return executeBang(projectRoot, REMOVE, opts);
	}

	@:native("add_component!")
	public static function addComponentBang(projectRoot:String, name:String, opts:Null<KeywordList<Term>> = null):Term {
		return mutateComponentBang(projectRoot, name, ADD_COMPONENT, opts);
	}

	@:native("remove_component!")
	public static function removeComponentBang(projectRoot:String, name:String, opts:Null<KeywordList<Term>> = null):Term {
		return mutateComponentBang(projectRoot, name, REMOVE_COMPONENT, opts);
	}

	@:native("execute!")
	public static function executeBang(projectRoot:String, mode:Atom, opts:Null<KeywordList<Term>> = null):Term {
		var options = normalizeOptions(opts);
		var root = canonicalProjectRoot(projectRoot);
		var recoveryStatus = ProjectPatch.recoveryStatusBang(root);
		if (mode == CHECK && recoveryStatus != CLEAN)
			return Kernel.raiseValue("LiveReact integration check found an interrupted project patch transaction ("
				+ Kernel.inspect(recoveryStatus)
				+ "). No writes occurred. Re-run `mix haxe.phoenix.live_react` to recover it, then run `--check` again.");
		if (mode != CHECK)
			ProjectPatch.recoverBang(root);
		var existingManifest = readManifest(root, mode);
		var result = mode == REMOVE ? buildRemovePlan(root, existingManifest, options) : buildApplyPlan(root, existingManifest, options, mode == APPLY);
		return finishExecution(result, mode, options);
	}

	public static function defaultLiveReactDependency():Term {
		return LiveReactDependencyResolver.defaultDependency();
	}

	public static function compatibility():Term {
		return IntegrationCore.compatibility();
	}

	static function finishExecution(result:LiveReactLifecyclePlan, mode:Atom, opts:KeywordList<Term>):Term {
		var changes = ProjectPatch.changes(result.plan);
		if (mode == CHECK) {
			if (changes.length == 0)
				return dropPlan(result);
			return raiseDrift(changes);
		}

		var report:String->Void = Keyword.get(opts, REPORT, function(message:String):Void IO.puts(message));
		Enum.each(changes, function(change:Term):Void {
			var action:Term = ElixirMap.fetchBangTerm(change, ACTION);
			var relative:String = ElixirMap.fetchBangTerm(change, RELATIVE);
			report("[live-react] " + Kernel.toString(action) + " " + relative);
		});
		if (changes.length == 0)
			return dropPlan(result);
		if (Keyword.get(opts, YES, false)) {
			ProjectPatch.publishBang(result.plan);
			return dropPlan(result);
		}
		var confirm:String->Bool = Keyword.get(opts, CONFIRM, function(_prompt:String):Bool return false);
		if (!confirm(IntegrationCore.confirmationPrompt(mode, changes.length)))
			return CANCELLED;
		ProjectPatch.publishBang(result.plan);
		return dropPlan(result);
	}

	static function dropPlan(result:LiveReactLifecyclePlan):Term {
		return ElixirMap.dropTerm(result, [PLAN]);
	}

	static function raiseDrift(changes:Array<Term>):Term {
		var paths = Enum.mapJoin(changes, "\n", function(change:Term):String {
			return "  - " + ElixirMap.fetchBangTerm(change, RELATIVE);
		});
		return Kernel.raiseValue(Enum.join([
			"LiveReact integration drift detected:",
			paths,
			"No writes occurred. Run `mix haxe.phoenix.live_react` to reconcile owned state, or `--remove` to remove it."
		], "\n"));
	}

	static function canonicalProjectRoot(projectRoot:String):String {
		var expanded = Path.expand(projectRoot);
		var physical = LiveReactHost.physicalDirectory(expanded);
		var physicalTag = tag(physical);
		if (physicalTag != OK)
			return Kernel.raiseValue("cannot resolve Phoenix project root " + expanded + ": " + LiveReactHost.formatPathError(Kernel.elem(physical, 1)));
		var root:String = Kernel.elemAs(physical, 1);
		LiveReactHost.requireRegularFile(Path.joinTwo(root, "mix.exs"), "Mix project");
		return root;
	}

	static function readManifest(root:String, mode:Atom):Term {
		var path = Path.joinTwo(root, IntegrationCore.MANIFEST_FILENAME);
		var read = File.readResult(path);
		var readTag = tag(read);
		if (readTag == OK) {
			var manifest = decodeManifest(Kernel.elemAs(read, 1));
			return validateManifest(manifest, path);
		}
		var reason = Kernel.elem(read, 1);
		if (reason == ENOENT && mode == REMOVE)
			return Kernel.raiseValue("cannot remove PhoenixHx LiveReact integration: "
				+ IntegrationCore.MANIFEST_FILENAME
				+ " is missing. No writes occurred. Restore the owned manifest or remove the integration manually after reviewing every marker.");
		if (reason == ENOENT && mode == CHECK)
			return Kernel.raiseValue("LiveReact integration drift detected: "
				+ IntegrationCore.MANIFEST_FILENAME
				+ " is missing. No writes occurred. Run `mix haxe.phoenix.live_react` to install it.");
		if (reason == ENOENT)
			return null;
		return Kernel.raiseValue("cannot read " + path + ": " + ErlangFile.formatError(reason));
	}

	static function decodeManifest(content:String):Term {
		try {
			return Jason.decodeStrict(content);
		} catch (error:NativeException) {
			return Kernel.raiseValue("invalid " + IntegrationCore.MANIFEST_FILENAME + ": " + ElixirException.message(error) + ". No writes occurred.");
		}
	}

	static function validateManifest(manifest:Term, path:String):Term {
		if (!Kernel.isMap(manifest))
			return Kernel.raiseValue(path + " must contain a JSON object. No writes occurred.");
		if (ElixirMap.get(manifest, "schema") != IntegrationCore.SCHEMA
			|| ElixirMap.get(manifest, "generatedBy") != IntegrationCore.GENERATED_BY)
			return Kernel.raiseValue("unsupported or unowned LiveReact integration manifest at " + path + ". No writes occurred.");
		var required = [
			"schema",
			"generatedBy",
			"assetMode",
			"appName",
			"packageRoot",
			"clientMode",
			"mixDependency",
			"npmReference",
			"runtimePolicy",
			"components",
			"managed"
		];
		var keys:Array<String> = ElixirMap.keysTerm(manifest);
		if (Enum.sort(keys) != Enum.sort(required))
			return Kernel.raiseValue(path
				+ " has an unsupported key set. No writes occurred. Upgrade the integration tool or restore its generated manifest.");
		var managed = ElixirMap.get(manifest, "managed");
		if (!Kernel.isMap(managed)
			|| !Kernel.isList(ElixirMap.get(managed, "files"))
			|| !Kernel.isList(ElixirMap.get(managed, "markers"))
			|| !Kernel.isList(ElixirMap.get(managed, "packageKeys"))
			|| !Kernel.isMap(ElixirMap.get(managed, "restores"))
			|| !Kernel.isBoolean(ElixirMap.get(managed, "dependencyOwned"))
			|| !Kernel.isBoolean(ElixirMap.get(managed, "lockOwned")))
			return Kernel.raiseValue(path + " has invalid managed ownership metadata. No writes occurred.");
		var clientMode = ElixirMap.get(manifest, "clientMode");
		if (ElixirMap.get(manifest, "assetMode") != "vite"
			|| (clientMode != "genes" && clientMode != "plain-js")
			|| !Kernel.isBinary(ElixirMap.get(manifest, "appName"))
			|| !Kernel.isBinary(ElixirMap.get(manifest, "packageRoot"))
			|| !Kernel.isMap(ElixirMap.get(manifest, "mixDependency"))
			|| !Kernel.isBinary(ElixirMap.get(manifest, "npmReference"))
			|| !Kernel.isMap(ElixirMap.get(manifest, "runtimePolicy"))
			|| !Kernel.isList(ElixirMap.get(manifest, "components")))
			return Kernel.raiseValue(path + " has invalid integration metadata. No writes occurred.");
		LiveReactRegistry.validateAppName(ElixirMap.getTyped(manifest, "appName"));
		LiveReactRegistry.componentsFromManifest(ElixirMap.get(manifest, "components"));
		return manifest;
	}

	static function buildApplyPlan(root:String, existingManifest:Term, opts:KeywordList<Term>, allowResolution:Bool):LiveReactLifecyclePlan {
		var topology = discoverTopology(root, existingManifest, opts);
		validateOwnedTopology(existingManifest, topology);
		var components = existingManifest == null ? [] : LiveReactRegistry.componentsFromManifest(ElixirMap.get(existingManifest, "components"));
		validateRegisteredBoundaries(root, components);
		var dependency = LiveReactDependencyResolver.resolve(root, topology, existingManifest, opts, allowResolution);
		var packagePlan = LiveReactPackage.plan(topology, dependency, existingManifest);
		var source = readRequiredSources(topology);
		var restores = existingRestores(existingManifest);
		var mixPatched = LiveReactSourcePatcher.patchMixExs(source.mixExs, topology, dependency, restores);
		restores = LiveReactSourcePatcher.putRestore(mixPatched._1, "mix.lockOriginalState", dependency.originalLockState);
		var configPatched = LiveReactSourcePatcher.patchConfigExs(source.configExs, restores);
		var devPatched = LiveReactSourcePatcher.patchDevExs(source.devExs, topology, configPatched._1);
		var appPatched = LiveReactSourcePatcher.patchAppJs(source.appJs, devPatched._1);
		var layoutPatched = LiveReactSourcePatcher.patchRootLayout(source.rootLayout, topology, appPatched._1);
		var managedFiles = managedFilesFor(topology);
		var manifestData:LiveReactManifestData = {
			topology: topology,
			dependency: dependency,
			components: components,
			managedFiles: managedFiles,
			packageKeys: packagePlan.ownedKeys,
			restores: layoutPatched._1,
			dependencyOwned: dependency.owned,
			lockOwned: dependency.lockOwned
		};
		var manifest = renderManifest(manifestData);
		var plan = ProjectPatch.newBang(root, [{_0: RECOVER, _1: false}]);
		plan = planLegacyRegistryMigration(plan, root, existingManifest, topology);
		plan = ProjectPatch.writeFileBang(plan, Path.joinTwo(root, "mix.exs"), mixPatched._0);
		plan = LiveReactDependencyResolver.writeLockIfChanged(plan, root, dependency);
		plan = ProjectPatch.writeFileBang(plan, Path.join([root, "config", "config.exs"]), configPatched._0);
		plan = ProjectPatch.writeFileBang(plan, Path.join([root, "config", "dev.exs"]), devPatched._0);
		plan = ProjectPatch.writeFileBang(plan, Path.join([root, "assets", "js", "app.js"]), appPatched._0);
		plan = ProjectPatch.writeFileBang(plan, topology.rootLayout, layoutPatched._0);
		plan = ProjectPatch.writeFileBang(plan, topology.packageJson, packagePlan.content);
		plan = planManagedFile(plan, topology.viteConfig, IntegrationCore.renderViteConfig(topology.packageRootRelative));
		plan = planManagedFile(plan, topology.hooksFile, IntegrationCore.renderHooksFile());
		plan = planManagedFile(plan, topology.registryFile, IntegrationCore.renderRegistryFile(components));
		if (topology.reloadWrapper != null)
			plan = planManagedFile(plan, topology.reloadWrapper, LiveReactRegistry.renderReloadWrapper(topology.appName));
		plan = ProjectPatch.writeFileBang(plan, Path.joinTwo(root, IntegrationCore.MANIFEST_FILENAME), manifest, [{_0: MANIFEST_QUESTION, _1: true}]);
		return {
			plan: plan,
			mode: allowResolution ? APPLY : CHECK,
			packageRoot: topology.packageRootRelative,
			clientMode: topology.clientMode,
			dependency: dependency.identity,
			npmReference: dependency.npmReference,
			changes: ProjectPatch.changes(plan)
		};
	}

	static function buildRemovePlan(root:String, manifest:Term, opts:KeywordList<Term>):LiveReactLifecyclePlan {
		var topology = discoverTopology(root, manifest, opts);
		validateOwnedTopology(manifest, topology);
		var restores = existingRestores(manifest);
		var source = readRequiredSources(topology);
		var packagePlan = LiveReactPackage.remove(topology, manifest);
		var retainLiveReact = Enum.member(packagePlan.retainedKeys, "dependencies.live_react");
		var mixExs = LiveReactSourcePatcher.removeMixWiring(source.mixExs, manifest, topology, restores, retainLiveReact);
		var configExs = LiveReactSourcePatcher.removeConfigWiring(source.configExs, restores);
		var devExs = LiveReactSourcePatcher.removeDevWiring(source.devExs, topology, restores);
		var appJs = LiveReactSourcePatcher.removeAppJsWiring(source.appJs, restores);
		var rootLayout = LiveReactSourcePatcher.removeRootLayoutWiring(source.rootLayout, topology, restores);
		var plan = ProjectPatch.newBang(root, [{_0: RECOVER, _1: false}]);
		plan = ProjectPatch.writeFileBang(plan, Path.joinTwo(root, "mix.exs"), mixExs);
		plan = LiveReactDependencyResolver.removeOwnedLock(plan, root, manifest, retainLiveReact);
		plan = ProjectPatch.writeFileBang(plan, Path.join([root, "config", "config.exs"]), configExs);
		plan = ProjectPatch.writeFileBang(plan, Path.join([root, "config", "dev.exs"]), devExs);
		plan = ProjectPatch.writeFileBang(plan, Path.join([root, "assets", "js", "app.js"]), appJs);
		plan = ProjectPatch.writeFileBang(plan, topology.rootLayout, rootLayout);
		plan = ProjectPatch.writeFileBang(plan, topology.packageJson, packagePlan.content);
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		var ownedFiles:Array<String> = ElixirMap.fetchBangTerm(managed, "files");
		plan = Enum.reduce(ownedFiles, plan, function(relative:String, current:PatchPlan):PatchPlan {
			return planGeneratedRemoval(current, root, relative);
		});
		var manifestPath = Path.joinTwo(root, IntegrationCore.MANIFEST_FILENAME);
		plan = ProjectPatch.updateFileBang(plan, manifestPath, function(state:PatchFileState):Term {
			return state.state == REGULAR ? DELETE : Kernel.raiseValue(IntegrationCore.MANIFEST_FILENAME + " disappeared during removal planning");
		}, [{_0: MANIFEST_QUESTION, _1: true}]);
		var dependencyOwned:Bool = ElixirMap.fetchBangTerm(managed, "dependencyOwned");
		return {
			plan: plan,
			mode: REMOVE,
			packageRoot: topology.packageRootRelative,
			clientMode: topology.clientMode,
			retainedPackageKeys: packagePlan.retainedKeys,
			retainedLiveReactDependency: retainLiveReact && dependencyOwned,
			changes: ProjectPatch.changes(plan)
		};
	}

	static function mutateComponentBang(projectRoot:String, name:String, mode:Atom, opts:Null<KeywordList<Term>>):Term {
		var options = normalizeOptions(opts);
		var root = canonicalProjectRoot(projectRoot);
		ProjectPatch.recoverBang(root);
		var manifest = readManifest(root, APPLY);
		if (manifest == null)
			return
				Kernel.raiseValue("PhoenixHx LiveReact is not installed. No writes occurred. Run `mix haxe.phoenix.live_react` before registering a component.");
		var topology = discoverTopology(root, manifest, options);
		validateOwnedTopology(manifest, topology);
		var appNameValue:Term = Keyword.get(options, APP_NAME, null);
		if (!Kernel.isBinary(appNameValue))
			return Kernel.raiseValue("component scaffolding requires the current Mix application name. No writes occurred.");
		var appName = Kernel.toString(appNameValue);
		var modulePath:Null<String> = Keyword.get(options, MODULE_PATH, null);
		var exportName:Null<String> = Keyword.get(options, EXPORT_NAME, null);
		var requested = LiveReactRegistry.component(name, modulePath, exportName);
		var components = LiveReactRegistry.componentsFromManifest(ElixirMap.get(manifest, "components"));
		var existing = Enum.find(components, function(value:LiveReactComponent):Bool return value.name == requested.name);
		var planResult = mode == ADD_COMPONENT ? buildComponentAddPlan(root, topology, manifest, components, existing, requested, appName,
			options) : buildComponentRemovePlan(root, topology, manifest, components, existing, requested, appName);
		return finishComponentExecution(planResult, options);
	}

	static function buildComponentAddPlan(root:String, topology:LiveReactTopology, manifest:Term, components:Array<LiveReactComponent>,
			existing:Null<LiveReactComponent>, requested:LiveReactComponent, appName:String, opts:KeywordList<Term>):LiveReactComponentPlan {
		var plan = ProjectPatch.newBang(root, [{_0: RECOVER, _1: false}]);
		if (existing != null) {
			if (!sameComponent(existing, requested))
				return
					Kernel.raiseValue('LiveReact component ${requested.name} is already registered as ${existing.modulePath}#${existing.exportName}. No writes occurred. Remove it before changing its static identity.');
			return {
				plan: plan,
				mode: ADD_COMPONENT,
				name: requested.name,
				components: components,
				createdFiles: [],
				retainedFiles: existingSourceFiles(root, appName, requested),
				changes: []
			};
		}

		var useExisting = Keyword.get(opts, EXISTING, false);
		var createdFiles:Array<String> = [];
		if (useExisting) {
			validateRegisteredBoundary(root, requested);
		} else {
			var wrapper = LiveReactRegistry.wrapperRelativePath(appName, requested);
			var boundary = LiveReactRegistry.boundaryRelativePath(requested);
			var inner = LiveReactRegistry.innerRelativePath(requested);
			plan = planHandOwnedStarter(plan, root, wrapper, LiveReactRegistry.renderHaxeWrapper(appName, requested));
			plan = planHandOwnedStarter(plan, root, boundary, LiveReactRegistry.renderBoundary(requested));
			plan = planHandOwnedStarter(plan, root, inner, LiveReactRegistry.renderInnerComponent(requested));
			createdFiles = [wrapper, boundary, inner];
		}

		var updated = LiveReactRegistry.normalizeComponents(Enum.concatTwo(components, [requested]));
		plan = planManagedFile(plan, topology.registryFile, IntegrationCore.renderRegistryFile(updated));
		plan = ProjectPatch.writeFileBang(plan, Path.joinTwo(root, IntegrationCore.MANIFEST_FILENAME), renderManifestComponents(manifest, updated),
			[{_0: MANIFEST_QUESTION, _1: true}]);
		return {
			plan: plan,
			mode: ADD_COMPONENT,
			name: requested.name,
			components: updated,
			createdFiles: createdFiles,
			retainedFiles: [],
			changes: ProjectPatch.changes(plan)
		};
	}

	static function buildComponentRemovePlan(root:String, topology:LiveReactTopology, manifest:Term, components:Array<LiveReactComponent>,
			existing:Null<LiveReactComponent>, requested:LiveReactComponent, appName:String):LiveReactComponentPlan {
		var plan = ProjectPatch.newBang(root, [{_0: RECOVER, _1: false}]);
		if (existing == null) {
			return {
				plan: plan,
				mode: REMOVE_COMPONENT,
				name: requested.name,
				components: components,
				createdFiles: [],
				retainedFiles: [],
				changes: []
			};
		}
		var updated = Enum.filter(components, function(value:LiveReactComponent):Bool return value.name != requested.name);
		plan = planManagedFile(plan, topology.registryFile, IntegrationCore.renderRegistryFile(updated));
		plan = ProjectPatch.writeFileBang(plan, Path.joinTwo(root, IntegrationCore.MANIFEST_FILENAME), renderManifestComponents(manifest, updated),
			[{_0: MANIFEST_QUESTION, _1: true}]);
		return {
			plan: plan,
			mode: REMOVE_COMPONENT,
			name: requested.name,
			components: updated,
			createdFiles: [],
			retainedFiles: existingSourceFiles(root, appName, existing),
			changes: ProjectPatch.changes(plan)
		};
	}

	static function finishComponentExecution(result:LiveReactComponentPlan, opts:KeywordList<Term>):Term {
		var changes = ProjectPatch.changes(result.plan);
		var report:String->Void = Keyword.get(opts, REPORT, function(message:String):Void IO.puts(message));
		Enum.each(changes, function(change:Term):Void {
			var action:Term = ElixirMap.fetchBangTerm(change, ACTION);
			var relative:String = ElixirMap.fetchBangTerm(change, RELATIVE);
			report("[live-react] " + Kernel.toString(action) + " " + relative);
		});
		if (changes.length == 0)
			return dropComponentPlan(result);
		if (Keyword.get(opts, YES, false)) {
			ProjectPatch.publishBang(result.plan);
			return dropComponentPlan(result);
		}
		var confirm:String->Bool = Keyword.get(opts, CONFIRM, function(_prompt:String):Bool return false);
		var action = result.mode == ADD_COMPONENT ? "Register" : "Remove";
		if (!confirm(action + " React component " + result.name + " with " + Kernel.toString(changes.length) + " project change(s)?"))
			return CANCELLED;
		ProjectPatch.publishBang(result.plan);
		return dropComponentPlan(result);
	}

	static function dropComponentPlan(result:LiveReactComponentPlan):Term {
		return ElixirMap.dropTerm(result, [PLAN]);
	}

	static function renderManifestComponents(manifest:Term, components:Array<LiveReactComponent>):String {
		var updated = ElixirMap.putTerm(manifest, "components", LiveReactRegistry.toManifestTerms(components));
		var options:KeywordList<Term> = [{_0: PRETTY, _1: true}];
		return Enum.join([Jason.encodeStrictWithKeywordOptions(updated, options), ""], "\n");
	}

	static function planHandOwnedStarter(plan:PatchPlan, root:String, relative:String, content:String):PatchPlan {
		var path = Path.joinTwo(root, relative);
		var read = File.readResult(path);
		var readTag = tag(read);
		if (readTag == OK)
			return Kernel.raiseValue("cannot scaffold "
				+ relative
				+ ": a hand-owned source file already exists. No writes occurred. Re-run with --existing to register reviewed existing source instead.");
		var reason = Kernel.elem(read, 1);
		if (reason != ENOENT)
			return Kernel.raiseValue("cannot inspect starter path " + relative + ": " + ErlangFile.formatError(reason) + ". No writes occurred.");
		return ProjectPatch.writeFileBang(plan, path, content);
	}

	static function validateRegisteredBoundaries(root:String, components:Array<LiveReactComponent>):Void {
		Enum.each(components, function(value:LiveReactComponent):Void validateRegisteredBoundary(root, value));
	}

	static function validateRegisteredBoundary(root:String, value:LiveReactComponent):Void {
		var candidates = Enum.map(LiveReactRegistry.boundaryCandidates(value), function(relative:String):String {
			return Path.join([root, "assets", "react-components", relative]);
		});
		var matches = Enum.filter(candidates, function(path:String):Bool return File.regular(path));
		if (matches.length == 0)
			Kernel.raise('registered LiveReact component ${value.name} cannot resolve ${value.modulePath} under assets/react-components. No writes occurred. Restore its hand-owned boundary or remove the registry entry.');
		if (matches.length > 1)
			Kernel.raise('registered LiveReact component ${value.name} has ambiguous boundary modules: ${Enum.join(matches, ", ")}. No writes occurred. Keep exactly one supported extension.');
	}

	static function existingSourceFiles(root:String, appName:String, value:LiveReactComponent):Array<String> {
		var candidates = [
			LiveReactRegistry.wrapperRelativePath(appName, value),
			LiveReactRegistry.innerRelativePath(value)
		];
		candidates = Enum.concatTwo(candidates, Enum.map(LiveReactRegistry.boundaryCandidates(value), function(relative:String):String {
			return Path.join(["assets", "react-components", relative]);
		}));
		return Enum.filter(candidates, function(relative:String):Bool return File.regular(Path.joinTwo(root, relative)));
	}

	static function sameComponent(left:LiveReactComponent, right:LiveReactComponent):Bool {
		return left.name == right.name && left.modulePath == right.modulePath && left.exportName == right.exportName;
	}

	static function discoverTopology(root:String, existingManifest:Term, opts:KeywordList<Term>):LiveReactTopology {
		LiveReactHost.requireRegularFile(Path.join([root, "config", "config.exs"]), "Phoenix config");
		LiveReactHost.requireRegularFile(Path.join([root, "config", "dev.exs"]), "Phoenix development config");
		LiveReactHost.requireRegularFile(Path.join([root, "assets", "js", "app.js"]), "Phoenix JavaScript entry");
		var packageRoot = discoverPackageRoot(root, Keyword.get(opts, PACKAGE_ROOT, null));
		var rootLayout = discoverRootLayout(root);
		var appName = discoverAppName(existingManifest, Keyword.get(opts, APP_NAME, null));
		var detectedMode = detectClientMode(root);
		var requestedMode:Term = Keyword.get(opts, CLIENT_MODE, null);
		var clientMode:Atom;
		if (requestedMode == null) {
			clientMode = detectedMode;
		} else if ((requestedMode == GENES || requestedMode == PLAIN_JS) && requestedMode == detectedMode) {
			clientMode = requestedMode;
		} else if (requestedMode == GENES || requestedMode == PLAIN_JS) {
			return Kernel.raiseValue("requested client mode " + IntegrationCore.clientModeLabel(requestedMode)
				+ " does not match the project topology (detected " + IntegrationCore.clientModeLabel(detectedMode)
				+ "). No writes occurred. Run the Phoenix scaffold first.");
		} else {
			return Kernel.raiseValue("invalid LiveReact client mode " + Kernel.inspect(requestedMode) + " (expected genes or plain-js)");
		}
		if (existingManifest != null) {
			var expectedPackage = ElixirMap.get(existingManifest, "packageRoot");
			var expectedMode = ElixirMap.get(existingManifest, "clientMode");
			if (expectedPackage != packageRoot.relative)
				return Kernel.raiseValue("LiveReact package-root drift: the manifest owns "
					+ Kernel.inspect(expectedPackage)
					+ ", but discovery selected "
					+ Kernel.inspect(packageRoot.relative)
					+ ". No writes occurred. Use the original --package-root or remove the integration first.");
			if (expectedMode != IntegrationCore.clientModeLabel(clientMode))
				return Kernel.raiseValue("LiveReact client-mode drift: the manifest owns "
					+ Kernel.toString(expectedMode)
					+ ", but the project now looks like "
					+ IntegrationCore.clientModeLabel(clientMode)
					+ ". No writes occurred. Remove and re-apply the integration after converging the Phoenix scaffold.");
		}
		return {
			root: root,
			appName: appName,
			packageRoot: packageRoot.absolute,
			packageRootRelative: packageRoot.relative,
			packageJson: Path.joinTwo(packageRoot.absolute, "package.json"),
			viteConfig: Path.joinTwo(packageRoot.absolute, "vite.config.mjs"),
			hooksFile: Path.join([root, "assets", "js", "live-react-hooks.js"]),
			registryFile: Path.join([root, "assets", "react-components", "registry.generated.ts"]),
			rootLayout: rootLayout.path,
			rootLayoutKind: rootLayout.kind,
			reloadWrapper: rootLayout.kind == HAXE_LAYOUT ? Path.joinTwo(root, LiveReactRegistry.reloadWrapperRelativePath(appName)) : null,
			reloadComponentModule: rootLayout.kind == HAXE_LAYOUT ? LiveReactRegistry.reloadComponentModule(appName) : null,
			clientMode: clientMode
		};
	}

	static function discoverAppName(existingManifest:Term, requested:Term):String {
		var owned = existingManifest == null ? null : ElixirMap.get(existingManifest, "appName");
		var value = requested == null ? owned : requested;
		if (!Kernel.isBinary(value))
			return Kernel.raiseValue("could not determine the Mix application name required by LiveReact project ownership. No writes occurred.");
		var appName = Kernel.toString(value);
		LiveReactRegistry.validateAppName(appName);
		if (owned != null && owned != appName)
			return Kernel.raiseValue("LiveReact app-name drift: the manifest owns " + Kernel.inspect(owned) + ", but the loaded Mix project reports "
				+ Kernel.inspect(appName) + ". No writes occurred.");
		return appName;
	}

	static function discoverPackageRoot(root:String, explicit:Term):LiveReactPackageRoot {
		var candidates:Array<String>;
		if (explicit == null) {
			candidates = Enum.filter([".", "assets"], function(relative:String):Bool {
				return File.regular(Path.join([root, relative, "package.json"]));
			});
		} else if (Kernel.isBinary(explicit)) {
			candidates = [validatePackageRootArgument(Kernel.toString(explicit))];
		} else {
			return Kernel.raiseValue("invalid --package-root " + Kernel.inspect(explicit));
		}
		var relative:String;
		if (candidates.length == 1)
			relative = candidates[0];
		else if (candidates.length == 0)
			return
				Kernel.raiseValue("could not find package.json at the project root or assets/package.json. No writes occurred. Create one package root or pass a project-relative --package-root.");
		else
			return Kernel.raiseValue("multiple npm package roots found: " + Enum.join(candidates, ", ")
				+ ". No writes occurred. Pass --package-root explicitly.");
		var normalized = normalizeRelativeRoot(relative);
		if (normalized != "." && normalized != "assets")
			return Kernel.raiseValue("unsupported npm package root "
				+ Kernel.inspect(relative)
				+ ". No writes occurred. The initial integration supports only package.json or assets/package.json.");
		var absolute = Path.expandRelativeTo(relative, root);
		var physical = LiveReactHost.physicalDirectory(absolute);
		var physicalTag = tag(physical);
		if (physicalTag != OK)
			return Kernel.raiseValue("cannot resolve package root " + relative + ": " + LiveReactHost.formatPathError(Kernel.elem(physical, 1)));
		var real:String = Kernel.elemAs(physical, 1);
		if (!insideRoot(root, real))
			return Kernel.raiseValue("package root " + Kernel.inspect(relative) + " resolves outside the Phoenix project. No writes occurred.");
		LiveReactHost.requireRegularFile(Path.joinTwo(real, "package.json"), "npm package");
		return {relative: normalized, absolute: real};
	}

	static function validatePackageRootArgument(value:String):String {
		if (value == "")
			return Kernel.raiseValue("--package-root may not be empty");
		var valueType = Path.typeAtom(value);
		if (valueType == ABSOLUTE)
			return Kernel.raiseValue("--package-root must be project-relative");
		if (Enum.any(Path.split(value), function(part:String):Bool return part == ".." || part == ""))
			return Kernel.raiseValue("--package-root may not contain parent traversal");
		return value;
	}

	static function normalizeRelativeRoot(value:String):String {
		return value == "." ? "." : Path.join(Path.split(value));
	}

	static function insideRoot(root:String, path:String):Bool {
		var relative = Path.relativeTo(path, root);
		var relativeType = Path.typeAtom(relative);
		return relative == "." || (relativeType == RELATIVE_PATH && !ElixirString.startsWith(relative, ".."));
	}

	static function discoverRootLayout(root:String):LiveReactRootLayout {
		var patterns = [
			Path.join([root, "lib", "*_web", "components", "layouts", "root.html.heex"]),
			Path.join([root, "lib", "*_web", "templates", "layout", "root.html.heex"]),
			Path.join([root, "lib", "*_web", "templates", "layout", "root.html.leex"])
		];
		var matches = Enum.uniq(Enum.flatMap(patterns, function(pattern:String):Array<String> return Path.wildcard(pattern)));
		if (matches.length == 1)
			return {path: matches[0], kind: HEEX_LAYOUT};
		if (matches.length > 1)
			return Kernel.raiseValue("multiple Phoenix root layouts found: "
				+ Enum.mapJoin(matches, ", ", function(path:String):String return Path.relativeTo(path, root))
				+ ". No writes occurred.");

		var haxeCandidates = Path.wildcard(Path.join([root, "src_haxe", "**", "Layouts.hx"]));
		var haxeMatches = Enum.filter(haxeCandidates, function(path:String):Bool {
			var source = File.readBang(path);
			return Regex.match(Regex.compileBang("(?m)^\\s*@:component\\b"), source)
				&& Regex.match(Regex.compileBang("\\bfunction\\s+root\\s*\\("), source)
				&& (ElixirString.contains(source, "/assets/app.js") || ElixirString.contains(source, "/assets/phoenix_app.js"));
		});
		if (haxeMatches.length == 1)
			return {path: haxeMatches[0], kind: HAXE_LAYOUT};
		if (haxeMatches.length == 0)
			return
				Kernel.raiseValue("could not find one canonical Phoenix root layout. No writes occurred. Expected a standard root.html.heex/root.html.leex or one Haxe-authored src_haxe/**/Layouts.hx with @:component root/1 and a canonical app script.");
		return Kernel.raiseValue("multiple Haxe-authored Phoenix root layouts found: "
			+ Enum.mapJoin(haxeMatches, ", ", function(path:String):String return Path.relativeTo(path, root))
			+ ". No writes occurred.");
	}

	static function detectClientMode(root:String):Atom {
		var structuralIndicators = [
			Path.joinTwo(root, "build-client.hxml"),
			Path.join([root, "src_haxe", "client", "Boot.hx"])
		];
		var canonicalGenes = Path.join([root, "haxe_libraries", "genes-ts.hxml"]);
		var compatibilityAlias = Path.join([root, "haxe_libraries", "genes.hxml"]);
		var hasGenesDescriptor = File.regular(canonicalGenes) || File.regular(compatibilityAlias);
		return Enum.all(structuralIndicators, function(path:String):Bool return File.regular(path))
			&& hasGenesDescriptor ? GENES : PLAIN_JS;
	}

	static function readRequiredSources(topology:LiveReactTopology):LiveReactSources {
		return {
			mixExs: File.readBang(Path.joinTwo(topology.root, "mix.exs")),
			configExs: File.readBang(Path.join([topology.root, "config", "config.exs"])),
			devExs: File.readBang(Path.join([topology.root, "config", "dev.exs"])),
			appJs: File.readBang(Path.join([topology.root, "assets", "js", "app.js"])),
			rootLayout: File.readBang(topology.rootLayout)
		};
	}

	static function existingRestores(manifest:Term):Term {
		if (manifest == null)
			return ElixirMap.new_();
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		return ElixirMap.fetchBangTerm(managed, "restores");
	}

	static function managedFilesFor(topology:LiveReactTopology):Array<String> {
		var files = [topology.viteConfig, topology.hooksFile, topology.registryFile];
		if (topology.reloadWrapper != null)
			files = Enum.concatTwo(files, [topology.reloadWrapper]);
		return Enum.sort(Enum.map(files, function(path:String):String return Path.relativeTo(path, topology.root)));
	}

	static function legacyManagedFilesFor(topology:LiveReactTopology):Array<String> {
		var files = [topology.viteConfig, topology.hooksFile];
		if (topology.reloadWrapper != null)
			files = Enum.concatTwo(files, [topology.reloadWrapper]);
		return Enum.sort(Enum.concatTwo(Enum.map(files, function(path:String):String return Path.relativeTo(path, topology.root)), [LEGACY_REGISTRY_FILE]));
	}

	static function renderManifest(data:LiveReactManifestData):String {
		var managed = jsonObject([
			{_0: "files", _1: data.managedFiles},
			{_0: "markers", _1: LiveReactSourcePatcher.managedMarkers(data.topology)},
			{_0: "packageKeys", _1: data.packageKeys},
			{_0: "dependencyOwned", _1: data.dependencyOwned},
			{_0: "lockOwned", _1: data.lockOwned},
			{_0: "restores", _1: data.restores}
		]);
		var manifest = jsonObject([
			{_0: "schema", _1: IntegrationCore.SCHEMA},
			{_0: "generatedBy", _1: IntegrationCore.GENERATED_BY},
			{_0: "assetMode", _1: "vite"},
			{_0: "appName", _1: data.topology.appName},
			{_0: "packageRoot", _1: data.topology.packageRootRelative},
			{_0: "clientMode", _1: IntegrationCore.clientModeLabel(data.topology.clientMode)},
			{_0: "mixDependency", _1: data.dependency.identity},
			{_0: "npmReference", _1: data.dependency.npmReference},
			{_0: "runtimePolicy", _1: IntegrationCore.runtimePolicy()},
			{_0: "components", _1: LiveReactRegistry.toManifestTerms(data.components)},
			{_0: "managed", _1: managed}
		]);
		var options:KeywordList<Term> = [{_0: PRETTY, _1: true}];
		return Enum.join([Jason.encodeStrictWithKeywordOptions(manifest, options), ""], "\n");
	}

	static function validateOwnedTopology(manifest:Term, topology:LiveReactTopology):Void {
		if (manifest == null)
			return;
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		var files:Array<String> = ElixirMap.fetchBangTerm(managed, "files");
		var markers:Array<Term> = ElixirMap.fetchBangTerm(managed, "markers");
		var sortedFiles = Enum.sort(files);
		var filesMatch = sortedFiles == managedFilesFor(topology) || sortedFiles == legacyManagedFilesFor(topology);
		if (!filesMatch
			|| markers != LiveReactSourcePatcher.managedMarkers(topology)
			|| ElixirMap.get(manifest, "runtimePolicy") != IntegrationCore.runtimePolicy())
			Kernel.raise(IntegrationCore.MANIFEST_FILENAME
				+
				" ownership or client-only policy does not match this integration version. No writes occurred. Upgrade the tool or restore the generated manifest.");
	}

	static function planLegacyRegistryMigration(plan:PatchPlan, root:String, manifest:Term, topology:LiveReactTopology):PatchPlan {
		if (manifest == null)
			return plan;
		var managed:Term = ElixirMap.fetchBangTerm(manifest, "managed");
		var files:Array<String> = ElixirMap.fetchBangTerm(managed, "files");
		var currentRegistry = Path.relativeTo(topology.registryFile, root);
		return Enum.member(files, LEGACY_REGISTRY_FILE)
			&& !Enum.member(files, currentRegistry) ? planGeneratedRemoval(plan, root, LEGACY_REGISTRY_FILE) : plan;
	}

	static function planManagedFile(plan:PatchPlan, path:String, desired:String):PatchPlan {
		return ProjectPatch.writeFileBang(plan, path, managedFileContent(path, desired));
	}

	static function managedFileContent(path:String, desired:String):String {
		var read = File.readResult(path);
		var readTag = tag(read);
		if (readTag == OK) {
			var managed = ProjectPatch.managedFileContent(Kernel.elemAs(read, 1), IntegrationCore.GENERATED_SIGNATURE, desired);
			var managedTag = tag(managed);
			if (managedTag == OK)
				return Kernel.elemAs(managed, 1);
			if (managedTag == UNOWNED)
				return Kernel.raiseValue("cannot write "
					+ path
					+
					": the generated path exists without the PhoenixHx LiveReact ownership signature. No writes occurred. Move the file or integrate it manually.");
			return Kernel.raiseValue("cannot write " + path + ": invalid generated ownership signature " + Kernel.inspect(Kernel.elem(managed, 1))
				+ ". No writes occurred.");
		}
		var reason = Kernel.elem(read, 1);
		if (reason != ENOENT)
			return Kernel.raiseValue("cannot read " + path + ": " + ErlangFile.formatError(reason));
		return desired;
	}

	static function planGeneratedRemoval(plan:PatchPlan, root:String, relative:String):PatchPlan {
		var path = Path.joinTwo(root, relative);
		var read = File.readResult(path);
		var readTag = tag(read);
		if (readTag == OK) {
			var status = ProjectPatch.signatureStatus(Kernel.elemAs(read, 1), IntegrationCore.GENERATED_SIGNATURE);
			var statusTag = tag(status);
			if (statusTag == OWNED)
				return ProjectPatch.deleteFileBang(plan, path);
			if (statusTag == UNOWNED)
				return Kernel.raiseValue("cannot remove "
					+ relative
					+ ": the generated ownership signature is missing. No writes occurred. Preserve the file and remove it manually after review.");
			return Kernel.raiseValue("cannot remove " + relative + ": duplicate ownership signature " + Kernel.inspect(Kernel.elem(status, 1))
				+ ". No writes occurred.");
		}
		var reason = Kernel.elem(read, 1);
		return reason == ENOENT ? plan : Kernel.raiseValue("cannot read " + path + ": " + ErlangFile.formatError(reason));
	}

	static function jsonObject(entries:Array<{_0:String, _1:Term}>):Term {
		return Enum.reduce(entries, ElixirMap.new_(), function(entry:{_0:String, _1:Term}, value:Term):Term {
			return ElixirMap.putTerm(value, entry._0, entry._1);
		});
	}

	static function normalizeOptions(opts:Null<KeywordList<Term>>):KeywordList<Term> {
		return opts == null ? [] : opts;
	}

	static function tag(value:Term):Atom {
		return Kernel.isTuple(value) ? Kernel.elemAs(value, 0) : value;
	}
}
