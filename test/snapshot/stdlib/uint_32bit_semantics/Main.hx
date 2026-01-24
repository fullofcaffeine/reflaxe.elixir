class Main {
	static function assertThat(condition: Bool, message: String): Void {
		if (!condition) {
			throw message;
		}
	}

	static function main() {
		var allOnes: UInt = cast -1; // 0xFFFFFFFF

		var wrappedAdd: UInt = allOnes + 1;
		assertThat(wrappedAdd == 0, "UInt wrap-around add failed");

		var wrappedMul: UInt = allOnes * 2;
		assertThat((wrappedMul : Int) == -2, "UInt wrap-around mul failed");

		var shifted: UInt = allOnes >>> 1;
		assertThat(shifted == 0x7FFFFFFF, "UInt unsigned shift-right failed");

		assertThat(allOnes > 1, "UInt unsigned comparison failed (0xFFFFFFFF > 1)");
		assertThat(!(1 > allOnes), "UInt unsigned comparison failed (1 !> 0xFFFFFFFF)");

		var zero: UInt = 0;
		var notZero: UInt = ~zero;
		assertThat((notZero : Int) == -1, "UInt bitwise not failed (~0)");

		var ten: UInt = 10;
		var five: UInt = 5;
		assertThat(allOnes % ten == five, "UInt modulo failed (0xFFFFFFFF % 10 == 5)");
	}
}

