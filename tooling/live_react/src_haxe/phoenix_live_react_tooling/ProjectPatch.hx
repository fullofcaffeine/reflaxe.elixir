package phoenix_live_react_tooling;

import elixir.Base;
import elixir.Bitwise;
import elixir.Crypto;
import elixir.ElixirException;
import elixir.ElixirInteger;
import elixir.ElixirMap;
import elixir.ElixirString;
import elixir.Enum;
import elixir.ErlangBinary;
import elixir.File;
import elixir.FileStat;
import elixir.IO;
import elixir.Jason;
import elixir.Keyword;
import elixir.Kernel;
import elixir.MapSet;
import elixir.Path;
import elixir.Regex;
import elixir.System;
import elixir.types.Atom;
import elixir.types.KeywordList;
import elixir.types.NativeException;
import elixir.types.Term;
import phoenix_live_react_tooling.PatchTypes.PatchFileState;
import phoenix_live_react_tooling.PatchTypes.PatchTransaction;
import phoenix_live_react_tooling.PatchTypes.StagedPatchOperation;

private typedef MarkerSpan = {
	final first:Int;
	final last:Int;
	final token:String;
}

/**
 * Haxe-authored ownership-safe project mutation and recovery protocol.
 */
@:keep
@:native("HaxeProjectPatch")
class ProjectPatch {
	static inline final TRANSACTION_DIRECTORY = ".reflaxe-elixir-project-patch";
	static inline final OWNER_FILENAME = "owner";
	static inline final JOURNAL_FILENAME = "journal.json";
	static inline final OWNER_MARKER = "reflaxe.elixir project patch transaction v1\n";
	static inline final PROTOCOL = "reflaxe-elixir/project-patch";
	static inline final VERSION = 1;
	static inline final DEFAULT_MODE = 420;
	static inline final PERMISSION_MASK = 4095;
	static inline final OK:Atom = "ok";
	static inline final ERROR:Atom = "error";
	static inline final KEEP:Atom = "keep";
	static inline final DELETE:Atom = "delete";
	static inline final WRITE:Atom = "write";
	static inline final REGULAR:Atom = "regular";
	static inline final DIRECTORY:Atom = "directory";
	static inline final CLEAN:Atom = "clean";
	static inline final PENDING:Atom = "pending";
	static inline final ROLLBACK:Atom = "rollback";
	static inline final COMMIT_CLEANUP:Atom = "commit_cleanup";
	static inline final DISCARD_INCOMPLETE:Atom = "discard_incomplete";
	static inline final REMOVED:Atom = "removed";
	static inline final WROTE:Atom = "wrote";
	static inline final PATCHED:Atom = "patched";
	static inline final ENOENT:Atom = "enoent";
	static inline final EEXIST:Atom = "eexist";
	static inline final ENOTEMPTY:Atom = "enotempty";
	static inline final ABSOLUTE:Atom = "absolute";
	static inline final POSITIVE:Atom = "positive";
	static inline final MONOTONIC:Atom = "monotonic";
	static inline final SHA256:Atom = "sha256";
	static inline final LOWER:Atom = "lower";
	static inline final CASE_KEY:Atom = "case";
	static inline final EXCLUSIVE:Atom = "exclusive";
	static inline final BINARY:Atom = "binary";
	static inline final ACTION:Atom = "action";
	static inline final PATH_KEY:Atom = "path";
	static inline final RELATIVE:Atom = "relative";
	static inline final MANIFEST_QUESTION:Atom = "manifest?";
	static inline final BEFORE_PUBLISH:Atom = "before_publish";
	static inline final AFTER_PUBLISH:Atom = "after_publish";
	static inline final MISSING:Atom = "missing";
	static inline final OWNED:Atom = "owned";
	static inline final UNOWNED:Atom = "unowned";
	static inline final EQUAL:Atom = "equal";
	static inline final CONFLICT:Atom = "conflict";
	static inline final INVALID_MARKER_TOKENS:Atom = "invalid_marker_tokens";
	static inline final INVERTED_MARKER_PAIR:Atom = "inverted_marker_pair";
	static inline final MARKER_COUNT:Atom = "marker_count";
	static inline final OVERLAPPING_MARKER_PAIRS:Atom = "overlapping_marker_pairs";
	static inline final DUPLICATE_SIGNATURE:Atom = "duplicate_signature";

	/**
	 * Create a validated immutable publication plan.
	 *
	 * Recovery runs before discovery by default so no new plan can be built on a
	 * mixed transaction state left by an interrupted process.
	 */
	@:native("new!")
	public static function newBang(root:String, opts:Null<KeywordList<Term>> = null):PatchPlan {
		var options = normalizeOptions(opts);
		var expanded = Path.expand(root);
		if (Keyword.get(options, "recover", true))
			recoverBang(expanded);
		requireDirectoryBang(expanded, "project patch root");
		return new PatchPlan(expanded);
	}

	@:native("update_file!")
	public static function updateFileBang(plan:PatchPlan, path:String, fun:PatchFileState->Term, opts:Null<KeywordList<Term>> = null):PatchPlan {
		var options = normalizeOptions(opts);
		var normalized = normalizeTargetBang(plan.root, path);
		var absolute:String = Kernel.elemAs(normalized, 0);
		var relative:String = Kernel.elemAs(normalized, 1);
		if (MapSet.member(plan.seenPaths, absolute))
			return Kernel.raiseValue("project patch plan contains more than one operation for " + absolute);

		var before = snapshotBang(plan.root, absolute);
		if (Keyword.get(options, "required", false) && before.state == MISSING) {
			var missingMessage = Keyword.get(options, "missing_message", "expected file at " + absolute);
			return Kernel.raiseValue(missingMessage);
		}

		var instruction = fun(before);
		var seenPaths = MapSet.put(plan.seenPaths, absolute);
		var normalizedInstruction = normalizeInstructionBang(instruction, before, absolute);
		plan.seenPaths = seenPaths;
		if (sameTerm(normalizedInstruction, KEEP))
			return plan;

		var kind:Atom = Kernel.elemAs(normalizedInstruction, 0);
		var afterState:PatchFileState = Kernel.elemAs(normalizedInstruction, 1);
		var action:Atom = Kernel.elemAs(normalizedInstruction, 2);
		var operation = new PatchOperation(kind, absolute, relative, before, afterState, action, Keyword.get(options, "manifest", false));
		plan.operations = Enum.concatTwo([operation], plan.operations);
		return plan;
	}

	@:native("ensure_file!")
	public static function ensureFileBang(plan:PatchPlan, path:String, initialContent:String, patchFun:String->String,
			opts:Null<KeywordList<Term>> = null):PatchPlan {
		return updateFileBang(plan, path, function(state:PatchFileState):Term {
			return state.state == MISSING ? writeInstruction(initialContent) : writeInstruction(patchFun(state.content));
		}, opts);
	}

	@:native("patch_file!")
	public static function patchFileBang(plan:PatchPlan, path:String, patchFun:String->String, opts:Null<KeywordList<Term>> = null):PatchPlan {
		var options = Keyword.put(normalizeOptions(opts), "required", true);
		return updateFileBang(plan, path, function(state:PatchFileState):Term return writeInstruction(patchFun(state.content)), options);
	}

	@:native("write_file!")
	public static function writeFileBang(plan:PatchPlan, path:String, content:String, opts:Null<KeywordList<Term>> = null):PatchPlan {
		return updateFileBang(plan, path, function(_state:PatchFileState):Term return writeInstruction(content), opts);
	}

