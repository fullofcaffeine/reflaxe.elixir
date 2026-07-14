package reflaxe.elixir;

#if (macro || reflaxe_runtime)
import haxe.Json;
import haxe.crypto.Sha256;
import haxe.io.Bytes;
import haxe.io.Path;
import haxe.macro.Context;
import reflaxe.BaseCompiler;
import reflaxe.output.StringOrBytes;
import sys.FileSystem;
import sys.io.File;

using StringTools;

/** A generated path and its not-yet-published contents. */
typedef GeneratedOutputCandidate = {
	var path:String;
	var content:StringOrBytes;
}

private typedef OwnedFileRecord = {
	var path:String;
	var digest:String;
}

private typedef OwnershipState = {
	var exists:Bool;
	var legacy:Bool;
	var id:Int;
	var paths:Array<String>;
	var digests:Map<String, String>;
}

private typedef TransactionPath = {
	var path:String;
	var tempPath:String;
	var hadPrevious:Bool;
	var previousDigest:Null<String>;
	var nextDigest:Null<String>;
}

private typedef TransactionJournal = {
	var protocol:String;
	var version:Int;
	var paths:Array<TransactionPath>;
	var previousManifest:Bool;
	var previousManifestDigest:Null<String>;
	var nextManifestDigest:String;
}

/**
 * Owns the fail-closed publication protocol for generated Elixir files.
 *
 * WHAT
 * - Treats `_GeneratedFiles.json` as the authoritative path ownership record.
 * - Stages the complete next output set before any live file is changed.
 * - Rejects unowned collisions and modifications to hash-owned generated files.
 * - Publishes through a recoverable transaction whose manifest is committed last.
 *
 * WHY
 * - Reflaxe's default output manager writes one module at a time. In an in-place
 *   Phoenix tree, that can overwrite handwritten source before a later error is
 *   discovered, and an interrupted build can leave the manifest behind the files.
 *
 * HOW
 * - Version 1 Reflaxe manifests are accepted as the upgrade ownership record.
 * - Version 2 adds a digest for every owned file and a deterministic generation id.
 * - Backups, staged files, and a strict journal live under reserved control paths.
 * - If the final manifest is absent after interruption, recovery rolls the files
 *   back. If the final manifest is present, recovery only removes transaction data.
 *
 * EXAMPLE
 * - A generated `lib/app_web/page_live.ex` may be updated when version 2 owns it and
 *   its digest still matches. The same existing path without manifest ownership is
 *   rejected before either the existing file or another generated file is changed.
 */
class GeneratedOutputOwnership {
	public static inline var MANIFEST_FILENAME = "_GeneratedFiles.json";
	public static inline var PROTOCOL = "reflaxe-elixir/generated-output";
	public static inline var TRANSACTION_PROTOCOL = "reflaxe-elixir/generated-output-transaction";
	public static inline var MANIFEST_VERSION = 2;
	public static inline var TRANSACTION_VERSION = 2;

	static inline var PREPARE_DIRECTORY = "._GeneratedFiles.prepare";
	static inline var TRANSACTION_DIRECTORY = "._GeneratedFiles.transaction";
	static inline var MANIFEST_TEMP_FILENAME = "._GeneratedFiles.json.new";
	static inline var OWNER_FILENAME = "owner";
	static inline var JOURNAL_FILENAME = "journal.json";
	static inline var PREVIOUS_MANIFEST_FILENAME = "previous_manifest.json";
	static inline var NEXT_MANIFEST_FILENAME = "next_manifest.json";
	static inline var STAGED_DIRECTORY = "staged";
	static inline var BACKUP_DIRECTORY = "backups";
	static inline var OWNER_MARKER = "reflaxe.elixir generated-output transaction v2\n";
	static inline var OUTPUT_TEMP_SUFFIX = ".__reflaxe_output_new__";

	/**
	 * Recovers a previously activated publication transaction, or removes a prepare
	 * tree that could not have changed live output yet.
	 */
	public static function recover(outputDirectory:String):Void {
		#if sys
		if (!FileSystem.exists(outputDirectory))
			return;
		if (!FileSystem.isDirectory(outputDirectory))
			fail('Generated output root is not a directory: $outputDirectory');

		var root = FileSystem.fullPath(Path.normalize(outputDirectory));
		var active = Path.join([root, TRANSACTION_DIRECTORY]);
		var prepare = Path.join([root, PREPARE_DIRECTORY]);

		if (directoryEntryExists(root, TRANSACTION_DIRECTORY)) {
			if (!FileSystem.exists(active))
				fail('Reserved generated-output transaction path cannot be resolved safely: $active');
			recoverActive(root, active);
		}
		if (directoryEntryExists(root, PREPARE_DIRECTORY)) {
			if (!FileSystem.exists(prepare))
				fail('Reserved generated-output prepare path cannot be resolved safely: $prepare');
			validateControlDirectory(root, prepare);
			safeRemoveTree(prepare);
		}

		var manifestTemp = Path.join([root, MANIFEST_TEMP_FILENAME]);
		if (directoryEntryExists(root, MANIFEST_TEMP_FILENAME)) {
			fail('Reserved generated-output manifest path exists without a recoverable transaction: $manifestTemp');
		}
		#else
		fail("Generated-output ownership requires a sys-capable Haxe macro environment.");
		#end
	}

