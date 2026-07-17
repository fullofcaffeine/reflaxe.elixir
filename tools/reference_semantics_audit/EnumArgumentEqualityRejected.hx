private enum EqualityArgumentEnum {
	Value(value:Int);
}

class EnumArgumentEqualityRejected {
	static function main():Void {
		trace(Value(1) == Value(1));
	}
}