	@:native("delete_file!")
	public static function deleteFileBang(plan:PatchPlan, path:String, opts:Null<KeywordList<Term>> = null):PatchPlan {
		return updateFileBang(plan, path, function(_state:PatchFileState):Term return DELETE, opts);
	}

	public static function changes(plan:PatchPlan):Array<Term> {
		return Enum.map(Enum.reverse(plan.operations), function(operation:PatchOperation):Term {
			var change = ElixirMap.new_();
			change = ElixirMap.putTerm(change, ACTION, operation.action);
			change = ElixirMap.putTerm(change, PATH_KEY, operation.path);
			change = ElixirMap.putTerm(change, RELATIVE, operation.relative);
			return ElixirMap.putTerm(change, MANIFEST_QUESTION, operation.manifest);
		});
	}

	@:native("publish!")
	public static function publishBang(plan:PatchPlan, opts:Null<KeywordList<Term>> = null):Atom {
		var operations = orderedOperations(plan);
		if (operations.length == 0)
			return OK;
		validatePlanBang(plan.root, operations);
		var transaction = prepareTransactionBang(plan.root, operations);
		var faultInjector:(Term,
			PatchOperation) -> Term = Keyword.get(normalizeOptions(opts), "fault_injector", function(_stage:Term, _operation:PatchOperation):Term return OK);
		var published = publishOperations(transaction, faultInjector);
		if (sameTerm(published, OK)) {
			finishCommittedTransactionBang(transaction);
			return OK;
		}

		var publicationError:Term = Kernel.elemAs(published, 1);
		var rollback = rollbackTransaction(transaction);
		if (sameTerm(rollback, OK))
			return Kernel.raiseValue("project patch publication failed and was rolled back: " + ElixirException.message(publicationError));
		var rollbackMessage:String = Kernel.elemAs(rollback, 1);
		return Kernel.raiseValue("project patch publication failed: " + ElixirException.message(publicationError)
			+ "; automatic rollback could not complete: " + rollbackMessage + ". Transaction data was retained at " + transaction.directory + ".");
	}

	@:native("recovery_status!")
	public static function recoveryStatusBang(root:String):Term {
		var action = recoveryActionBang(Path.expand(root));
		if (sameTerm(action, CLEAN))
			return CLEAN;
		var tag = tupleTag(action);
		return {_0: PENDING, _1: tag == COMMIT_CLEANUP ? COMMIT_CLEANUP : ROLLBACK};
	}

	@:native("recover!")
	public static function recoverBang(root:String):Atom {
		var action = recoveryActionBang(Path.expand(root));
		if (sameTerm(action, CLEAN))
			return OK;
		var tag = tupleTag(action);
		if (tag == DISCARD_INCOMPLETE) {
			removeIncompleteTransactionBang(Kernel.elemAs(action, 1));
			return OK;
		}
		var transaction:PatchTransaction = Kernel.elemAs(action, 1);
		if (tag == COMMIT_CLEANUP) {
			finishCommittedTransactionBang(transaction);
			return OK;
		}
		var rollback = rollbackTransaction(transaction);
		if (sameTerm(rollback, OK))
			return OK;
		return Kernel.raiseValue(Kernel.elemAs(rollback, 1));
	}

	@:native("replace_marker_block_lines")
	public static function replaceMarkerBlockLines(content:String, beginToken:String, endToken:String, desiredLines:Array<String>):Term {
		var span = markerSpan(content, beginToken, endToken);
		if (sameTerm(span, MISSING))
			return MISSING;
		if (hasTag(span, ERROR))
			return error(Kernel.elemAs(span, 1));

		var lines:Array<String> = Kernel.elemAs(span, 1);
		var beginIndex:Int = Kernel.elemAs(span, 2);
		var endIndex:Int = Kernel.elemAs(span, 3);
		var beginLine = Enum.at(lines, beginIndex, "");
		var endLine = Enum.at(lines, endIndex, "");
		var indent = leadingIndent(beginLine);
		var indented = Enum.map(desiredLines, function(line:String):String return indent + line);
		var replacement = Enum.concatTwo(Enum.concatTwo([beginLine], indented), [endLine]);
		return ok(replaceLineSpan(lines, beginIndex, endIndex, replacement));
	}

	@:native("replace_marker_block_lines_with")
	public static function replaceMarkerBlockLinesWith(content:String, beginToken:String, endToken:String, fun:Array<String>->Array<String>):Term {
		var span = markerSpan(content, beginToken, endToken);
		if (sameTerm(span, MISSING))
			return MISSING;
		if (hasTag(span, ERROR))
			return error(Kernel.elemAs(span, 1));

		var lines:Array<String> = Kernel.elemAs(span, 1);
		var beginIndex:Int = Kernel.elemAs(span, 2);
		var endIndex:Int = Kernel.elemAs(span, 3);
		var beginLine = Enum.at(lines, beginIndex, "");
		var endLine = Enum.at(lines, endIndex, "");
		var indent = leadingIndent(beginLine);
		var existingInner = Enum.take(Enum.drop(lines, beginIndex + 1), endIndex - beginIndex - 1);
		var desiredInner = Enum.map(fun(existingInner), function(line:String):String return indent + ElixirString.trimLeading(line));
		var replacement = Enum.concatTwo(Enum.concatTwo([beginLine], desiredInner), [endLine]);
		return ok(replaceLineSpan(lines, beginIndex, endIndex, replacement));
	}

	@:native("remove_marker_block_lines")
	public static function removeMarkerBlockLines(content:String, beginToken:String, endToken:String):Term {
		var span = markerSpan(content, beginToken, endToken);
		if (sameTerm(span, MISSING))
			return MISSING;
		if (hasTag(span, ERROR))
			return error(Kernel.elemAs(span, 1));

		var lines:Array<String> = Kernel.elemAs(span, 1);
		var beginIndex:Int = Kernel.elemAs(span, 2);
		var endIndex:Int = Kernel.elemAs(span, 3);
		var retained = Enum.flatMap(Enum.withIndex(lines), function(entry:Term):Array<String> {
			var line:String = Kernel.elemAs(entry, 0);
			var index:Int = Kernel.elemAs(entry, 1);
			return index >= beginIndex && index <= endIndex ? [] : [line];
		});
		return ok(Enum.join(retained, "\n"));
	}

	@:native("validate_marker_pairs")
	public static function validateMarkerPairs(content:String, markerPairs:Array<{_0:String, _1:String}>):Term {
		var collected = collectMarkerSpans(content, markerPairs, 0, []);
		if (hasTag(collected, ERROR))
			return collected;
		var spans:Array<MarkerSpan> = Kernel.elemAs(collected, 1);
		return validateOrderedSpans(Enum.sortBy(spans, function(span:MarkerSpan):Int return span.first), 1);
	}

	@:native("marker_block_lines")
	public static function markerBlockLines(beginToken:String, endToken:String, desiredLines:Array<String>, opts:Null<KeywordList<Term>> = null):Array<String> {
		var options:KeywordList<Term> = opts == null ? [] : opts;
		var indent:String = Keyword.get(options, "indent", "");
		var commentPrefix:String = Keyword.get(options, "comment_prefix", "#");
		var body = Enum.map(desiredLines, function(line:String):String return indent + line);
		return Enum.concatTwo(Enum.concatTwo([indent + commentPrefix + " " + beginToken], body), [indent + commentPrefix + " " + endToken]);
	}