	/**
	 * Stages, validates, optionally post-processes, and transactionally publishes a
	 * complete generated output set. Returns normalized manifest-relative paths.
	 */
	public static function publish(compiler:BaseCompiler, outputDirectory:String, candidates:Array<GeneratedOutputCandidate>,
			cachedRebuild:Bool):Array<String> {
		#if sys
		ensureDirectory(outputDirectory);
		var root = FileSystem.fullPath(Path.normalize(outputDirectory));
		recover(root);

		var prepare = Path.join([root, PREPARE_DIRECTORY]);
		if (directoryEntryExists(root, PREPARE_DIRECTORY))
			fail('Reserved generated-output prepare path is already in use: $prepare');

		var activated = false;
		try {
			var previous = readOwnership(root);
			var pending = new Map<String, StringOrBytes>();
			var pendingOrder:Array<String> = [];

			for (candidate in candidates) {
				var path = validateRelativePath(candidate.path, "generated output");
				if (isReservedPath(path))
					fail('Generated output path is reserved by the ownership protocol: $path');
				if (pending.exists(path))
					fail('The compiler produced the same generated path more than once: $path');
				pending.set(path, candidate.content);
				pendingOrder.push(path);
			}

			verifyOwnedFiles(root, previous);
			var oldSet = stringSet(previous.paths);
			for (path in pendingOrder) {
				var target = targetPath(root, path);
				if (FileSystem.exists(target) && !oldSet.exists(path)) {
					fail('Refusing to overwrite unowned file `$target`. Move it, choose isolated output, or remove the ownership collision explicitly.');
				}
			}

			var nextPaths = cachedRebuild ? previous.paths.copy() : [];
			var nextSet = stringSet(nextPaths);
			for (path in pendingOrder) {
				if (!nextSet.exists(path)) {
					nextPaths.push(path);
					nextSet.set(path, true);
				}
			}

			if (cachedRebuild) {
				for (path in previous.paths) {
					if (!pending.exists(path) && !FileSystem.exists(targetPath(root, path)))
						fail('Cached rebuild cannot preserve missing owned output `$path`; run a full Haxe rebuild.');
				}
			}

			// Claim the fixed prepare path only after every fail-closed ownership
			// preflight has passed. A handwritten collision therefore leaves no files,
			// manifests, or control directories behind.
			if (directoryEntryExists(root, PREPARE_DIRECTORY))
				fail('Reserved generated-output prepare path was claimed by another compiler: $prepare');
			FileSystem.createDirectory(prepare);
			File.saveContent(Path.join([prepare, OWNER_FILENAME]), OWNER_MARKER);
			verifyOwnedFiles(root, previous);
			for (path in pendingOrder) {
				var target = targetPath(root, path);
				if (FileSystem.exists(target) && !oldSet.exists(path))
					fail('Unowned output collision appeared while publication was being prepared: $target');
			}

			var stagedRoot = Path.join([prepare, STAGED_DIRECTORY]);
			ensureDirectory(stagedRoot);
			for (path in nextPaths) {
				var staged = targetPath(stagedRoot, path);
				ensureDirectory(Path.directory(staged));
				if (pending.exists(path)) {
					var content = pending.get(path);
					if (content == null)
						fail('Missing pending output contents for `$path`.');
					content.save(staged);
				} else {
					File.copy(targetPath(root, path), staged);
				}
			}

			// The target formatter consumes the normal Reflaxe manifest shape. This
			// provisional copy is confined to staging and is replaced by version 2 below.
			File.saveContent(Path.join([stagedRoot, MANIFEST_FILENAME]), Json.stringify({
				filesGenerated: nextPaths,
				id: 0,
				wasCached: cachedRebuild,
				version: 1
			}, null, "\t") + "\n");
			compiler.onOutputPrepared(stagedRoot);

			var owned:Array<OwnedFileRecord> = [];
			var newDigests = new Map<String, String>();
			for (path in nextPaths) {
				var staged = targetPath(stagedRoot, path);
				if (!FileSystem.exists(staged) || FileSystem.isDirectory(staged))
					fail('Prepared output hook removed or replaced generated file `$path`.');
				ensureCanonicalWithin(stagedRoot, staged, "prepared output");
				var digest = hashFile(staged);
				newDigests.set(path, digest);
				owned.push({path: path, digest: digest});
			}
			owned.sort((left, right) -> Reflect.compare(left.path, right.path));
			var manifestOwned:Array<Dynamic> = [];
			for (record in owned) {
				var manifestRecord:Dynamic = {path: record.path};
				Reflect.setField(manifestRecord, "sha256", record.digest);
				manifestOwned.push(manifestRecord);
			}

			var generation = generationDigest(owned);
			var nextId = #if reflaxe.dont_output_metadata_id 0 #else previous.id + 1 #end;
			var nextManifest = Json.stringify({
				filesGenerated: nextPaths,
				generation: generation,
				id: nextId,
				ownedFiles: manifestOwned,
				protocol: PROTOCOL,
				version: MANIFEST_VERSION,
				wasCached: cachedRebuild
			}, null, "\t") + "\n";

			var affected:Array<String> = [];
			for (path in previous.paths) {
				if (!nextSet.exists(path) && FileSystem.exists(targetPath(root, path)))
					affected.push(path);
			}
			for (path in nextPaths) {
				var target = targetPath(root, path);
				var digest = newDigests.get(path);
				if (!FileSystem.exists(target) || digest == null || hashFile(target) != digest)
					affected.push(path);
			}
			affected.sort(Reflect.compare);

			var transactionPaths:Array<TransactionPath> = [];
			var allOwned = stringSet(previous.paths.concat(nextPaths));
			for (path in affected) {
				var tempPath = validateRelativePath(path + OUTPUT_TEMP_SUFFIX, "transaction temporary output");
				if (allOwned.exists(tempPath))
					fail('Generated output `$tempPath` collides with a reserved transaction path.');
				var absoluteTemp = targetPath(root, tempPath);
				if (FileSystem.exists(absoluteTemp))
					fail('Reserved generated-output transaction path already exists: $absoluteTemp');
				var nextDigest = nextSet.exists(path) ? newDigests.get(path) : null;
				if (nextSet.exists(path) && nextDigest == null)
					fail('Missing next generated-output digest for `$path`.');
				var target = targetPath(root, path);
				var hadPrevious = FileSystem.exists(target);
				transactionPaths.push({
					path: path,
					tempPath: tempPath,
					hadPrevious: hadPrevious,
					previousDigest: hadPrevious ? hashFile(target) : null,
					nextDigest: nextDigest
				});
			}

			var backups = Path.join([prepare, BACKUP_DIRECTORY]);
			ensureDirectory(backups);
			for (index in 0...transactionPaths.length) {
				var entry = transactionPaths[index];
				if (entry.hadPrevious)
					File.copy(targetPath(root, entry.path), Path.join([backups, Std.string(index)]));
			}

			var manifestPath = Path.join([root, MANIFEST_FILENAME]);
			var previousManifestDigest:Null<String> = null;
			if (previous.exists) {
				var previousManifestPath = Path.join([prepare, PREVIOUS_MANIFEST_FILENAME]);
				File.copy(manifestPath, previousManifestPath);
				previousManifestDigest = hashFile(previousManifestPath);
			}
			var nextManifestPath = Path.join([prepare, NEXT_MANIFEST_FILENAME]);
			File.saveContent(nextManifestPath, nextManifest);
			var journal:TransactionJournal = {
				protocol: TRANSACTION_PROTOCOL,
				version: TRANSACTION_VERSION,
				paths: transactionPaths,
				previousManifest: previous.exists,
				previousManifestDigest: previousManifestDigest,
				nextManifestDigest: hashFile(nextManifestPath)
			};
			File.saveContent(Path.join([prepare, JOURNAL_FILENAME]), Json.stringify(journal, null, "\t") + "\n");

			// Recheck the exact bytes backed up before activating the journal. A
			// concurrent edit therefore fails while live output is still untouched.
			for (index in 0...transactionPaths.length) {
				var entry = transactionPaths[index];
				var target = targetPath(root, entry.path);
				if (entry.hadPrevious) {
					if (!FileSystem.exists(target) || entry.previousDigest == null || hashFile(target) != entry.previousDigest)
						fail('Generated output changed while publication was being prepared: $target');
				} else if (FileSystem.exists(target)) {
					fail('Unowned output collision appeared while publication was being prepared: $target');
				}
			}

			var active = Path.join([root, TRANSACTION_DIRECTORY]);
			if (directoryEntryExists(root, TRANSACTION_DIRECTORY))
				fail('Reserved generated-output transaction path is already active: $active');
			FileSystem.rename(prepare, active);
			activated = true;

			var activeStaged = Path.join([active, STAGED_DIRECTORY]);
			for (entry in transactionPaths) {
				var target = targetPath(root, entry.path);
				var temp = targetPath(root, entry.tempPath);
				verifyPrePublicationTarget(target, entry);
				if (nextSet.exists(entry.path)) {
					ensureDirectory(Path.directory(target));
					File.copy(targetPath(activeStaged, entry.path), temp);
					replaceFile(temp, target);
				} else if (FileSystem.exists(target)) {
					if (FileSystem.isDirectory(target))
						fail('Owned generated output became a directory during publication: $target');
					FileSystem.deleteFile(target);
				}
			}

			var manifestTemp = Path.join([root, MANIFEST_TEMP_FILENAME]);
			File.copy(Path.join([active, NEXT_MANIFEST_FILENAME]), manifestTemp);
			replaceFile(manifestTemp, manifestPath);

			removeTransactionTemps(root, journal);
			safeRemoveTree(active);
			activated = false;

			if (affected.length == 0)
				Sys.println("No files updated.");
			return nextPaths;
		} catch (error:Dynamic) {
			if (!activated && FileSystem.exists(prepare)) {
				try
					safeRemoveTree(prepare)
				catch (_:Dynamic) {}
			}
			throw error;
		}
		#else
		fail("Generated-output ownership requires a sys-capable Haxe macro environment.");
		return [];
		#end
	}

