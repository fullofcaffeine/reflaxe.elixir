private class EqualityBox {
	public var value:Int;

	public function new(value:Int) {
		this.value = value;
	}

	public function read():Int {
		return value;
	}
}

private enum EqualityEnvelope {
	Empty;
	Scalar(value:Int);
	Object(value:EqualityBox);
}

class EqualityMatrix {
	static function main():Void {
		final box = new EqualityBox(1);
		final otherBox = new EqualityBox(1);
		final record = {value: 1};
		final array = [1];
		final scalarEnum = Scalar(1);
		final objectEnum = Object(box);
		final date = Date.fromTime(0);
		final dynamicBox:Dynamic = box;
		final dynamicScalarEnum:Dynamic = scalarEnum;

		final observations = {
			classAlias: box == box,
			classSeparateEqualFields: box == otherBox,
			dynamicClassAlias: dynamicBox == box,
			dynamicClassSeparateEqualFields: dynamicBox == otherBox,
			anonymousAlias: record == record,
			anonymousSeparateEqualFields: record == {
				value: 1
			},
			arrayAlias: array == array,
			arraySeparateEqualElements: array == [1],
			enumNullarySeparate: Empty == Empty,
			typeEnumEqScalar: Type.enumEq(scalarEnum, Scalar(1)),
			typeEnumEqObjectAliasPayload: Type.enumEq(objectEnum, Object(box)),
			typeEnumEqObjectSeparatePayload: Type.enumEq(objectEnum, Object(otherBox)),
			enumValueToolsDeepScalar: haxe.EnumTools.EnumValueTools.equals(scalarEnum, Scalar(1)),
			enumValueToolsDeepObject: haxe.EnumTools.EnumValueTools.equals(objectEnum, Object(otherBox)),
			dynamicEnumScalarSeparate: dynamicScalarEnum == cast Scalar(1),
			dateAlias: date == date,
			dateSeparateSameTimestamp: date == Date.fromTime(0),
			boundMethodSameReceiver: Reflect.compareMethods(box.read, box.read),
			boundMethodSeparateReceiver: Reflect.compareMethods(box.read, otherBox.read)
		};

		trace('equality-matrix:${haxe.Json.stringify(observations)}');
	}
}
