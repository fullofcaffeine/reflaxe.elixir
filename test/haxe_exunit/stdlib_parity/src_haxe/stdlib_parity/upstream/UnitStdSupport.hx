package stdlib_parity.upstream;

/** Minimal support types used by the unchanged official unitstd fixtures. */
class ClassWithToString {
	public function new() {}

	public function toString():String {
		return "ClassWithToString.toString()";
	}
}

class ClassWithToStringChild extends ClassWithToString {
	public function new() {
		super();
	}
}

class ClassWithToStringChild2 extends ClassWithToString {
	public function new() {
		super();
	}

	public override function toString():String {
		return "ClassWithToStringChild2.toString()";
	}
}

enum SomeEnum<T> {
	NoArguments;
	OneArgument(value:T);
}

enum EnumFlagTest {
	EA;
	EB;
	EC;
}

enum EnumFlagTest2 {
	EF_00;
	EF_01;
	EF_02;
	EF_03;
	EF_04;
	EF_05;
	EF_06;
	EF_07;
	EF_08;
	EF_09;
	EF_10;
	EF_11;
	EF_12;
	EF_13;
	EF_14;
	EF_15;
	EF_16;
	EF_17;
	EF_18;
	EF_19;
	EF_20;
	EF_21;
	EF_22;
	EF_23;
	EF_24;
	EF_25;
	EF_26;
	EF_27;
	EF_28;
	EF_29;
	EF_30;
	EF_31;
}