	#if sys
	static function readOwnership(root:String):OwnershipState {
		var manifestPath = Path.join([root, MANIFEST_FILENAME]);
		if (!FileSystem.exists(manifestPath)) {
			return {
				exists: false,
				legacy: false,
				id: 0,
				paths: [],
				digests: []
			};
		}
		if (FileSystem.isDirectory(manifestPath))
			fail('Generated-output ownership manifest is a directory: $manifestPath');
		ensureCanonicalWithin(root, manifestPath, "generated-output ownership manifest");

		var raw:Dynamic = try Json.parse(File.getContent(manifestPath)) catch (error:Dynamic) {
			fail('Cannot parse generated-output ownership manifest `$manifestPath`: ${Std.string(error)}');
			{};
		};
		var version = requiredInt(raw, "version", manifestPath);
		var id = requiredInt(raw, "id", manifestPath);
		if (id < 0)
			fail('Generated-output ownership manifest has a negative `id`: $manifestPath');
		var paths = requiredPaths(raw, "filesGenerated", manifestPath);

		if (version == 1) {
			return {
				exists: true,
				legacy: true,
				id: id,
				paths: paths,
				digests: []
			};
		}
		if (version != MANIFEST_VERSION)
			fail('Unsupported generated-output ownership manifest version `$version` at $manifestPath.');
		if (requiredString(raw, "protocol", manifestPath) != PROTOCOL)
			fail('Unexpected generated-output ownership protocol at $manifestPath.');

		var dynamicOwned:Dynamic = Reflect.field(raw, "ownedFiles");
		if (!isArrayValue(dynamicOwned))
			fail('Generated-output ownership manifest has invalid `ownedFiles`: $manifestPath');
		var ownedValues:Array<Dynamic> = cast dynamicOwned;
		var digests = new Map<String, String>();
		var records:Array<OwnedFileRecord> = [];
		for (value in ownedValues) {
			var path = validateRelativePath(requiredString(value, "path", manifestPath), "owned manifest path");
			var digest = requiredString(value, "sha256", manifestPath).toLowerCase();
			if (!validDigest(digest))
				fail('Generated-output manifest has an invalid SHA-256 digest for `$path`: $manifestPath');
			if (digests.exists(path))
				fail('Generated-output manifest owns `$path` more than once: $manifestPath');
			digests.set(path, digest);
			records.push({path: path, digest: digest});
		}
		var pathSet = stringSet(paths);
		if (records.length != paths.length)
			fail('Generated-output manifest path and digest counts differ: $manifestPath');
		for (record in records) {
			if (!pathSet.exists(record.path))
				fail('Generated-output digest references an unowned path `${record.path}`: $manifestPath');
		}
		records.sort((left, right) -> Reflect.compare(left.path, right.path));
		var expectedGeneration = generationDigest(records);
		if (requiredString(raw, "generation", manifestPath).toLowerCase() != expectedGeneration)
			fail('Generated-output manifest generation digest does not match its owned files: $manifestPath');

		return {
			exists: true,
			legacy: false,
			id: id,
			paths: paths,
			digests: digests
		};
	}

