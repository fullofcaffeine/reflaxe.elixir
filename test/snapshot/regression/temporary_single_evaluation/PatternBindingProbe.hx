/** Unreachable array cases must not leave undefined local reads in native output. */
class PatternBindingProbe {
	static function classify():String {
		var packet = [255, 254, 4, 0, 72, 101, 108, 108, 111];
		return switch (packet) {
			case [255, 254, length, version] if (version == 0 && packet.length >= 4): 'packet:$length';
			case [255, 254, length, version] if (version > 0): 'future:$version:$length';
			case [255, other, rest] if (other != 254): 'invalid:$other:$rest';
			case header if (header.length < 4): "short";
			default: "other";
		};
	}

	public static function main():Void {
		if (classify() != "other")
			throw "Exact-length array patterns changed";
	}
}
