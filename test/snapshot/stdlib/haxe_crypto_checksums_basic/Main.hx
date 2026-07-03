import haxe.crypto.Adler32;
import haxe.crypto.Crc32;
import haxe.io.Bytes;
import haxe.io.BytesInput;

class Main {
	static function assertThat(condition:Bool, message:String):Void {
		if (!condition)
			throw message;
	}

	static function main():Void {
		assertThat(Crc32.make(Bytes.ofString("")) == 0, "crc32 empty failed");
		assertThat(Crc32.make(Bytes.ofString("abc")) == 891568578, "crc32 abc failed");

		var crc = new Crc32();
		var prefix = Bytes.ofString("ab");
		crc.update(prefix, 0, prefix.length);
		crc.byte("c".code);
		assertThat(crc.get() == 891568578, "crc32 incremental failed");

		var highCrc = Bytes.alloc(1);
		highCrc.set(0, 0);
		assertThat(Crc32.make(highCrc) == -771559539, "crc32 signed int failed");

		assertThat(Adler32.make(Bytes.ofString("")) == 1, "adler32 empty failed");
		assertThat(Adler32.make(Bytes.ofString("abc")) == 38600999, "adler32 abc failed");

		var adler = new Adler32();
		adler.update(prefix, 0, prefix.length);
		var suffix = Bytes.ofString("c");
		adler.update(suffix, 0, suffix.length);
		assertThat(adler.get() == 38600999, "adler32 incremental failed");
		assertThat(adler.toString() == "0000024D00000127", "adler32 toString failed");

		var read = Adler32.read(new BytesInput(Bytes.ofHex("024d0127")));
		assertThat(read.equals(adler), "adler32 read/equals failed");

		var highAdler = Bytes.alloc(16);
		for (i in 0...highAdler.length)
			highAdler.set(i, 255);
		assertThat(Adler32.make(highAdler) == -2021126159, "adler32 signed int failed");
	}
}