	static function verifyOwnedFiles(root:String, ownership:OwnershipState):Void {
		for (path in ownership.paths) {
			var target = targetPath(root, path);
			if (!FileSystem.exists(target))
				continue;
			if (FileSystem.isDirectory(target))
				fail('Owned generated output is a directory: $target');
			ensureCanonicalWithin(root, target, "owned generated output");
			if (!ownership.legacy) {
				var expected = ownership.digests.get(path);
				if (expected == null || hashFile(target) != expected)
					fail('Owned generated output was modified outside the compiler: $target\nRefusing to overwrite or delete it until the change is reconciled explicitly.');
			}
		}
	}

	static function recoverActive(root:String, active:String):Void {
		validateControlDirectory(root, active);
		var journal = readJournal(root, active);
		var nextManifest = Path.join([active, NEXT_MANIFEST_FILENAME]);
		if (!FileSystem.exists(nextManifest) || FileSystem.isDirectory(nextManifest))
			fail('Generated-output transaction is missing its next manifest: $active');
		ensureCanonicalWithin(active, nextManifest, "next generated-output manifest");
		if (hashFile(nextManifest) != journal.nextManifestDigest)
			fail('Generated-output transaction next manifest failed integrity validation: $active');

		var manifest = Path.join([root, MANIFEST_FILENAME]);
		if (FileSystem.exists(manifest)) {
			if (FileSystem.isDirectory(manifest))
				fail('Generated-output ownership manifest is a directory: $manifest');
			ensureCanonicalWithin(root, manifest, "generated-output ownership manifest");
		}
		if (FileSystem.exists(manifest) && !FileSystem.isDirectory(manifest) && hashFile(manifest) == journal.nextManifestDigest) {
			removeTransactionTemps(root, journal);
			safeRemoveTree(active);
			return;
		}

		preflightRollback(root, active, journal);

		var backups = Path.join([active, BACKUP_DIRECTORY]);
		for (index in 0...journal.paths.length) {
			var entry = journal.paths[index];
			var target = targetPath(root, entry.path);
			var temp = targetPath(root, entry.tempPath);
			var backup = Path.join([backups, Std.string(index)]);
			validateTransactionBackup(active, backup, index, entry);
			validateRollbackTarget(target, entry);
			removeTransactionTemp(temp, entry.nextDigest);
			if (entry.hadPrevious) {
				if (!FileSystem.exists(target) || entry.previousDigest == null || hashFile(target) != entry.previousDigest) {
					File.copy(backup, temp);
					if (entry.previousDigest == null || hashFile(temp) != entry.previousDigest)
						fail('Generated-output transaction backup changed during rollback: $backup');
					validateRollbackTarget(target, entry);
					replaceFile(temp, target);
				}
			} else if (FileSystem.exists(target)) {
				validateRollbackTarget(target, entry);
				FileSystem.deleteFile(target);
			}
		}

		var manifestTemp = Path.join([root, MANIFEST_TEMP_FILENAME]);
		validatePreviousManifest(active, journal);
		validateRollbackManifestTarget(root, manifest, journal);
		removeTransactionTemp(manifestTemp, journal.nextManifestDigest);
		if (journal.previousManifest) {
			var previous = Path.join([active, PREVIOUS_MANIFEST_FILENAME]);
			if (!FileSystem.exists(manifest)
				|| journal.previousManifestDigest == null
				|| hashFile(manifest) != journal.previousManifestDigest) {
				File.copy(previous, manifestTemp);
				if (journal.previousManifestDigest == null || hashFile(manifestTemp) != journal.previousManifestDigest)
					fail('Generated-output transaction previous manifest changed during rollback: $previous');
				validateRollbackManifestTarget(root, manifest, journal);
				replaceFile(manifestTemp, manifest);
			}
		} else if (FileSystem.exists(manifest)) {
			validateRollbackManifestTarget(root, manifest, journal);
			FileSystem.deleteFile(manifest);
		}

		safeRemoveTree(active);
	}