	@:native("signature_status")
	public static function signatureStatus(content:String, signature:String):Term {
		var count = ErlangBinary.matches(content, signature).length;
		if (count == 0)
			return UNOWNED;
		if (count == 1)
			return OWNED;
		return error({_0: DUPLICATE_SIGNATURE, _1: signature, _2: count});
	}

	@:native("managed_file_content")
	public static function managedFileContent(existing:String, signature:String, desired:String):Term {
		var status = signatureStatus(existing, signature);
		if (sameTerm(status, OWNED))
			return ok(desired);
		return status;
	}

	@:native("package_key_status")
	public static function packageKeyStatus(content:String, path:Array<String>, expected:Term):Term {
		var decoded = decodeJsonObject(content);
		if (hasTag(decoded, ERROR))
			return decoded;
		var pathValidation = validateKeyPath(path);
		if (!sameTerm(pathValidation, OK))
			return pathValidation;

		var json:Term = Kernel.elemAs(decoded, 1);
		var fetched = fetchJsonPath(json, path, []);
		if (sameTerm(fetched, MISSING) || hasTag(fetched, ERROR))
			return sameTerm(fetched, MISSING) ? ok(MISSING) : fetched;
		var actual:Term = Kernel.elemAs(fetched, 1);
		return sameTerm(actual, expected) ? ok(EQUAL) : ok({_0: CONFLICT, _1: actual});
	}

	@:native("validate_package_key_change")
	public static function validatePackageKeyChange(before:String, afterContent:String, path:Array<String>, expected:Term):Term {
		var beforeDecoded = decodeJsonObject(before);
		if (hasTag(beforeDecoded, ERROR))
			return beforeDecoded;
		var afterDecoded = decodeJsonObject(afterContent);
		if (hasTag(afterDecoded, ERROR))
			return afterDecoded;
		var pathValidation = validateKeyPath(path);
		if (!sameTerm(pathValidation, OK))
			return pathValidation;

		var beforeJson:Term = Kernel.elemAs(beforeDecoded, 1);
		var afterJson:Term = Kernel.elemAs(afterDecoded, 1);
		var fetched = fetchJsonPath(afterJson, path, []);
		if (sameTerm(fetched, MISSING))
			return error("updated package JSON is missing " + Enum.join(path, "."));
		if (hasTag(fetched, ERROR))
			return fetched;

		var actual:Term = Kernel.elemAs(fetched, 1);
		if (!sameTerm(actual, expected))
			return error("updated package JSON has conflicting value " + Kernel.inspect(actual));
		if (!sameTerm(stripJsonPath(beforeJson, path), stripJsonPath(afterJson, path)))
			return error("package JSON update changed keys outside " + Enum.join(path, "."));
		return OK;
	}

	static function normalizeOptions(opts:Null<KeywordList<Term>>):KeywordList<Term> {
		return opts == null ? [] : opts;
	}

	static function writeInstruction(content:String):Term {
		return {_0: WRITE, _1: content};
	}

	static function normalizeInstructionBang(instruction:Term, before:PatchFileState, path:String):Term {
		if (sameTerm(instruction, KEEP))
			return KEEP;
		if (sameTerm(instruction, DELETE))
			return before.state == MISSING ? KEEP : {_0: DELETE, _1: missingState(), _2: REMOVED};
		if (hasTag(instruction, WRITE)) {
			var content:Term = Kernel.elemAs(instruction, 1);
			if (!Kernel.isBinary(content))
				return Kernel.raiseValue("invalid project patch instruction for " + path + ": " + Kernel.inspect(instruction));
			var mode = before.state == REGULAR ? before.mode : DEFAULT_MODE;
			var afterState = regularState(Kernel.elemAs(instruction, 1), mode);
			if (sameState(before, afterState))
				return KEEP;
			return {_0: WRITE, _1: afterState, _2: before.state == MISSING ? WROTE : PATCHED};
		}
		return Kernel.raiseValue("invalid project patch instruction for " + path + ": " + Kernel.inspect(instruction));
	}

	static function orderedOperations(plan:PatchPlan):Array<PatchOperation> {
		var operations = Enum.reverse(plan.operations);
		var split = Enum.splitWith(operations, function(operation:PatchOperation):Bool return !operation.manifest);
		var ordinary:Array<PatchOperation> = Kernel.elemAs(split, 0);
		var manifests:Array<PatchOperation> = Kernel.elemAs(split, 1);
		if (manifests.length > 1)
			return Kernel.raiseValue("project patch plan may contain at most one manifest operation");
		return Enum.concatTwo(ordinary, manifests);
	}

	static function validatePlanBang(root:String, operations:Array<PatchOperation>):Atom {
		Enum.each(operations, function(operation:PatchOperation):Void {
			var current = snapshotBang(root, operation.path);
			if (!sameState(current, operation.before))
				Kernel.raise("project patch input changed after discovery: " + operation.path);
		});
		return OK;
	}

	/**
	 * Stage a recoverable transaction before the first target replacement.
	 *
	 * Each replacement is atomic per file. The journal plus content-addressed
	 * backups provides deterministic recovery of a mixed state; it does not
	 * claim a filesystem-wide power-loss-safe transaction.
	 */
	static function prepareTransactionBang(root:String, operations:Array<PatchOperation>):PatchTransaction {
		var directory = Path.joinTwo(root, TRANSACTION_DIRECTORY);
		var status = File.lstatResult(directory);
		if (!hasTag(status, ERROR) || !sameTerm(Kernel.elemAs(status, 1), ENOENT)) {
			if (hasTag(status, OK))
				return Kernel.raiseValue("project patch transaction already exists: " + directory);
			return Kernel.raiseValue("cannot inspect project patch transaction path: " + Kernel.inspect(Kernel.elemAs(status, 1)));
		}

		var id = ElixirInteger.toString(System.uniqueIntegerWithAtomOptions([POSITIVE, MONOTONIC]));
		var createdDirs = missingParentDirectories(root, operations);
		var stagedOperations = buildStagedOperations(root, directory, id, operations);
		validateStagedPathsBang(stagedOperations);

		File.mkdirBang(directory);
		File.writeBangWithAtomModes(Path.joinTwo(directory, OWNER_FILENAME), OWNER_MARKER, [WRITE, EXCLUSIVE]);
		File.mkdirBang(Path.joinTwo(directory, "backups"));

		var transaction:PatchTransaction = {
			root: root,
			directory: directory,
			id: id,
			operations: stagedOperations,
			createdDirs: createdDirs
		};
		writeJournalBang(transaction);

		try {
			Enum.each(createdDirs, function(path:String):Void File.mkdirBang(path));
			Enum.each(stagedOperations, function(staged:StagedPatchOperation):Void stageOperationBang(staged));
			return transaction;
		} catch (error:NativeException) {
			var rollback = rollbackTransaction(transaction);
			if (sameTerm(rollback, OK))
				return Kernel.raiseNative(error);
			return Kernel.raiseValue(ElixirException.message(error) + "; staging cleanup failed: " + Kernel.elemAs(rollback, 1));
		}
	}

	static function buildStagedOperations(root:String, directory:String, id:String, operations:Array<PatchOperation>):Array<StagedPatchOperation> {
		return Enum.map(Enum.withIndex(operations), function(entry:Term):StagedPatchOperation {
			var operation:PatchOperation = Kernel.elemAs(entry, 0);
			var index:Int = Kernel.elemAs(entry, 1);
			var basename = Path.basename(operation.path);
			var newPath:Null<String> = operation.kind == WRITE ? Path.joinTwo(Path.dirname(operation.path),
				"." + basename + ".reflaxe-patch-" + id + "-" + ElixirInteger.toString(index) + ".new") : null;
			var backupPath:Null<String> = operation.before.state == REGULAR ? Path.join([directory, "backups", ElixirInteger.toString(index)]) : null;
			return {
				operation: operation,
				newPath: newPath,
				newRelative: relativeOrNil(root, newPath),
				backupPath: backupPath,
				backupRelative: relativeOrNil(root, backupPath)
			};
		});
	}

