## API Quick Reference (Auto-Generated)

### Module: haxe.io.Error

#### Error (enum)

	The possible IO errors that can occur


### Module: haxe.io.Encoding

#### Encoding (enum)

	String binary encoding supported by Haxe I/O


### Module: haxe.io.BytesData

#### BytesData (typedef)

### Module: haxe.ds.StringMap

#### StringMap (class)

	StringMap allows mapping of String keys to arbitrary values.

	See `Map` for documentation details.

	@see https://haxe.org/manual/std-Map.html

**Instance Methods:**
- `set(key:String, value:T):Void`
- `get(key:String):Null`
- `exists(key:String):Bool`
- `remove(key:String):Bool`
- `keys():Iterator`
- `iterator():Iterator`
- `keyValueIterator():KeyValueIterator`
- `copy():StringMap`
- `toString():String`
- `clear():Void`

### Module: haxe.ds.ReadOnlyArray

#### ReadOnlyArray (abstract)

	`ReadOnlyArray` is an abstract over an ordinary `Array` which only exposes
	APIs that don't modify the instance, hence "read-only".

	Note that this doesn't necessarily mean that the instance is *immutable*.
	Other code holding a reference to the underlying `Array` can still modify it,
	and the reference can be obtained with a `cast`.


### Module: haxe.ds.ObjectMap

#### ObjectMap (class)

	ObjectMap allows mapping of object keys to arbitrary values.

	On static targets, the keys are considered to be strong references. Refer
	to `haxe.ds.WeakMap` for a weak reference version.

	See `Map` for documentation details.

	@see https://haxe.org/manual/std-Map.html

**Instance Methods:**
- `set(key:K, value:V):Void`
- `get(key:K):Null`
- `exists(key:K):Bool`
- `remove(key:K):Bool`
- `keys():Iterator`
- `iterator():Iterator`
- `keyValueIterator():KeyValueIterator`
- `copy():ObjectMap`
- `toString():String`
- `clear():Void`

### Module: haxe.ds.Map

#### Map (abstract)

	Map allows key to value mapping for arbitrary value types, and many key
	types.

	This is a multi-type abstract, it is instantiated as one of its
	specialization types depending on its type parameters.

	A Map can be instantiated without explicit type parameters. Type inference
	will then determine the type parameters from the usage.

	Maps can also be created with `[key1 => value1, key2 => value2]` syntax.

	Map is an abstract type, it is not available at runtime.

	@see https://haxe.org/manual/std-Map.html


### Module: haxe.ds.IntMap

#### IntMap (class)

	IntMap allows mapping of Int keys to arbitrary values.

	See `Map` for documentation details.

	@see https://haxe.org/manual/std-Map.html

**Instance Methods:**
- `set(key:Int, value:T):Void`
- `get(key:Int):Null`
- `exists(key:Int):Bool`
- `remove(key:Int):Bool`
- `keys():Iterator`
- `iterator():Iterator`
- `keyValueIterator():KeyValueIterator`
- `copy():IntMap`
- `toString():String`
- `clear():Void`

### Module: haxe.PosInfos

#### PosInfos (typedef)

	`PosInfos` is a magic type which can be used to generate position information
	into the output for debugging use.

	If a function has a final optional argument of this type, i.e.
	`(..., ?pos:haxe.PosInfos)`, each call to that function which does not assign
	a value to that argument has its position added as call argument.

	This can be used to track positions of calls in e.g. a unit testing
	framework.


### Module: haxe.NativeStackTrace

#### NativeStackTrace (class)

	Do not use manually.

**Static Methods:**
- `saveStack(exception:Any):Void`
- `callStack():Any`
- `exceptionStack():Any`
- `toHaxe(nativeStackTrace:Any, ?skip:Int):Array`

### Module: haxe.Int64

#### Int64 (abstract)

	A cross-platform signed 64-bit integer.
	Int64 instances can be created from two 32-bit words using `Int64.make()`.


#### __Int64 (typedef)

	This typedef will fool `@:coreApi` into thinking that we are using
	the same underlying type, even though it might be different on
	specific platforms.


### Module: haxe.Int32

#### Int32 (abstract)

	Int32 provides a 32-bit integer with consistent overflow behavior across
	all platforms.


### Module: haxe.Exception