	static function verifyPrePublicationTarget(target:String, entry:TransactionPath):Void {
		if (entry.hadPrevious) {
			if (!FileSystem.exists(target)
				|| FileSystem.isDirectory(target)
				|| entry.previousDigest == null
				|| hashFile(target) != entry.previousDigest) {
				fail('Generated output changed immediately before publication: $target');
			}
		} else if (FileSystem.exists(target)) {
			fail('Unowned output collision appeared immediately before publication: $target');
		}
	}

	/** Validates the entire rollback set before restoring or deleting any live file. */
	static function preflightRollback(root:String, active:String, journal:TransactionJournal):Void {
		var backups = Path.join([active, BACKUP_DIRECTORY]);
		for (index in 0...journal.paths.length) {
			var entry = journal.paths[index];
			var target = targetPath(root, entry.path);
			var temp = targetPath(root, entry.tempPath);
			preflightTransactionTemp(temp, entry.nextDigest);
			validateTransactionBackup(active, Path.join([backups, Std.string(index)]), index, entry);
			validateRollbackTarget(target, entry);
		}

		var manifestTemp = Path.join([root, MANIFEST_TEMP_FILENAME]);
		ensureCanonicalWithin(root, manifestTemp, "generated-output manifest temporary path");
		preflightTransactionTemp(manifestTemp, journal.nextManifestDigest);
		var manifest = Path.join([root, MANIFEST_FILENAME]);
		validatePreviousManifest(active, journal);
		validateRollbackManifestTarget(root, manifest, journal);
	}

	static function validateTransactionBackup(active:String, backup:String, index:Int, entry:TransactionPath):Void {
		if (!entry.hadPrevious)
			return;
		if (!FileSystem.exists(backup) || FileSystem.isDirectory(backup) || entry.previousDigest == null)
			fail('Generated-output transaction is missing backup `$index`: $active');
		ensureCanonicalWithin(active, backup, "generated-output transaction backup");
		if (hashFile(backup) != entry.previousDigest)
			fail('Generated-output transaction backup `$index` failed integrity validation: $active');
	}

	static function validateRollbackTarget(target:String, entry:TransactionPath):Void {
		if (!FileSystem.exists(target))
			return;
		if (FileSystem.isDirectory(target))
			fail('Generated-output recovery target is a directory: $target');
		var current = hashFile(target);
		if (entry.hadPrevious) {
			if (current != entry.previousDigest && (entry.nextDigest == null || current != entry.nextDigest))
				fail('Generated output changed after the interrupted publication: $target\nRefusing to overwrite the unexpected bytes during rollback.');
		} else if (entry.nextDigest == null || current != entry.nextDigest) {
			fail('Unowned or modified output occupies an interrupted publication path: $target\nRefusing to delete it during rollback.');
		}
	}