	static function validateStagedPathsBang(stagedOperations:Array<StagedPatchOperation>):Atom {
		var targets = Enum.map(stagedOperations, function(staged:StagedPatchOperation):String return staged.operation.path);
		var temporaryPaths = Enum.flatMap(stagedOperations, function(staged:StagedPatchOperation):Array<String> return presentPath(staged.newPath));
		var backupPaths = Enum.flatMap(stagedOperations, function(staged:StagedPatchOperation):Array<String> return presentPath(staged.backupPath));
		assertUniquePathsBang(targets, "target");
		assertUniquePathsBang(temporaryPaths, "temporary");
		assertUniquePathsBang(backupPaths, "backup");
		var collisions = MapSet.intersection(MapSet.fromValues(targets), MapSet.fromValues(Enum.concatTwo(temporaryPaths, backupPaths)));
		if (MapSet.size(collisions) > 0)
			return Kernel.raiseValue("project patch staging paths collide with targets: " + Kernel.inspect(MapSet.toList(collisions)));
		return OK;
	}

	static function missingParentDirectories(root:String, operations:Array<PatchOperation>):Array<String> {
		var all = Enum.flatMap(Enum.filter(operations, function(operation:PatchOperation):Bool return operation.kind == WRITE),
			function(operation:PatchOperation):Array<String> return missingDirectories(root, Path.dirname(operation.path)));
		return Enum.sortBy(Enum.uniq(all), function(path:String):Int return Path.split(path).length);
	}

	static function missingDirectories(root:String, directory:String):Array<String> {
		return collectMissingDirectories(Path.split(Path.relativeTo(directory, root)), 0, root, []);
	}

	static function collectMissingDirectories(parts:Array<String>, index:Int, parent:String, missing:Array<String>):Array<String> {
		if (index >= parts.length)
			return missing;
		var path = Path.joinTwo(parent, parts[index]);
		var status = File.lstatResult(path);
		if (hasTag(status, OK)) {
			var stat:FileStat = Kernel.elemAs(status, 1);
			if (stat.type != DIRECTORY)
				return Kernel.raiseValue("project patch parent is not a directory (" + Kernel.toString(stat.type) + "): " + path);
			return collectMissingDirectories(parts, index + 1, path, missing);
		}
		var reason:Term = Kernel.elemAs(status, 1);
		if (sameTerm(reason, ENOENT))
			return collectMissingDirectories(parts, index + 1, path, Enum.concatTwo(missing, [path]));
		return Kernel.raiseValue("cannot inspect project patch parent " + path + ": " + Kernel.inspect(reason));
	}

	static function stageOperationBang(staged:StagedPatchOperation):Void {
		var operation = staged.operation;
		if (staged.backupPath != null)
			writeExclusiveBang(staged.backupPath, operation.before.content, operation.before.mode);
		if (staged.newPath != null)
			writeExclusiveBang(staged.newPath, operation.after.content, operation.after.mode);
	}

	static function publishOperations(transaction:PatchTransaction, faultInjector:(Term, PatchOperation) -> Term):Term {
		return publishOperationsAt(transaction, faultInjector, 0);
	}

	static function publishOperationsAt(transaction:PatchTransaction, faultInjector:(Term, PatchOperation) -> Term, index:Int):Term {
		if (index >= transaction.operations.length)
			return OK;
		var staged = transaction.operations[index];
		var result = safely(function():Void {
			invokeFaultBang(faultInjector, {_0: BEFORE_PUBLISH, _1: index}, staged.operation);
			verifyTargetBang(transaction.root, staged.operation, "before");
			publishOneBang(staged);
			invokeFaultBang(faultInjector, {_0: AFTER_PUBLISH, _1: index}, staged.operation);
		});
		return sameTerm(result, OK) ? publishOperationsAt(transaction, faultInjector, index + 1) : result;
	}

	static function publishOneBang(staged:StagedPatchOperation):Void {
		if (staged.operation.kind == WRITE)
			File.renameBang(staged.newPath, staged.operation.path);
		else
			File.rmBang(staged.operation.path);
	}

	static function finishCommittedTransactionBang(transaction:PatchTransaction):Atom {
		Enum.each(transaction.operations, function(staged:StagedPatchOperation):Void verifyTargetBang(transaction.root, staged.operation, "after"));
		return cleanupTransactionBang(transaction);
	}

	static function rollbackTransaction(transaction:PatchTransaction):Term {
		try {
			validateRecoverableTargets(transaction);
			restoreOperations(transaction);
			cleanupTransactionBang(transaction);
			pruneCreatedDirectories(transaction.createdDirs);
			return OK;
		} catch (exception:NativeException) {
			return error(ElixirException.message(exception));
		}
	}

	static function validateRecoverableTargets(transaction:PatchTransaction):Atom {
		Enum.each(transaction.operations, function(staged:StagedPatchOperation):Void {
			var current = snapshotBang(transaction.root, staged.operation.path);
			if (!sameState(current, staged.operation.before) && !sameState(current, staged.operation.after))
				Kernel.raise("project patch target has unexpected bytes during recovery: " + staged.operation.path);
			if (sameState(current, staged.operation.after) && staged.operation.before.state == REGULAR)
				verifyBackupBang(transaction.root, staged);
		});
		return OK;
	}

	static function restoreOperations(transaction:PatchTransaction):Atom {
		Enum.each(Enum.reverse(transaction.operations), function(staged:StagedPatchOperation):Void {
			var operation = staged.operation;
			var current = snapshotBang(transaction.root, operation.path);
			if (sameState(current, operation.after)) {
				if (operation.before.state == REGULAR) {
					verifyBackupBang(transaction.root, staged);
					File.renameBang(staged.backupPath, operation.path);
				} else {
					File.rmBang(operation.path);
				}
			}
		});
		return OK;
	}

	static function verifyBackupBang(root:String, staged:StagedPatchOperation):Atom {
		var backup = snapshotBang(root, staged.backupPath);
		if (!sameState(backup, staged.operation.before))
			return Kernel.raiseValue("project patch backup failed integrity validation: " + staged.backupPath);
		return OK;
	}

	static function cleanupTransactionBang(transaction:PatchTransaction):Atom {
		Enum.each(transaction.operations,
			function(staged:StagedPatchOperation):Void removeOwnedTempBang(transaction.root, staged.newPath, staged.operation.after));
		requireOwnedTransactionDirectoryBang(transaction.directory);
		var result = File.rmRecursiveResult(transaction.directory);
		if (hasTag(result, OK))
			return OK;
		var reason:Term = Kernel.elemAs(result, 1);
		var path:String = Kernel.elemAs(result, 2);
		return Kernel.raiseValue("cannot remove project patch transaction data " + path + ": " + Kernel.inspect(reason));
	}

	static function removeOwnedTempBang(root:String, path:Null<String>, expected:PatchFileState):Atom {
		if (path == null)
			return OK;
		validateOwnedTempBang(root, path, expected);
		var result = File.rmResult(path);
		if (sameTerm(result, OK))
			return OK;
		var reason:Term = Kernel.elemAs(result, 1);
		if (sameTerm(reason, ENOENT))
			return OK;
		return Kernel.raiseValue("cannot remove project patch temporary file: " + Kernel.inspect(reason));
	}

