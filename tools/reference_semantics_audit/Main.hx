import haxe.crypto.Adler32;
import haxe.crypto.Crc32;
import haxe.ds.BalancedTree;
import haxe.ds.GenericStack;
import haxe.ds.HashMap;
import haxe.ds.List;
import haxe.ds.ObjectMap;
import haxe.ds.Vector;
import haxe.io.Bytes;
import haxe.io.BytesBuffer;
import haxe.io.UInt8Array;

private typedef MutableRecord = {
	var value:Int;
}

private enum AuditMapKey {
	First;
	Second;
}

private class AuditBox {
	public var value:Int;

	public function new(value:Int) {
		this.value = value;
	}

	public function read():Int {
		return value;
	}
}

private class AuditHashKey {
	final hash:Int;

	public function new(hash:Int) {
		this.hash = hash;
	}

	public function hashCode():Int {
		return hash;
	}
}

class Main {
	static function check(label:String, condition:Bool):Void {
		if (!condition) {
			throw 'reference-semantics audit failed: $label';
		}
	}

	static function main():Void {
		classAndAnonymousAliases();
		arrayAliases();
		mapAliasesAndCopies();
		linkedCollectionAliases();
		byteAndVectorAliases();
		bufferAndChecksumAliases();
		statefulRuntimeAliases();
		identityAndReflection();

		trace("reference-semantics audit passed");
	}

	static function classAndAnonymousAliases():Void {
		final box = new AuditBox(1);
		final boxAlias = box;
		box.value = 2;
		check("class field write is visible through an alias", boxAlias.value == 2);

		final record:MutableRecord = {value: 1};
		final recordAlias = record;
		record.value = 2;
		check("anonymous-object field write is visible through an alias", recordAlias.value == 2);
	}

	static function arrayAliases():Void {
		final values = [1];
		final alias = values;
		values.push(2);
		values[0] = 3;
		check("Array.push mutates the shared array", alias.length == 2 && alias[1] == 2);
		check("Array indexed assignment mutates the shared array", alias[0] == 3);

		alias.reverse();
		check("Array.reverse mutates the shared array", values[0] == 2 && values[1] == 3);
	}

	static function mapAliasesAndCopies():Void {
		final strings:Map<String, Int> = [];
		final stringsAlias = strings;
		strings.set("answer", 42);
		check("String-key Map.set mutates the shared map", stringsAlias.get("answer") == 42);

		final stringsCopy = strings.copy();
		stringsCopy.set("copy-only", 1);
		check("Map.copy creates an independently mutable map", !strings.exists("copy-only"));

		final integers:Map<Int, String> = [];
		final integersAlias = integers;
		integers.set(7, "seven");
		check("Int-key Map.set mutates the shared map", integersAlias.get(7) == "seven");

		final enums:Map<AuditMapKey, Int> = [];
		final enumsAlias = enums;
		enums.set(First, 1);
		check("enum-key Map.set mutates the shared map", enumsAlias.get(First) == 1);

		final tree = new BalancedTree<Int, String>();
		final treeAlias = tree;
		tree.set(1, "one");
		check("BalancedTree.set mutates the shared tree", treeAlias.get(1) == "one");

		final treeCopy = tree.copy();
		treeCopy.set(2, "two");
		check("BalancedTree.copy creates an independently mutable tree", !tree.exists(2));

		final hash = new HashMap<AuditHashKey, String>();
		final hashAlias = hash;
		final key = new AuditHashKey(1);
		hash.set(key, "one");
		check("HashMap.set mutates the shared map", hashAlias.get(key) == "one");

		final hashCopy = hash.copy();
		final copyKey = new AuditHashKey(2);
		hashCopy.set(copyKey, "copy-only");
		check("HashMap.copy creates an independently mutable map", !hash.exists(copyKey));
	}