	static function validatePreviousManifest(active:String, journal:TransactionJournal):Void {
		if (!journal.previousManifest)
			return;
		var previous = Path.join([active, PREVIOUS_MANIFEST_FILENAME]);
		if (!FileSystem.exists(previous) || FileSystem.isDirectory(previous) || journal.previousManifestDigest == null)
			fail('Generated-output transaction is missing its previous manifest: $active');
		ensureCanonicalWithin(active, previous, "previous generated-output manifest");
		if (hashFile(previous) != journal.previousManifestDigest)
			fail('Generated-output transaction previous manifest failed integrity validation: $active');
	}

	static function validateRollbackManifestTarget(root:String, manifest:String, journal:TransactionJournal):Void {
		if (!FileSystem.exists(manifest))
			return;
		if (FileSystem.isDirectory(manifest))
			fail('Generated-output ownership manifest is a directory: $manifest');
		ensureCanonicalWithin(root, manifest, "generated-output ownership manifest");
		var current = hashFile(manifest);
		if (journal.previousManifest) {
			if (current != journal.previousManifestDigest && current != journal.nextManifestDigest)
				fail('Generated-output ownership manifest changed after interrupted publication: $manifest');
		} else if (current != journal.nextManifestDigest) {
			fail('Unowned manifest occupies an interrupted publication path: $manifest');
		}
	}

	static function preflightTransactionTemp(path:String, expected:Null<String>):Void {
		if (!FileSystem.exists(path))
			return;
		if (FileSystem.isDirectory(path) || expected == null || hashFile(path) != expected)
			fail('Generated-output transaction temporary path failed integrity validation: $path');
	}

	static function removeTransactionTemp(path:String, expected:Null<String>):Void {
		preflightTransactionTemp(path, expected);
		if (FileSystem.exists(path))
			FileSystem.deleteFile(path);
	}

	static function readJournal(root:String, active:String):TransactionJournal {
		var path = Path.join([active, JOURNAL_FILENAME]);
		if (!FileSystem.exists(path) || FileSystem.isDirectory(path))
			fail('Generated-output transaction journal is missing: $path');
		ensureCanonicalWithin(active, path, "generated-output transaction journal");
		var raw:Dynamic = try Json.parse(File.getContent(path)) catch (error:Dynamic) {
			fail('Cannot parse generated-output transaction journal `$path`: ${Std.string(error)}');
			{};
		};
		if (requiredString(raw, "protocol", path) != TRANSACTION_PROTOCOL || requiredInt(raw, "version", path) != TRANSACTION_VERSION)
			fail('Unsupported generated-output transaction journal: $path');

		var dynamicPaths:Dynamic = Reflect.field(raw, "paths");
		if (!isArrayValue(dynamicPaths))
			fail('Generated-output transaction journal has invalid `paths`: $path');
		var values:Array<Dynamic> = cast dynamicPaths;
		var seen = new Map<String, Bool>();
		var paths:Array<TransactionPath> = [];
		for (value in values) {
			var generatedPath = validateRelativePath(requiredString(value, "path", path), "transaction path");
			var tempPath = validateRelativePath(requiredString(value, "tempPath", path), "transaction temporary path");
			if (tempPath != generatedPath + OUTPUT_TEMP_SUFFIX)
				fail('Generated-output transaction has an unexpected temporary path for `$generatedPath`: $path');
			if (seen.exists(generatedPath))
				fail('Generated-output transaction repeats path `$generatedPath`: $path');
			seen.set(generatedPath, true);
			paths.push({
				path: generatedPath,
				tempPath: tempPath,
				hadPrevious: requiredBool(value, "hadPrevious", path),
				previousDigest: requiredNullableDigest(value, "previousDigest", path),
				nextDigest: requiredNullableDigest(value, "nextDigest", path)
			});
		}
		for (entry in paths) {
			if (entry.hadPrevious != (entry.previousDigest != null))
				fail('Generated-output transaction previous-file state is inconsistent for `${entry.path}`: $path');
			if (entry.previousDigest == null && entry.nextDigest == null)
				fail('Generated-output transaction has no owned byte state for `${entry.path}`: $path');
		}
		var nextDigest = requiredString(raw, "nextManifestDigest", path).toLowerCase();
		if (!validDigest(nextDigest))
			fail('Generated-output transaction has an invalid next-manifest digest: $path');
		var previousManifest = requiredBool(raw, "previousManifest", path);
		var previousManifestDigest = requiredNullableDigest(raw, "previousManifestDigest", path);
		if (previousManifest != (previousManifestDigest != null))
			fail('Generated-output transaction previous-manifest state is inconsistent: $path');
		return {
			protocol: TRANSACTION_PROTOCOL,
			version: TRANSACTION_VERSION,
			paths: paths,
			previousManifest: previousManifest,
			previousManifestDigest: previousManifestDigest,
			nextManifestDigest: nextDigest
		};
	}