	static function pruneCreatedDirectories(directories:Array<String>):Atom {
		Enum.each(Enum.reverse(directories), function(directory:String):Void {
			var result = File.rmdirResult(directory);
			if (!sameTerm(result, OK)) {
				var reason:Term = Kernel.elemAs(result, 1);
				if (!sameTerm(reason, ENOENT) && !sameTerm(reason, EEXIST) && !sameTerm(reason, ENOTEMPTY))
					Kernel.raise("cannot remove project patch directory " + directory + ": " + Kernel.inspect(reason));
			}
		});
		return OK;
	}

	static function recoveryActionBang(root:String):Term {
		var transactionDirectory = Path.joinTwo(root, TRANSACTION_DIRECTORY);
		var result = File.lstatResult(transactionDirectory);
		if (hasTag(result, ERROR)) {
			var reason:Term = Kernel.elemAs(result, 1);
			return sameTerm(reason,
				ENOENT) ? CLEAN : Kernel.raiseValue("cannot inspect project patch transaction path " + transactionDirectory + ": " + Kernel.inspect(reason));
		}
		var stat:FileStat = Kernel.elemAs(result, 1);
		if (stat.type != DIRECTORY)
			return Kernel.raiseValue("project patch transaction path is not a directory (" + Kernel.toString(stat.type) + "): " + transactionDirectory);
		return recoveryActionFromDirectoryBang(root, transactionDirectory);
	}

	static function recoveryActionFromDirectoryBang(root:String, directory:String):Term {
		requireOwnedTransactionDirectoryBang(directory);
		var journalPath = Path.joinTwo(directory, JOURNAL_FILENAME);
		var result = File.lstatResult(journalPath);
		if (hasTag(result, ERROR)) {
			var reason:Term = Kernel.elemAs(result, 1);
			return sameTerm(reason,
				ENOENT) ? {_0: DISCARD_INCOMPLETE, _1: directory} : Kernel.raiseValue("cannot inspect project patch journal " + journalPath + ": "
				+ Kernel.inspect(reason));
		}
		var stat:FileStat = Kernel.elemAs(result, 1);
		if (stat.type != REGULAR)
			return Kernel.raiseValue("project patch journal is not a regular file (" + Kernel.toString(stat.type) + "): " + journalPath);

		var transaction = readJournalBang(root, directory, journalPath);
		var complete = Enum.all(transaction.operations,
			function(staged:StagedPatchOperation):Bool return sameState(snapshotBang(root, staged.operation.path), staged.operation.after));
		if (complete) {
			validateCommitCleanupBang(transaction);
			return {_0: COMMIT_CLEANUP, _1: transaction};
		}
		validateRecoverableTargets(transaction);
		return {_0: ROLLBACK, _1: transaction};
	}

	static function validateCommitCleanupBang(transaction:PatchTransaction):Atom {
		Enum.each(transaction.operations, function(staged:StagedPatchOperation):Void {
			verifyTargetBang(transaction.root, staged.operation, "after");
			validateOwnedTempBang(transaction.root, staged.newPath, staged.operation.after);
		});
		return OK;
	}

	static function validateOwnedTempBang(root:String, path:Null<String>, expected:PatchFileState):Atom {
		if (path == null)
			return OK;
		var current = snapshotBang(root, path);
		if (current.state != MISSING && !sameState(current, expected))
			return Kernel.raiseValue("project patch temporary file failed integrity validation: " + path);
		return OK;
	}

	static function removeIncompleteTransactionBang(directory:String):Atom {
		requireOwnedTransactionDirectoryBang(directory);
		var result = File.rmRecursiveResult(directory);
		if (hasTag(result, OK))
			return OK;
		var reason:Term = Kernel.elemAs(result, 1);
		var path:String = Kernel.elemAs(result, 2);
		return Kernel.raiseValue("cannot remove incomplete transaction " + path + ": " + Kernel.inspect(reason));
	}

	static function writeJournalBang(transaction:PatchTransaction):Atom {
		var journal = jsonObject([
			{_0: "protocol", _1: PROTOCOL},
			{_0: "version", _1: VERSION},
			{_0: "id", _1: transaction.id},
			{_0: "createdDirectories", _1: Enum.map(transaction.createdDirs, function(path:String):String return Path.relativeTo(path, transaction.root))},
			{_0: "operations", _1: Enum.map(transaction.operations, operationToJson)}
		]);
		var content = Jason.encodeStrictWithKeywordOptions(journal, [{_0: "pretty", _1: true}]);
		atomicWriteBang(Path.joinTwo(transaction.directory, JOURNAL_FILENAME), content + "\n");
		return OK;
	}

	static function operationToJson(staged:StagedPatchOperation):Term {
		return jsonObject([
			{_0: "kind", _1: Kernel.toString(staged.operation.kind)},
			{_0: "path", _1: staged.operation.relative},
			{_0: "before", _1: stateToJson(staged.operation.before)},
			{_0: "after", _1: stateToJson(staged.operation.after)},
			{_0: "newPath", _1: staged.newRelative},
			{_0: "backupPath", _1: staged.backupRelative},
			{_0: "manifest", _1: staged.operation.manifest}
		]);
	}

	static function stateToJson(state:PatchFileState):Term {
		if (state.state == MISSING)
			return jsonObject([{_0: "state", _1: "missing"}]);
		return jsonObject([
			{_0: "state", _1: "regular"},
			{_0: "sha256", _1: state.sha256},
			{_0: "mode", _1: state.mode}
		]);
	}

	static function readJournalBang(root:String, directory:String, path:String):PatchTransaction {
		var decoded = Jason.decodeResult(File.readBang(path));
		if (!hasTag(decoded, OK))
			return Kernel.raiseValue("invalid project patch transaction journal: " + path);
		var json:Term = Kernel.elemAs(decoded, 1);
		if (!Kernel.isMap(json))
			return Kernel.raiseValue("invalid project patch transaction journal: " + path);

		var protocol = ElixirMap.getTyped(json, "protocol");
		var version = ElixirMap.getTyped(json, "version");
		var id:Term = ElixirMap.getTyped(json, "id");
		var created:Term = ElixirMap.getTyped(json, "createdDirectories");
		var operationValues:Term = ElixirMap.getTyped(json, "operations");
		if (!sameTerm(protocol, PROTOCOL) || !sameTerm(version, VERSION) || !validTransactionId(id) || !Kernel.isList(created)
			|| !Kernel.isList(operationValues))
			return Kernel.raiseValue("invalid project patch transaction journal: " + path);

		var operationTerms:Array<Term> = Kernel.elemAs({_0: OK, _1: operationValues}, 1);
		var operations = Enum.map(Enum.withIndex(operationTerms), function(entry:Term):StagedPatchOperation {
			return operationFromJsonBang(root, directory, Kernel.elemAs(idValue(id), 0), Kernel.elemAs(entry, 0), Kernel.elemAs(entry, 1));
		});
		var createdValues:Array<Term> = Kernel.elemAs({_0: OK, _1: created}, 1);
		var transaction:PatchTransaction = {
			root: root,
			directory: directory,
			id: idValue(id)._0,
			createdDirs: Enum.map(createdValues,
				function(relative:Term):String return pathFromRelativeBang(root,
					requireBinary(relative, "invalid project patch transaction journal: " + path))),
			operations: operations
		};
		validateLoadedTransactionBang(transaction);
		return transaction;
	}