	static function linkedCollectionAliases():Void {
		final list = new List<Int>();
		final listAlias = list;
		list.add(1);
		list.push(0);
		check("List mutations are visible through an alias", listAlias.length == 2 && listAlias.first() == 0);

		final stack = new GenericStack<Int>();
		final stackAlias = stack;
		stack.add(1);
		stack.add(2);
		check("GenericStack mutations are visible through an alias", stackAlias.first() == 2);
		check("GenericStack.pop mutates the shared stack", stack.pop() == 2 && stackAlias.first() == 1);
	}

	static function byteAndVectorAliases():Void {
		final bytes = Bytes.alloc(3);
		final bytesAlias = bytes;
		bytes.set(1, 7);
		check("Bytes.set mutates shared storage", bytesAlias.get(1) == 7);

		final view = UInt8Array.fromBytes(bytes);
		final subview = view.subarray(1, 2);
		subview[0] = 9;
		check("typed byte views share their source Bytes storage", bytesAlias.get(1) == 9 && view[1] == 9);

		final vector = new Vector<Int>(2, 0);
		final vectorAlias = vector;
		vector[0] = 4;
		check("Vector indexed assignment mutates shared storage", vectorAlias[0] == 4);

		final vectorCopy = vector.copy();
		vectorCopy[0] = 8;
		check("Vector.copy creates independent storage", vector[0] == 4 && vectorCopy[0] == 8);
	}

	static function bufferAndChecksumAliases():Void {
		final text = new StringBuf();
		final textAlias = text;
		text.add("a");
		text.addChar("b".code);
		check("StringBuf additions are visible through an alias", textAlias.toString() == "ab");

		final binary = new BytesBuffer();
		final binaryAlias = binary;
		binary.addByte(1);
		binary.addString("ab");
		check("BytesBuffer additions are visible through an alias", binaryAlias.length == 3);

		final payload = Bytes.ofString("abc");
		final crc = new Crc32();
		final crcAlias = crc;
		crc.update(payload, 0, payload.length);
		check("Crc32.update mutates shared checksum state", crcAlias.get() == Crc32.make(payload));

		final adler = new Adler32();
		final adlerAlias = adler;
		adler.update(payload, 0, payload.length);
		check("Adler32.update mutates shared checksum state", adlerAlias.get() == Adler32.make(payload));
	}

	static function statefulRuntimeAliases():Void {
		final matcher = ~/([a-z]+)/;
		final matcherAlias = matcher;
		check("EReg.match succeeds", matcher.match("abc"));
		check("EReg match state is visible through an alias", matcherAlias.matched(1) == "abc");

		final root = Xml.createElement("root");
		final rootAlias = root;
		root.set("answer", "42");
		final child = Xml.createElement("child");
		root.addChild(child);
		check("Xml attribute mutation is visible through an alias", rootAlias.get("answer") == "42");
		check("Xml child mutation is visible through an alias", rootAlias.firstChild() == child && child.parent == root);

		final iterator = [1, 2].iterator();
		final iteratorAlias = iterator;
		check("iterator cursor advances through its aliases", iterator.next() == 1 && iteratorAlias.next() == 2);
	}

	static function identityAndReflection():Void {
		final first = new AuditBox(1);
		final firstAlias = first;
		final second = new AuditBox(1);
		check("one class allocation compares equal to its alias", first == firstAlias);
		check("separate equal-looking class allocations are distinct", first != second);

		final objectMap = new ObjectMap<AuditBox, String>();
		objectMap.set(first, "first");
		objectMap.set(second, "second");
		first.value = 2;
		check("ObjectMap keys use allocation identity", objectMap.get(first) == "first" && objectMap.get(second) == "second");

		final record:Dynamic = {value: 1, child: first};
		final recordCopy:Dynamic = Reflect.copy(record);
		Reflect.setField(recordCopy, "value", 2);
		check("Reflect.copy creates a new outer object", Reflect.field(record, "value") == 1 && Reflect.field(recordCopy, "value") == 2);
		check("Reflect.copy is shallow", Reflect.field(recordCopy, "child") == first);

		check("bound methods retain receiver identity", Reflect.compareMethods(first.read, first.read));
		check("bound methods from distinct receivers remain distinct", !Reflect.compareMethods(first.read, second.read));
	}
}