	static function validateControlDirectory(root:String, directory:String):Void {
		if (!FileSystem.isDirectory(directory))
			fail('Reserved generated-output control path is not a directory: $directory');
		ensureCanonicalWithin(root, directory, "generated-output control directory");
		var marker = Path.join([directory, OWNER_FILENAME]);
		if (!FileSystem.exists(marker) || FileSystem.isDirectory(marker))
			fail('Reserved generated-output control path is not owned by Reflaxe.Elixir: $directory');
		ensureCanonicalWithin(directory, marker, "generated-output control owner marker");
		if (File.getContent(marker) != OWNER_MARKER)
			fail('Reserved generated-output control path is not owned by Reflaxe.Elixir: $directory');
	}

	static function removeTransactionTemps(root:String, journal:TransactionJournal):Void {
		for (entry in journal.paths) {
			var temp = targetPath(root, entry.tempPath);
			preflightTransactionTemp(temp, entry.nextDigest);
		}
		var manifestTemp = Path.join([root, MANIFEST_TEMP_FILENAME]);
		ensureCanonicalWithin(root, manifestTemp, "generated-output manifest temporary path");
		preflightTransactionTemp(manifestTemp, journal.nextManifestDigest);

		for (entry in journal.paths) {
			var temp = targetPath(root, entry.tempPath);
			removeTransactionTemp(temp, entry.nextDigest);
		}
		removeTransactionTemp(manifestTemp, journal.nextManifestDigest);
	}

	static function safeRemoveTree(path:String):Void {
		if (!FileSystem.exists(path))
			return;
		if (!FileSystem.isDirectory(path)) {
			FileSystem.deleteFile(path);
			return;
		}
		var canonicalRoot = FileSystem.fullPath(path);
		for (name in FileSystem.readDirectory(path)) {
			var child = Path.join([path, name]);
			ensureCanonicalWithin(canonicalRoot, child, "transaction cleanup");
			if (FileSystem.isDirectory(child))
				safeRemoveTree(child);
			else
				FileSystem.deleteFile(child);
		}
		FileSystem.deleteDirectory(path);
	}

	static function replaceFile(temporary:String, target:String):Void {
		if (FileSystem.exists(target) && FileSystem.isDirectory(target))
			fail('Cannot replace generated output because the target is a directory: $target');
		try {
			FileSystem.rename(temporary, target);
		} catch (_:Dynamic) {
			// Windows does not consistently replace an existing destination with rename.
			// The active journal and backup make this delete-then-rename path recoverable.
			if (FileSystem.exists(target))
				FileSystem.deleteFile(target);
			FileSystem.rename(temporary, target);
		}
	}

	static function targetPath(root:String, relative:String):String {
		var path = Path.join([root, relative]);
		ensureCanonicalWithin(root, path, "generated output path");
		return path;
	}

	static function ensureCanonicalWithin(root:String, candidate:String, label:String):Void {
		var canonicalRoot = normalizeAbsolute(FileSystem.fullPath(root));
		var existing = candidate;
		while (!FileSystem.exists(existing)) {
			var parent = Path.directory(existing);
			if (parent == null || parent.length == 0 || parent == existing)
				fail('Cannot resolve $label `$candidate` beneath `$root`.');
			if (FileSystem.exists(parent)
				&& FileSystem.isDirectory(parent)
				&& directoryEntryExists(parent, Path.withoutDirectory(existing))) {
				fail('$label contains a dangling or otherwise unresolvable filesystem entry: $candidate');
			}
			existing = parent;
		}
		var canonicalExisting = normalizeAbsolute(FileSystem.fullPath(existing));
		if (canonicalExisting != canonicalRoot && !canonicalExisting.startsWith(canonicalRoot + "/"))
			fail('$label escapes the generated output root through a symbolic link: $candidate');
		if (canonicalExisting != normalizeAbsolute(existing))
			fail('$label crosses a symbolic link inside the generated output root: $candidate');
	}

	static function normalizeAbsolute(path:String):String {
		var normalized = Path.normalize(path).replace("\\", "/");
		while (normalized.length > 1 && normalized.endsWith("/"))
			normalized = normalized.substr(0, normalized.length - 1);
		return normalized;
	}

	static function validateRelativePath(path:String, label:String):String {
		if (path == null || path.length == 0 || Path.isAbsolute(path) || path.indexOf("\\") >= 0 || hasControlCharacter(path))
			fail('Invalid $label `${Std.string(path)}`; paths must be non-empty portable relative paths.');
		var normalized = Path.normalize(path);
		if (normalized != path)
			fail('Invalid $label `$path`; normalized path would be `$normalized`.');
		for (part in path.split("/")) {
			if (part.length == 0 || part == "." || part == "..")
				fail('Invalid $label `$path`; traversal and empty segments are forbidden.');
		}
		return path;
	}

	static function hasControlCharacter(path:String):Bool {
		for (index in 0...path.length) {
			var code = path.charCodeAt(index);
			if (code < 32 || code == 127)
				return true;
		}
		return false;
	}