	static function operationFromJsonBang(root:String, directory:String, id:String, json:Term, index:Int):StagedPatchOperation {
		if (!Kernel.isMap(json))
			return Kernel.raiseValue("invalid project patch operation: " + Kernel.inspect(json));
		var kindValue:Term = ElixirMap.getTyped(json, "kind");
		var kind:Atom = sameTerm(kindValue, "write") ? WRITE : (sameTerm(kindValue, "delete") ? DELETE : null);
		if (kind == null)
			return Kernel.raiseValue("invalid project patch operation kind: " + Kernel.inspect(kindValue));

		var relative = requireBinary(fetchJsonBang(json, "path"), "invalid project patch operation path");
		var path = pathFromRelativeBang(root, relative);
		rejectReservedTargetBang(relative);
		var before = stateFromJsonBang(fetchJsonBang(json, "before"));
		var afterState = stateFromJsonBang(fetchJsonBang(json, "after"));
		var manifest = requiredBooleanBang(json, "manifest");
		validateOperationStatesBang(kind, before, afterState, relative);

		var operation = new PatchOperation(kind, path, relative, before, afterState, kind == DELETE ? REMOVED : PATCHED, manifest);
		var newPath = nullableRelativePathBang(root, ElixirMap.getTyped(json, "newPath"));
		var backupPath = nullableRelativePathBang(root, ElixirMap.getTyped(json, "backupPath"));
		var expectedBackup:Null<String> = before.state == REGULAR ? Path.join([directory, "backups", ElixirInteger.toString(index)]) : null;
		var expectedNew:Null<String> = kind == WRITE ? Path.joinTwo(Path.dirname(path),
			"." + Path.basename(path) + ".reflaxe-patch-" + id + "-" + ElixirInteger.toString(index) + ".new") : null;
		if (backupPath != expectedBackup)
			return Kernel.raiseValue("invalid project patch backup path for " + relative);
		if (newPath != expectedNew)
			return Kernel.raiseValue("invalid project patch temporary path for " + relative);
		return {
			operation: operation,
			newPath: newPath,
			newRelative: relativeOrNil(root, newPath),
			backupPath: backupPath,
			backupRelative: relativeOrNil(root, backupPath)
		};
	}

	static function validateLoadedTransactionBang(transaction:PatchTransaction):Atom {
		var operations = transaction.operations;
		if (operations.length == 0)
			return Kernel.raiseValue("project patch transaction contains no operations");
		validateStagedPathsBang(operations);
		var manifestIndices = Enum.flatMap(Enum.withIndex(operations), function(entry:Term):Array<Int> {
			var staged:StagedPatchOperation = Kernel.elemAs(entry, 0);
			return staged.operation.manifest ? [Kernel.elemAs(entry, 1)] : [];
		});
		if (manifestIndices.length > 1 || (manifestIndices.length == 1 && manifestIndices[0] != operations.length - 1))
			return Kernel.raiseValue("project patch transaction manifest must be the final operation");

		var createdDirs = transaction.createdDirs;
		assertUniquePathsBang(createdDirs, "created directory");
		var sortedDirs = Enum.sortBy(createdDirs, function(path:String):Int return pathDepth(transaction.root, path));
		if (!sameTerm(createdDirs, sortedDirs))
			return Kernel.raiseValue("project patch created directories are not ordered from parent to child");
		var allowedCreatedDirs = MapSet.fromValues(Enum.flatMap(Enum.filter(operations,
			function(staged:StagedPatchOperation):Bool return staged.operation.kind == WRITE),
			function(staged:StagedPatchOperation):Array<String> return parentDirectories(transaction.root, staged.operation.path)));
		Enum.each(createdDirs, function(directory:String):Void {
			if (!MapSet.member(allowedCreatedDirs, directory))
				Kernel.raise("invalid project patch created directory: " + directory);
		});
		return OK;
	}

	static function validateOperationStatesBang(kind:Atom, before:PatchFileState, afterState:PatchFileState, relative:String):Atom {
		return kind == WRITE
			&& afterState.state == REGULAR ? (sameState(before,
				afterState) ? Kernel.raiseValue("project patch journal contains a no-op write for " + relative) : OK) : kind == DELETE
				&& before.state == REGULAR
				&& afterState.state == MISSING ? OK : Kernel.raiseValue("invalid project patch " + Kernel.toString(kind) + " state transition for "
					+ relative + ": " + Kernel.inspect(before.state) + " -> " + Kernel.inspect(afterState.state));
	}

	static function requiredBooleanBang(json:Term, key:String):Bool {
		var fetched = ElixirMap.fetchTerm(json, key);
		if (!hasTag(fetched, OK))
			return Kernel.raiseValue("invalid project patch boolean field: " + key);
		var value:Term = Kernel.elemAs(fetched, 1);
		return Kernel.isBoolean(value) ? Kernel.elemAs({_0: OK, _1: value}, 1) : Kernel.raiseValue("invalid project patch boolean field: " + key);
	}

	static function validTransactionId(id:Term):Bool {
		return Kernel.isBinary(id) && Regex.match(Regex.compileBang("\\A[1-9][0-9]*\\z"), Kernel.elemAs({_0: OK, _1: id}, 1));
	}

	static function idValue(id:Term):{_0:String} {
		return {_0: Kernel.elemAs({_0: OK, _1: id}, 1)};
	}

	static function presentPath(path:Null<String>):Array<String> {
		return path == null ? [] : [path];
	}

	static function assertUniquePathsBang(paths:Array<String>, label:String):Atom {
		if (paths.length != MapSet.size(MapSet.fromValues(paths)))
			return Kernel.raiseValue("project patch transaction contains duplicate " + label + " paths");
		return OK;
	}

	static function parentDirectories(root:String, path:String):Array<String> {
		var relative = Path.relativeTo(Path.dirname(path), root);
		if (relative == ".")
			return [];
		return Enum.scan(Path.split(relative), root, function(part:String, parent:String):String return Path.joinTwo(parent, part));
	}

	static function pathDepth(root:String, path:String):Int {
		return Path.split(Path.relativeTo(path, root)).length;
	}

	static function stateFromJsonBang(json:Term):PatchFileState {
		if (!Kernel.isMap(json))
			return Kernel.raiseValue("invalid project patch file state: " + Kernel.inspect(json));
		var state:Term = ElixirMap.getTyped(json, "state");
		return sameTerm(state,
			"missing") ? missingState() : sameTerm(state,
				"regular") ? regularStateFromJsonBang(json) : Kernel.raiseValue("invalid project patch file state: " + Kernel.inspect(json));
	}

	static function regularStateFromJsonBang(json:Term):PatchFileState {
		var digest:Term = ElixirMap.getTyped(json, "sha256");
		var mode:Term = ElixirMap.getTyped(json, "mode");
		if (!Kernel.isBinary(digest) || !Kernel.isInteger(mode))
			return Kernel.raiseValue("invalid project patch file state: " + Kernel.inspect(json));
		var sha:String = Kernel.elemAs({_0: OK, _1: digest}, 1);
		var numericMode:Int = Kernel.elemAs({_0: OK, _1: mode}, 1);
		return sha.length != 64
			|| numericMode < 0
			|| numericMode > PERMISSION_MASK
			|| !Regex.match(Regex.compileBang("\\A[0-9a-f]{64}\\z"),
				sha) ? Kernel.raiseValue("invalid project patch content digest: " + Kernel.inspect(digest)) : {
					state: REGULAR,
					sha256: sha,
					mode: numericMode
				};
	}

