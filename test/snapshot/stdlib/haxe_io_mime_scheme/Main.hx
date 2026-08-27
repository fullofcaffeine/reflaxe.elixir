package;

import haxe.io.Encoding;
import haxe.io.Eof;
import haxe.io.Error;
import haxe.io.Mime;
import haxe.io.Scheme;

/**
 * Runtime contract for small haxe.io value types.
 *
 * Encoding, Eof, and Error must keep their constructor and exception
 * semantics. Mime and Scheme must erase to ordinary String values without
 * emitting target runtime modules.
 */
class Main {
	static function assertTrue(condition:Bool, message:String):Void {
		if (!condition) {
			throw message;
		}
	}

	static function testEncoding():Void {
		assertTrue(switch (Encoding.UTF8) {
			case UTF8: true;
			default: false;
		}, "Encoding.UTF8 changed constructor");

		assertTrue(switch (Encoding.RawNative) {
			case RawNative: true;
			default: false;
		}, "Encoding.RawNative changed constructor");
	}

	static function testEof():Void {
		var eof = new Eof();
		assertTrue(eof.toString() == "Eof", "Eof.toString() changed");

		try {
			throw eof;
		} catch (error:Eof) {
			assertTrue(error.toString() == "Eof", "Eof catch changed value");
		}
	}

	static function testError():Void {
		var simpleErrors = [Error.Blocked, Error.Overflow, Error.OutsideBounds];
		var matched = 0;
		for (error in simpleErrors) {
			switch (error) {
				case Blocked | Overflow | OutsideBounds:
					matched++;
				case Custom(_):
			}
		}
		assertTrue(matched == 3, "Error constructors changed");

		try {
			throw Error.Custom("io failure");
		} catch (error:Error) {
			switch (error) {
				case Custom(message):
					assertTrue(message == "io failure", "Error.Custom payload changed");
				default:
					assertTrue(false, "Error.Custom changed constructor");
			}
		}
	}

	static function testMimeAndScheme():Void {
		var mime:String = Mime.ApplicationJson;
		var customMime:Mime = "application/vnd.example+json";
		var customMimeText:String = customMime;
		var scheme:String = Scheme.Https;
		var customScheme:Scheme = "web+demo";
		var customSchemeText:String = customScheme;

		assertTrue(mime == "application/json", "Mime.ApplicationJson changed");
		assertTrue(customMimeText == "application/vnd.example+json", "Custom Mime conversion changed");
		assertTrue(scheme == "https", "Scheme.Https changed");
		assertTrue(customSchemeText == "web+demo", "Custom Scheme conversion changed");
	}

	static function main():Void {
		testEncoding();
		testEof();
		testError();
		testMimeAndScheme();
	}
}