	static function isReservedPath(path:String):Bool {
		return path == MANIFEST_FILENAME
			|| path == PREPARE_DIRECTORY
			|| path.startsWith(PREPARE_DIRECTORY + "/")
			|| path == TRANSACTION_DIRECTORY
			|| path.startsWith(TRANSACTION_DIRECTORY + "/")
			|| path == MANIFEST_TEMP_FILENAME;
	}

	static function requiredPaths(raw:Dynamic, field:String, location:String):Array<String> {
		var value:Dynamic = Reflect.field(raw, field);
		if (!isArrayValue(value))
			fail('Generated-output metadata has invalid `$field`: $location');
		var dynamicPaths:Array<Dynamic> = cast value;
		var seen = new Map<String, Bool>();
		var paths:Array<String> = [];
		for (item in dynamicPaths) {
			if (!isStringValue(item))
				fail('Generated-output metadata has a non-string path in `$field`: $location');
			var path = validateRelativePath(cast item, "manifest path");
			if (isReservedPath(path))
				fail('Generated-output metadata owns reserved path `$path`: $location');
			if (seen.exists(path))
				fail('Generated-output metadata owns `$path` more than once: $location');
			seen.set(path, true);
			paths.push(path);
		}
		return paths;
	}

	static function requiredString(raw:Dynamic, field:String, location:String):String {
		var value:Dynamic = Reflect.field(raw, field);
		if (!isStringValue(value))
			fail('Generated-output metadata has invalid `$field`: $location');
		return cast value;
	}

	static function requiredInt(raw:Dynamic, field:String, location:String):Int {
		var value:Dynamic = Reflect.field(raw, field);
		if (Std.string(Type.typeof(value)) != "TInt")
			fail('Generated-output metadata has invalid `$field`: $location');
		return cast value;
	}

	static function requiredBool(raw:Dynamic, field:String, location:String):Bool {
		var value:Dynamic = Reflect.field(raw, field);
		if (Std.string(Type.typeof(value)) != "TBool")
			fail('Generated-output metadata has invalid `$field`: $location');
		return cast value;
	}

	static function requiredNullableDigest(raw:Dynamic, field:String, location:String):Null<String> {
		if (!Reflect.hasField(raw, field))
			fail('Generated-output metadata is missing `$field`: $location');
		var value:Dynamic = Reflect.field(raw, field);
		if (value == null)
			return null;
		if (!isStringValue(value))
			fail('Generated-output metadata has invalid `$field`: $location');
		var digest = (cast value : String).toLowerCase();
		if (!validDigest(digest))
			fail('Generated-output metadata has invalid `$field`: $location');
		return digest;
	}

	static function directoryEntryExists(directory:String, name:String):Bool {
		var entries = try FileSystem.readDirectory(directory) catch (error:Dynamic) {
			fail('Cannot inspect generated-output directory `$directory`: ${Std.string(error)}');
			[];
		};
		return entries.indexOf(name) >= 0;
	}

	static function generationDigest(records:Array<OwnedFileRecord>):String {
		var buffer = new StringBuf();
		for (record in records) {
			buffer.add(record.path);
			buffer.add("\n");
			buffer.add(record.digest);
			buffer.add("\n");
		}
		return Sha256.encode(buffer.toString()).toLowerCase();
	}

	// Macro-eval values can come from a separately loaded standard-library class
	// identity, making `Std.isOfType(value, Array/String)` return false even though
	// `Type.typeof` identifies the canonical runtime class.
	static function isArrayValue(value:Dynamic):Bool {
		return Std.string(Type.typeof(value)) == "TClass(Class<Array>)";
	}

	static function isStringValue(value:Dynamic):Bool {
		return Std.string(Type.typeof(value)) == "TClass(Class<String>)";
	}

	static function hashFile(path:String):String {
		return hashBytes(File.getBytes(path));
	}

	static function hashBytes(bytes:Bytes):String {
		return Sha256.make(bytes).toHex().toLowerCase();
	}

	static function validDigest(value:String):Bool {
		if (value == null || value.length != 64)
			return false;
		for (index in 0...value.length) {
			var code = value.charCodeAt(index);
			if (!((code >= "0".code && code <= "9".code) || (code >= "a".code && code <= "f".code)))
				return false;
		}
		return true;
	}

	static function stringSet(values:Array<String>):Map<String, Bool> {
		var result = new Map<String, Bool>();
		for (value in values)
			result.set(value, true);
		return result;
	}

	static function ensureDirectory(path:String):Void {
		if (path == null || path.length == 0)
			return;
		if (FileSystem.exists(path)) {
			if (!FileSystem.isDirectory(path))
				fail('Expected directory but found a file: $path');
			return;
		}
		FileSystem.createDirectory(path);
	}
	#end

	static function fail(message:String):Dynamic {
		#if eval
		return Context.error('[reflaxe.elixir] Generated output ownership: $message', Context.currentPos());
		#else
		throw '[reflaxe.elixir] Generated output ownership: $message';
		#end
	}
}
#end