	static function verifyTargetBang(root:String, operation:PatchOperation, side:String):Atom {
		var expected = side == "before" ? operation.before : operation.after;
		var current = snapshotBang(root, operation.path);
		if (!sameState(current, expected))
			return Kernel.raiseValue("project patch target changed before publication: " + operation.path);
		return OK;
	}

	static function invokeFaultBang(faultInjector:(Term, PatchOperation) -> Term, stage:Term, operation:PatchOperation):Atom {
		var result = faultInjector(stage, operation);
		if (sameTerm(result, OK))
			return OK;
		if (hasTag(result, ERROR))
			return Kernel.raiseValue("injected project patch failure: " + Kernel.toString(Kernel.elemAs(result, 1)));
		return Kernel.raiseValue("invalid project patch fault injector result: " + Kernel.inspect(result));
	}

	static function safely(fun:Void->Void):Term {
		try {
			fun();
			return OK;
		} catch (error:NativeException) {
			return {_0: ERROR, _1: error};
		}
	}

	static function snapshotBang(root:String, path:String):PatchFileState {
		validateParentChainBang(root, path);
		var result = File.lstatResult(path);
		if (hasTag(result, ERROR)) {
			var reason:Term = Kernel.elemAs(result, 1);
			return sameTerm(reason, ENOENT) ? missingState() : Kernel.raiseValue("cannot inspect project patch target " + path + ": " + Kernel.inspect(reason));
		}
		return snapshotRegularBang(path, result);
	}

	static function snapshotRegularBang(path:String, result:Term):PatchFileState {
		var stat:FileStat = Kernel.elemAs(result, 1);
		return stat.type != REGULAR ? Kernel.raiseValue("project patch target is not a regular file (" + Kernel.toString(stat.type) + "): " +
			path) : regularState(File.readBang(path), Bitwise.band(stat.mode, PERMISSION_MASK));
	}

	static function missingState():PatchFileState {
		return {state: MISSING};
	}

	static function regularState(content:String, mode:Int):PatchFileState {
		return {
			state: REGULAR,
			content: content,
			sha256: sha256(content),
			mode: mode
		};
	}

	static function sameState(left:PatchFileState, right:PatchFileState):Bool {
		if (left.state == MISSING || right.state == MISSING)
			return left.state == MISSING && right.state == MISSING;
		return left.state == REGULAR && right.state == REGULAR && left.sha256 == right.sha256 && left.mode == right.mode;
	}

	static function sha256(content:String):String {
		return Base.encode16(Crypto.hash(SHA256, content), [{_0: CASE_KEY, _1: LOWER}]);
	}

	static function normalizeTargetBang(root:String, path:String):Term {
		final pathType = Path.typeAtom(path);
		var absolute = pathType == ABSOLUTE ? Path.expand(path) : Path.expandRelativeTo(path, root);
		var relative = Path.relativeTo(absolute, root);
		if (relative == "." || escapesRoot(relative))
			return Kernel.raiseValue("project patch target escapes the project root: " + path);
		rejectReservedTargetBang(relative);
		validateParentChainBang(root, absolute);
		return {_0: absolute, _1: relative};
	}

	static function pathFromRelativeBang(root:String, relative:String):String {
		final pathType = Path.typeAtom(relative);
		if (pathType == ABSOLUTE || relative == "." || escapesRoot(relative))
			return Kernel.raiseValue("invalid project patch relative path: " + Kernel.inspect(relative));
		var path = Path.expandRelativeTo(relative, root);
		if (Path.relativeTo(path, root) != relative)
			return Kernel.raiseValue("project patch relative path is not canonical: " + Kernel.inspect(relative));
		validateParentChainBang(root, path);
		return path;
	}

	static function nullableRelativePathBang(root:String, path:Term):Null<String> {
		return path == null ? null : pathFromRelativeBang(root, requireBinary(path, "invalid project patch relative path: " + Kernel.inspect(path)));
	}

	static function relativeOrNil(root:String, path:Null<String>):Null<String> {
		return path == null ? null : Path.relativeTo(path, root);
	}

	static function rejectReservedTargetBang(relative:String):Atom {
		if (relative == TRANSACTION_DIRECTORY || ElixirString.startsWith(relative, TRANSACTION_DIRECTORY + "/"))
			return Kernel.raiseValue("project patch target uses the reserved transaction path: " + relative);
		return OK;
	}

	static function escapesRoot(relative:String):Bool {
		final pathType = Path.typeAtom(relative);
		return pathType == ABSOLUTE || relative == ".." || ElixirString.startsWith(relative, "../");
	}

	static function validateParentChainBang(root:String, path:String):Atom {
		requireDirectoryBang(root, "project patch root");
		var relative = Path.relativeTo(path, root);
		if (escapesRoot(relative))
			return Kernel.raiseValue("project patch path escapes the project root: " + path);
		validateParentPartsBang(Path.split(Path.dirname(relative)), 0, root);
		return OK;
	}

	static function validateParentPartsBang(parts:Array<String>, index:Int, current:String):String {
		if (index >= parts.length)
			return current;
		var part = parts[index];
		if (part == ".")
			return validateParentPartsBang(parts, index + 1, current);
		var next = Path.joinTwo(current, part);
		var result = File.lstatResult(next);
		if (hasTag(result, OK)) {
			var stat:FileStat = Kernel.elemAs(result, 1);
			if (stat.type != DIRECTORY)
				return Kernel.raiseValue("project patch parent is not a directory (" + Kernel.toString(stat.type) + "): " + next);
			return validateParentPartsBang(parts, index + 1, next);
		}
		var reason:Term = Kernel.elemAs(result, 1);
		if (sameTerm(reason, ENOENT))
			return next;
		return Kernel.raiseValue("cannot inspect project patch parent " + next + ": " + Kernel.inspect(reason));
	}

	static function requireDirectoryBang(path:String, label:String):Atom {
		var result = File.lstatResult(path);
		if (hasTag(result, OK)) {
			var stat:FileStat = Kernel.elemAs(result, 1);
			if (stat.type == DIRECTORY)
				return OK;
			return Kernel.raiseValue(label + " is not a directory (" + Kernel.toString(stat.type) + "): " + path);
		}
		return Kernel.raiseValue("cannot inspect " + label + " " + path + ": " + Kernel.inspect(Kernel.elemAs(result, 1)));
	}

	static function requireOwnedTransactionDirectoryBang(directory:String):Atom {
		requireDirectoryBang(directory, "project patch transaction path");
		var owner = Path.joinTwo(directory, OWNER_FILENAME);
		var result = File.lstatResult(owner);
		if (hasTag(result, OK)) {
			var stat:FileStat = Kernel.elemAs(result, 1);
			if (stat.type != REGULAR)
				return Kernel.raiseValue("project patch transaction owner is not a regular file (" + Kernel.toString(stat.type) + "): " + owner);
			if (File.readBang(owner) != OWNER_MARKER)
				return Kernel.raiseValue("project patch transaction owner marker is invalid: " + owner);
			return OK;
		}
		return Kernel.raiseValue("cannot inspect project patch transaction owner " + owner + ": " + Kernel.inspect(Kernel.elemAs(result, 1)));
	}

	static function writeExclusiveBang(path:String, content:String, mode:Int):Atom {
		File.writeBangWithAtomModes(path, content, [WRITE, EXCLUSIVE, BINARY]);
		File.chmodBang(path, mode);
		return OK;
	}

