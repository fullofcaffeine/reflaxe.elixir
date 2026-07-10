package;

import haxe.io.Bytes;
import haxe.io.Float32Array;
import haxe.io.UInt8Array;

/**
 * Snapshot: official typed-array fallback over the Elixir Bytes runtime.
 *
 * This locks two compiler contracts used by the upstream implementation:
 * multi-expression abstract constructors bind their final value, and omitted
 * defaulted arguments use the typed Haxe default instead of nil.
 */
class Main {
	static function main() {
		var floats = new Float32Array(2);
		floats[0] = 1.25;
		if (floats[0] != 1.25) {
			throw "Float32Array write failed";
		}

		var bytes = Bytes.alloc(2);
		var octets = UInt8Array.fromBytes(bytes);
		octets[0] = 55;
		if (bytes.get(0) != 55) {
			throw "UInt8Array shared write failed";
		}
	}
}
