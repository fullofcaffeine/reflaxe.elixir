package;

import haxe.io.Bytes;
import haxe.io.Encoding;

class Main {
	static function main() {
		testIteration();
		testKeyValueIteration();
		testValidateUtf8();
	}

	static function testIteration() {
		var text:UnicodeString = "Aé🌍中";
		expect("unicode length", text.length == 4);

		var codes:Array<Int> = [];
		for (code in text) {
			codes.push(code);
		}

		expect("codepoint count", codes.length == 4);
		expect("ascii codepoint", codes[0] == 65);
		expect("latin codepoint", codes[1] == 233);
		expect("astral codepoint", codes[2] == 0x1F30D);
		expect("cjk codepoint", codes[3] == 0x4E2D);
	}

	static function testKeyValueIteration() {
		var text:UnicodeString = "a🌍b";
		var entries:Array<String> = [];
		for (index => code in text) {
			entries.push(index + ":" + code);
		}

		expect("key value count", entries.length == 3);
		expect("key value ascii", entries[0] == "0:97");
		expect("key value astral", entries[1] == "1:127757");
		expect("key value trailing", entries[2] == "2:98");
	}

	static function testValidateUtf8() {
		var valid = Bytes.ofString("Aé🌍中", UTF8);
		expect("valid utf8", UnicodeString.validate(valid, UTF8));

		var invalid:Bytes = cast untyped __elixir__('%{__reflaxe_class__: Bytes, length: 1, b: <<0xC0>>}');
		expect("invalid utf8", !UnicodeString.validate(invalid, UTF8));
	}

	static function expect(label:String, condition:Bool):Void {
		untyped __elixir__('if not ({1}), do: raise("UnicodeString assertion failed: " <> {0})', label, condition);
	}
}