#### Exception (class)

	Base class for exceptions.

	If this class (or derivatives) is used to catch an exception, then
	`haxe.CallStack.exceptionStack()` will not return a stack for the exception
	caught. Use `haxe.Exception.stack` property instead:
	```haxe
	try {
		throwSomething();
	} catch(e:Exception) {
		trace(e.stack);
	}
	```

	Custom exceptions should extend this class:
	```haxe
	class MyException extends haxe.Exception {}
	//...
	throw new MyException('terrible exception');
	```

	`haxe.Exception` is also a wildcard type to catch any exception:
	```haxe
	try {
		throw 'Catch me!';
	} catch(e:haxe.Exception) {
		trace(e.message); // Output: Catch me!
	}
	```

	To rethrow an exception just throw it again.
	Haxe will try to rethrow an original native exception whenever possible.
	```haxe
	try {
		var a:Array<Int> = null;
		a.push(1); // generates target-specific null-pointer exception
	} catch(e:haxe.Exception) {
		throw e; // rethrows native exception instead of haxe.Exception
	}
	```

**Instance Methods:**
- `toString():String`
- `details():String`

### Module: haxe.EnumTools

#### EnumTools (class)

	This class provides advanced methods on enums. It is ideally used with
	`using EnumTools` and then acts as an
	  [extension](https://haxe.org/manual/lf-static-extension.html) to the
	  `enum` types.

	If the first argument to any of the methods is `null`, the result is
	unspecified.

**Static Methods:**
- `getName(e:Enum):String`
- `createByName(e:Enum, constr:String, ?params:Null):T`
- `createByIndex(e:Enum, index:Int, ?params:Null):T`
- `createAll(e:Enum):Array`
- `getConstructors(e:Enum):Array`

#### EnumValueTools (class)

	This class provides advanced methods on enum values. It is ideally used with
	`using EnumValueTools` and then acts as an
	  [extension](https://haxe.org/manual/lf-static-extension.html) to the
	  `EnumValue` types.

	If the first argument to any of the methods is `null`, the result is
	unspecified.

**Static Methods:**
- `equals(a:T, b:T):Bool`
- `getName(e:EnumValue):String`
- `getParameters(e:EnumValue):Array`
- `getIndex(e:EnumValue):Int`

### Module: haxe.Constraints

#### Constructible (abstract)

	This type unifies with any instance of classes that have a constructor
	which

	  * is `public` and
	  * unifies with the type used for type parameter `T`.

	If a type parameter `A` is assigned to a type parameter `B` which is constrained
	to `Constructible<T>`, A must be explicitly constrained to
	`Constructible<T>` as well.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


#### FlatEnum (abstract)

	This type unifies with an enum instance if all constructors of the enum
	require no arguments.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


#### Function (abstract)

	This type unifies with any function type.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


#### NotVoid (abstract)

	This type unifies with anything but `Void`.

	It is intended to be used as a type parameter constraint. If used as a real
	type, the underlying type will be `Dynamic`.


### Module: haxe.CallStack

#### CallStack (abstract)

	Get information about the call stack.


#### StackItem (enum)

	Elements return by `CallStack` methods.


### Module: Type

#### Type (class)

	The Haxe Reflection API allows retrieval of type information at runtime.

	This class complements the more lightweight Reflect class, with a focus on
	class and enum instances.

	@see https://haxe.org/manual/types.html
	@see https://haxe.org/manual/std-reflection.html

**Static Methods:**
- `getClass(o:T):Class`
- `getEnum(o:EnumValue):Enum`
- `getSuperClass(c:Class):Class`
- `getClassName(c:Class):String`
- `getEnumName(e:Enum):String`
- `resolveClass(name:String):Class`
- `resolveEnum(name:String):Enum`
- `createInstance(cl:Class, args:Array):T`
- `createEmptyInstance(cl:Class):T`
- `createEnum(e:Enum, constr:String, ?params:Null):T`
- `createEnumIndex(e:Enum, index:Int, ?params:Null):T`
- `getInstanceFields(c:Class):Array`
- `getClassFields(c:Class):Array`
- `getEnumConstructs(e:Enum):Array`
- `typeof(v:Dynamic):ValueType`
- `enumEq(a:T, b:T):Bool`
- `enumConstructor(e:EnumValue):String`
- `enumParameters(e:EnumValue):Array`
- `enumIndex(e:EnumValue):Int`
- `allEnums(e:Enum):Array`

#### ValueType (enum)

	The different possible runtime types of a value.


### Module: Sys

#### Sys (class)

	This class provides access to various base functions of system platforms.
	Look in the `sys` package for more system APIs.

**Static Methods:**
- `print(v:Dynamic):Void`
- `println(v:Dynamic):Void`
- `args():Array`
- `getEnv(s:String):String`
- `putEnv(s:String, v:Null):Void`
- `environment():Map`
- `sleep(seconds:Float):Void`
- `setTimeLocale(loc:String):Bool`
- `getCwd():String`
- `setCwd(s:String):Void`
- `systemName():String`
- `command(cmd:String, ?args:Null):Int`
- `exit(code:Int):Void`
- `time():Float`
- `cpuTime():Float`
- `executablePath():String`
- `programPath():String`
- `getChar(echo:Bool):Int`
- `stdin():Input`
- `stdout():Output`
- `stderr():Output`

### Module: String

#### String (class)

	The basic String class.

	A Haxe String is immutable, it is not possible to modify individual
	characters. No method of this class changes the state of `this` String.

	Strings can be constructed using the String literal syntax `"string value"`.

	String can be concatenated by using the `+` operator. If an operand is not a
	String, it is passed through `Std.string()` first.

	@see https://haxe.org/manual/std-String.html

**Instance Methods:**
- `toUpperCase():String`
- `toLowerCase():String`
- `charAt(index:Int):String`
- `charCodeAt(index:Int):Null`
- `indexOf(str:String, ?startIndex:Null):Int`
- `lastIndexOf(str:String, ?startIndex:Null):Int`
- `split(delimiter:String):Array`
- `substr(pos:Int, ?len:Null):String`
- `substring(startIndex:Int, ?endIndex:Null):String`
- `toString():String`
**Static Methods:**
- `fromCharCode(code:Int):String`

### Module: StdTypes

#### ArrayAccess (class)

	`ArrayAccess` is used to indicate a class that can be accessed using brackets.
	The type parameter represents the type of the elements stored.

	This interface should be used for externs only. Haxe does not support custom
	array access on classes. However, array access can be implemented for
	abstract types.

	@see https://haxe.org/manual/types-abstract-array-access.html


#### Bool (abstract)

	The standard Boolean type, which can either be `true` or `false`.

	On static targets, `null` cannot be assigned to `Bool`. If this is necessary,
	`Null<Bool>` can be used instead.

	@see https://haxe.org/manual/types-bool.html
	@see https://haxe.org/manual/types-nullability.html


#### Dynamic (abstract)

	`Dynamic` is a special type which is compatible with all other types.

	Use of `Dynamic` should be minimized as it prevents several compiler
	checks and optimizations. See `Any` type for a safer alternative for
	representing values of any type.

	@see https://haxe.org/manual/types-dynamic.html


#### Float (abstract)

	The standard `Float` type, this is a double-precision IEEE 64bit float.

	On static targets, `null` cannot be assigned to Float. If this is necessary,
	`Null<Float>` can be used instead.

	`Std.int` converts a `Float` to an `Int`, rounded towards 0.
	`Std.parseFloat` converts a `String` to a `Float`.

	@see https://haxe.org/manual/types-basic-types.html
	@see https://haxe.org/manual/types-nullability.html


#### Int (abstract)

	The standard `Int` type. Its precision depends on the platform.

	On static targets, `null` cannot be assigned to `Int`. If this is necessary,
	`Null<Int>` can be used instead.

	`Std.int` converts a `Float` to an `Int`, rounded towards 0.
	`Std.parseInt` converts a `String` to an `Int`.

	@see https://haxe.org/manual/types-basic-types.html
	@see https://haxe.org/manual/std-math-integer-math.html
	@see https://haxe.org/manual/types-nullability.html


#### Iterable (typedef)

	An `Iterable` is a data structure which has an `iterator()` method.
	See `Lambda` for generic functions on iterable structures.

	@see https://haxe.org/manual/lf-iterators.html


#### Iterator (typedef)

	An `Iterator` is a structure that permits iteration over elements of type `T`.

	Any class with matching `hasNext()` and `next()` fields is considered an `Iterator`
	and can then be used e.g. in `for`-loops. This makes it easy to implement
	custom iterators.

	@see https://haxe.org/manual/lf-iterators.html


#### KeyValueIterable (typedef)

	A `KeyValueIterable` is a data structure which has a `keyValueIterator()`
	method to iterate over key-value-pairs.


#### KeyValueIterator (typedef)

	A `KeyValueIterator` is an `Iterator` that has a key and a value.


#### Null (abstract)

	`Null<T>` is a wrapper that can be used to make the basic types `Int`,
	`Float` and `Bool` nullable on static targets.

	If null safety is enabled, only types wrapped in `Null<T>` are nullable.

	Otherwise, it has no effect on non-basic-types, but it can be useful as a way to document
	that `null` is an acceptable value for a method argument, return value or variable.

	@see https://haxe.org/manual/types-nullability.html


#### Void (abstract)

	The standard `Void` type. Only `null` values can be of the type `Void`.

	@see https://haxe.org/manual/types-void.html


### Module: Std

#### Std (class)

	The Std class provides standard methods for manipulating basic types.

**Static Methods:**
- `is(v:Dynamic, t:Dynamic):Bool`
- `isOfType(v:Dynamic, t:Dynamic):Bool`
- `downcast(value:T, c:Class):S`
- `instance(value:T, c:Class):S`
- `string(s:Dynamic):String`
- `int(x:Float):Int`
- `parseInt(x:String):Null`
- `parseFloat(x:String):Float`
- `random(x:Int):Int`

### Module: Reflect

#### Reflect (class)

	The Reflect API is a way to manipulate values dynamically through an
	abstract interface in an untyped manner. Use with care.

	@see https://haxe.org/manual/std-reflection.html

**Static Methods:**
- `hasField(o:Dynamic, field:String):Bool`
- `field(o:Dynamic, field:String):Dynamic`
- `setField(o:Dynamic, field:String, value:Dynamic):Void`
- `getProperty(o:Dynamic, field:String):Dynamic`
- `setProperty(o:Dynamic, field:String, value:Dynamic):Void`
- `callMethod(o:Dynamic, func:Function, args:Array):Dynamic`
- `fields(o:Dynamic):Array`
- `isFunction(f:Dynamic):Bool`
- `compare(a:T, b:T):Int`
- `compareMethods(f1:Dynamic, f2:Dynamic):Bool`
- `isObject(v:Dynamic):Bool`
- `isEnumValue(v:Dynamic):Bool`
- `deleteField(o:Dynamic, field:String):Bool`
- `copy(o:Null):Null`
- `makeVarArgs(f:(:Array) -> Dynamic):Dynamic`

### Module: Math

#### Math (class)

	This class defines mathematical functions and constants.

	@see https://haxe.org/manual/std-math.html

**Static Methods:**
- `abs(v:Float):Float`
- `min(a:Float, b:Float):Float`
- `max(a:Float, b:Float):Float`
- `sin(v:Float):Float`
- `cos(v:Float):Float`
- `tan(v:Float):Float`
- `asin(v:Float):Float`
- `acos(v:Float):Float`
- `atan(v:Float):Float`
- `atan2(y:Float, x:Float):Float`
- `exp(v:Float):Float`
- `log(v:Float):Float`
- `pow(v:Float, exp:Float):Float`
- `sqrt(v:Float):Float`
- `round(v:Float):Int`
- `floor(v:Float):Int`
- `ceil(v:Float):Int`
- `random():Float`
- `ffloor(v:Float):Float`
- `fceil(v:Float):Float`
- `fround(v:Float):Float`
- `isFinite(f:Float):Bool`
- `isNaN(f:Float):Bool`

### Module: Map

#### IMap (typedef)

#### Map (typedef)

### Module: EnumValue

#### EnumValue (abstract)

	An abstract type that represents any enum value.
	See `Type` for the Haxe Reflection API.

	@see https://haxe.org/manual/types-enum-instance.html


### Module: Enum

#### Enum (abstract)

	An abstract type that represents an Enum type.

	The corresponding enum instance type is `EnumValue`.

	See `Type` for the Haxe Reflection API.

	@see https://haxe.org/manual/types-enum-instance.html


### Module: Class

#### Class (abstract)

	An abstract type that represents a Class.

	See `Type` for the Haxe Reflection API.

	@see https://haxe.org/manual/types-class-instance.html


### Module: Array

#### Array (class)

	An Array is a storage for values. You can access it using indexes or
	with its API.

	@see https://haxe.org/manual/std-Array.html
	@see https://haxe.org/manual/lf-array-comprehension.html

**Instance Methods:**
- `concat(a:Array):Array`
- `join(sep:String):String`
- `pop():Null`
- `push(x:T):Int`
- `reverse():Void`
- `shift():Null`
- `slice(pos:Int, ?end:Null):Array`
- `sort(f:(:T, :T) -> Int):Void`
- `splice(pos:Int, len:Int):Array`
- `toString():String`
- `unshift(x:T):Void`
- `insert(pos:Int, x:T):Void`
- `remove(x:T):Bool`
- `contains(x:T):Bool`
- `indexOf(x:T, ?fromIndex:Null):Int`
- `lastIndexOf(x:T, ?fromIndex:Null):Int`
- `copy():Array`
- `iterator():ArrayIterator`
- `keyValueIterator():ArrayKeyValueIterator`
- `map(f:(:T) -> S):Array`
- `filter(f:(:T) -> Bool):Array`
- `resize(len:Int):Void`

### Module: Any

#### Any (abstract)

	`Any` is a type that is compatible with any other in both ways.

	This means that a value of any type can be assigned to `Any`, and
	vice-versa, a value of `Any` type can be assigned to any other type.

	It's a more type-safe alternative to `Dynamic`, because it doesn't
	support field access or operators and it's bound to monomorphs. So,
	to work with the actual value, it needs to be explicitly promoted
	to another type.