	static function atomicWriteBang(path:String, content:String):Atom {
		var temp = path + ".tmp";
		File.writeBangWithAtomModes(temp, content, [WRITE, EXCLUSIVE, BINARY]);
		File.renameBang(temp, path);
		return OK;
	}

	static function jsonObject(pairs:Array<{_0:String, _1:Term}>):Term {
		return buildJsonObject(pairs, 0, ElixirMap.new_());
	}

	static function buildJsonObject(pairs:Array<{_0:String, _1:Term}>, index:Int, value:Term):Term {
		if (index >= pairs.length)
			return value;
		var pair = pairs[index];
		return buildJsonObject(pairs, index + 1, ElixirMap.putTerm(value, pair._0, pair._1));
	}

	static function fetchJsonBang(json:Term, key:String):Term {
		var fetched = ElixirMap.fetchTerm(json, key);
		return hasTag(fetched, OK) ? Kernel.elemAs(fetched, 1) : Kernel.raiseValue("missing project patch JSON field: " + key);
	}

	static function requireBinary(value:Term, message:String):String {
		return Kernel.isBinary(value) ? Kernel.elemAs({_0: OK, _1: value}, 1) : Kernel.raiseValue(message);
	}

	static function markerSpan(content:String, beginToken:String, endToken:String):Term {
		if (beginToken == "" || endToken == "" || beginToken == endToken)
			return error({_0: INVALID_MARKER_TOKENS, _1: beginToken, _2: endToken});

		var lines = ElixirString.splitOn(content, "\n");
		var begins = matchingLineIndices(lines, beginToken);
		var ends = matchingLineIndices(lines, endToken);
		if (begins.length == 0 && ends.length == 0)
			return MISSING;
		if (begins.length == 1 && ends.length == 1) {
			var beginIndex = begins[0];
			var endIndex = ends[0];
			return beginIndex < endIndex ? {
				_0: OK,
				_1: lines,
				_2: beginIndex,
				_3: endIndex
			} : error({
				_0: INVERTED_MARKER_PAIR,
				_1: beginToken,
				_2: endToken,
				_3: beginIndex,
				_4: endIndex
				});
		}
		return error({
			_0: MARKER_COUNT,
			_1: beginToken,
			_2: begins.length,
			_3: endToken,
			_4: ends.length
		});
	}

	static function matchingLineIndices(lines:Array<String>, token:String):Array<Int> {
		return Enum.flatMap(Enum.withIndex(lines), function(entry:Term):Array<Int> {
			var line:String = Kernel.elemAs(entry, 0);
			var index:Int = Kernel.elemAs(entry, 1);
			return markerTokenOnLine(line, token) ? [index] : [];
		});
	}

	static function markerTokenOnLine(line:String, token:String):Bool {
		var pattern = "(?:^|\\s)" + Regex.escape(token) + "(?=$|\\s)";
		return Regex.match(Regex.compileBang(pattern), line);
	}

	static function replaceLineSpan(lines:Array<String>, beginIndex:Int, endIndex:Int, replacement:Array<String>):String {
		var updated = Enum.flatMap(Enum.withIndex(lines), function(entry:Term):Array<String> {
			var line:String = Kernel.elemAs(entry, 0);
			var index:Int = Kernel.elemAs(entry, 1);
			if (index < beginIndex)
				return [line];
			if (index == beginIndex)
				return replacement;
			return index <= endIndex ? [] : [line];
		});
		return Enum.join(updated, "\n");
	}

	static function leadingIndent(line:String):String {
		var leading = Enum.takeWhile(ElixirString.graphemes(line), function(character:String):Bool return character == " " || character == "\t");
		return Enum.join(leading, "");
	}

	static function decodeJsonObject(content:String):Term {
		var decoded = Jason.decodeResult(content);
		if (hasTag(decoded, OK)) {
			var value:Term = Kernel.elemAs(decoded, 1);
			return Kernel.isMap(value) ? ok(value) : error("package JSON must contain an object");
		}
		var reason:Term = Kernel.elemAs(decoded, 1);
		return error("invalid package JSON: " + ElixirException.message(reason));
	}

	static function validateKeyPath(path:Array<String>):Term {
		return validateKeyPathAt(path, 0);
	}

	static function fetchJsonPath(json:Term, path:Array<String>, parents:Array<String>):Term {
		var key = path[0];
		var fetched = ElixirMap.fetchTerm(json, key);
		if (sameTerm(fetched, ERROR))
			return MISSING;
		var value:Term = Kernel.elemAs(fetched, 1);
		if (path.length == 1)
			return ok(value);
		if (!Kernel.isMap(value))
			return error("package JSON key path " + Enum.join(Enum.concatTwo(parents, [key]), ".") + " must contain an object");
		return fetchJsonPath(value, Enum.drop(path, 1), Enum.concatTwo(parents, [key]));
	}

	static function stripJsonPath(json:Term, path:Array<String>):Term {
		var key = path[0];
		if (path.length == 1)
			return ElixirMap.deleteTerm(json, key);

		var fetched = ElixirMap.fetchTerm(json, key);
		if (sameTerm(fetched, ERROR))
			return json;
		var value:Term = Kernel.elemAs(fetched, 1);
		if (!Kernel.isMap(value))
			return json;
		var child = stripJsonPath(value, Enum.drop(path, 1));
		return Kernel.mapSize(child) == 0 ? ElixirMap.deleteTerm(json, key) : ElixirMap.putTerm(json, key, child);
	}

	static function tupleTag(value:Term):Null<Atom> {
		return Kernel.isTuple(value) && Kernel.tupleSize(value) > 0 ? Kernel.elemAs(value, 0) : null;
	}

	static function collectMarkerSpans(content:String, pairs:Array<{_0:String, _1:String}>, index:Int, spans:Array<MarkerSpan>):Term {
		if (index >= pairs.length)
			return ok(spans);
		var pair = pairs[index];
		var span = markerSpan(content, pair._0, pair._1);
		if (hasTag(span, ERROR))
			return span;
		var updated = spans;
		if (!sameTerm(span, MISSING)) {
			updated = Enum.concatTwo(spans, [
				{
					first: Kernel.elemAs(span, 2),
					last: Kernel.elemAs(span, 3),
					token: pair._0
				}
			]);
		}
		return collectMarkerSpans(content, pairs, index + 1, updated);
	}

	static function validateOrderedSpans(spans:Array<MarkerSpan>, index:Int):Term {
		if (index >= spans.length)
			return OK;
		var first = spans[index - 1];
		var second = spans[index];
		if (second.first <= first.last) {
			return error({
				_0: OVERLAPPING_MARKER_PAIRS,
				_1: first.token,
				_2: {_0: first.first, _1: first.last},
				_3: second.token,
				_4: {_0: second.first, _1: second.last}
			});
		}
		return validateOrderedSpans(spans, index + 1);
	}

	static function validateKeyPathAt(path:Array<String>, index:Int):Term {
		if (index >= path.length)
			return path.length == 0 ? error("package JSON key path must contain non-empty strings") : OK;
		if (path[index] == "")
			return error("package JSON key path must contain non-empty strings");
		return validateKeyPathAt(path, index + 1);
	}

	static function hasTag(value:Term, tag:Atom):Bool {
		var actual:Term = tupleTag(value);
		return sameTerm(actual, tag);
	}

	static function sameTerm(left:Term, right:Term):Bool {
		return left == right;
	}

	static function ok(value:Term):Term {
		return {_0: OK, _1: value};
	}

	static function error(reason:Term):Term {
		return {_0: ERROR, _1: reason};
	}
}
