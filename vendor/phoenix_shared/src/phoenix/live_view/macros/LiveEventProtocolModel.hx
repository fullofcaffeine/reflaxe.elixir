package phoenix.live_view.macros;

#if macro
import haxe.crypto.Sha1;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Printer;
import haxe.macro.Type;

using haxe.macro.Tools;
using StringTools;

/**
 * Fully normalized description of one shared LiveView event protocol enum.
 */
typedef LiveEventProtocolData = {
	var enumPath:String;
	var enumModule:String;
	var enumPack:Array<String>;
	var enumName:String;
	var companionName:String;
	var events:Array<LiveEventData>;
	var manifest:String;
	var manifestHash:String;
}

/**
 * Normalized event constructor metadata used by later helper generators.
 */
typedef LiveEventData = {
	var constructorName:String;
	var eventName:String;
	var args:Array<LiveEventArgumentData>;
	var fields:Array<LiveEventFieldData>;
	var pos:Position;
}

/**
 * Normalized Haxe constructor/handler argument metadata.
 */
typedef LiveEventArgumentData = {
	var name:String;
	var typeName:String;
	var type:Type;
	var kind:LiveEventArgumentKind;
	var fields:Array<LiveEventFieldData>;
	var optional:Bool;
	var pos:Position;
}

/**
 * Normalized payload field metadata with both Haxe and wire names preserved.
 */
typedef LiveEventFieldData = {
	var name:String;
	var wireName:String;
	var typeName:String;
	var type:Type;
	var kind:LiveEventFieldKind;
	var optional:Bool;
	var pos:Position;
}

/**
 * Haxe-side payload argument shapes supported by the v1 generator.
 */
enum LiveEventArgumentKind {
	FieldArguments;
	TypedefPayload;
}

/**
 * Built-in payload field families the v1 generator can lower directly.
 */
enum LiveEventFieldKind {
	WireString;
	WireInt;
	WireBool;
	WireFloat;
	WireStringArray;
	WireIntArray;
	RawPayload;
	CustomCodec(codec:Expr, label:String);
	Unsupported(reason:String);
}

/**
 * Typed model builder for `@:liveEventProtocol` enum declarations.
 *
 * WHAT
 * - Normalizes a shared event enum into protocol, event, and payload-field
 *   records.
 *
 * WHY
 * - LiveView protocol generation needs one strongly typed intermediate model
 *   before it emits JS helpers, Elixir dispatch helpers, diagnostics, or
 *   manifest hashes. This mirrors the Tink-style declaration -> model ->
 *   generated surface pipeline without importing HTTP routing complexity.
 *
 * HOW
 * - Resolves the provided type expression to an enum.
 * - Reads `@:liveEventProtocol("CompanionName")` from the enum.
 * - Reads optional `@:event("wire_name")` metadata from constructors.
 * - Validates duplicate event names, duplicate payload wire keys, and
 *   unsupported payload field types.
 */
class LiveEventProtocolModel {
	/**
	 * Resolves and validates a protocol enum expression into the shared model.
	 */
	public static function fromTypeRef(protocolRef:Expr):LiveEventProtocolData {
		var typeName = expressionToTypeName(protocolRef);
		var protocolType = try {
			Context.getType(typeName);
		} catch (_:Any) {
			Context.error('Unable to resolve LiveView event protocol type "$typeName".', protocolRef.pos);
			null;
		}

		return fromType(protocolType, protocolRef.pos);
	}

	/**
	 * Normalizes an already resolved protocol enum type.
	 */
	public static function fromType(protocolType:Type, pos:Position):LiveEventProtocolData {
		return switch (protocolType.follow()) {
			case TEnum(enumRef, params):
				if (params.length > 0) {
					Context.error("LiveView event protocol enums cannot be generic in v1.", pos);
				}
				fromEnum(enumRef.get());
			case _:
				Context.error("LiveView event protocols must be enum declarations.", pos);
				null;
		};
	}

	static function fromEnum(enumType:EnumType):LiveEventProtocolData {
		var enumPath = typePath(enumType.pack, enumType.name);
		var protocolEntry = findMeta(enumType.meta.get(), ":liveEventProtocol");
		if (protocolEntry == null) {
			Context.error('${enumPath} must be marked with @:liveEventProtocol("GeneratedCompanionName").', enumType.pos);
		}

		var companionName = metadataStringParam(protocolEntry, 0);
		if (companionName == null || companionName.trim() == "") {
			companionName = defaultCompanionName(enumType.name);
		}

		var seenEvents = new Map<String, Position>();
		var eventNames = [for (name in enumType.constructs.keys()) name];
		eventNames.sort(Reflect.compare);

		var events:Array<LiveEventData> = [];
		for (constructorName in eventNames) {
			var constructor = enumType.constructs.get(constructorName);
			var eventName = readEventName(constructor);
			if (seenEvents.exists(eventName)) {
				Context.error('Duplicate LiveView event name "$eventName" in ${enumPath}.', constructor.pos);
			}
			seenEvents.set(eventName, constructor.pos);

			events.push({
				constructorName: constructorName,
				eventName: eventName,
				args: readArguments(enumPath, constructor),
				fields: [],
				pos: constructor.pos
			});
			events[events.length - 1].fields = flattenFields(events[events.length - 1].args);
		}

		var manifest = buildManifest(enumPath, companionName, events);
		return {
			enumPath: enumPath,
			enumModule: enumType.module,
			enumPack: enumType.pack,
			enumName: enumType.name,
			companionName: companionName,
			events: events,
			manifest: manifest,
			manifestHash: Sha1.encode(manifest)
		};
	}

	static function readEventName(constructor:EnumField):String {
		var entry = findMeta(constructor.meta.get(), ":event");
		if (entry != null) {
			var explicit = metadataStringParam(entry, 0);
			if (explicit == null || explicit.trim() == "") {
				Context.error("@:event expects a non-empty string literal.", entry.pos);
			}
			return explicit;
		}
		return camelToSnake(constructor.name);
	}

	static function readArguments(enumPath:String, constructor:EnumField):Array<LiveEventArgumentData> {
		return switch (constructor.type.follow()) {
			case TFun(args, _):
				var seenWireKeys = new Map<String, Position>();
				if (args.length == 1) {
					var typedefArg = buildTypedefPayloadArgument(enumPath, constructor, args[0], seenWireKeys);
					if (typedefArg != null) {
						return [typedefArg];
					}
				}
				[for (arg in args) buildFieldArgument(enumPath, constructor, arg, seenWireKeys)];
			case _:
				[];
		};
	}

	static function buildFieldArgument(enumPath:String, constructor:EnumField, arg:{name:String, opt:Bool, t:Type},
			seenWireKeys:Map<String, Position>):LiveEventArgumentData {
		var wireName = camelToSnake(arg.name);
		var field = buildField(enumPath, constructor.name, arg.name, wireName, arg.t, arg.opt, constructor.pos);
		registerWireKey(enumPath, constructor.name, field, seenWireKeys);
		return {
			name: arg.name,
			typeName: field.typeName,
			type: arg.t,
			kind: FieldArguments,
			fields: [field],
			optional: field.optional,
			pos: constructor.pos
		};
	}

	static function buildTypedefPayloadArgument(enumPath:String, constructor:EnumField, arg:{name:String, opt:Bool, t:Type},
			seenWireKeys:Map<String, Position>):Null<LiveEventArgumentData> {
		var payload = typedefPayloadFields(arg.t);
		if (payload == null) {
			return null;
		}

		var fields:Array<LiveEventFieldData> = [];
		var payloadFields = payload.fields.copy();
		payloadFields.sort((a, b) -> Reflect.compare(a.name, b.name));
		for (payloadField in payloadFields) {
			var wireName = readWireName(payloadField);
			var codec = readCodec(payloadField);
			var field = buildField(enumPath, constructor.name, payloadField.name, wireName, payloadField.type, fieldIsOptional(payloadField),
				payloadField.pos, codec);
			registerWireKey(enumPath, constructor.name, field, seenWireKeys);
			fields.push(field);
		}

		return {
			name: arg.name,
			typeName: payload.typeName,
			type: arg.t,
			kind: TypedefPayload,
			fields: fields,
			optional: arg.opt || payload.typeName.startsWith("Null<"),
			pos: constructor.pos
		};
	}

	static function typedefPayloadFields(type:Type):Null<{typeName:String, fields:Array<ClassField>}> {
		return switch (type) {
			case TType(typeRef, params):
				if (params.length > 0) {
					Context.error("LiveView event payload typedefs cannot be generic in v1.", typeRef.get().pos);
				}
				var typeDef = typeRef.get();
				switch (typeDef.type.follow()) {
					case TAnonymous(anonRef):
						{typeName: type.toString(), fields: anonRef.get().fields};
					case _:
						null;
				}
			case TLazy(resolve):
				typedefPayloadFields(resolve());
			case _:
				null;
		};
	}

	static function buildField(enumPath:String, constructorName:String, name:String, wireName:String, type:Type, optional:Bool,
			pos:Position, ?codec:Expr):LiveEventFieldData {
		var typeName = type.toString();
		if (isNullTypeName(typeName) && !optional) {
			var owner = enumPath == "" ? "LiveView event" : '${enumPath}.${constructorName}';
			Context.error('${owner} payload field "${name}" uses Null<T> without an explicit optional marker. Use an optional constructor argument or @:optional typedef field so nullable wire data is deliberate.',
				pos);
		}
		var field = {
			name: name,
			wireName: wireName,
			typeName: typeName,
			type: type,
			kind: codec == null ? classifyFieldType(typeName) : CustomCodec(codec, new Printer().printExpr(codec)),
			optional: optional,
			pos: pos
		};
		switch (field.kind) {
			case Unsupported(reason):
				var owner = enumPath == "" ? "LiveView event" : '${enumPath}.${constructorName}';
				Context.error('${owner} payload field "${name}" uses unsupported type ${field.typeName}. ${reason}', pos);
			case _:
		}
		return field;
	}

	static function classifyFieldType(typeName:String):LiveEventFieldKind {
		return switch (typeName) {
			case "String": WireString;
			case "Int": WireInt;
			case "Bool": WireBool;
			case "Float": WireFloat;
			case "Array<String>": WireStringArray;
			case "Array<Int>": WireIntArray;
			case "phoenix.channels.Payload" | "elixir.types.Term" | "js.lib.Object": RawPayload;
			case name if (name.startsWith("Null<") && name.endsWith(">")):
				classifyFieldType(name.substr(5, name.length - 6));
			case _:
				Unsupported("Use String, Int, Bool, Float, Array<String>, Array<Int>, Payload, or add an explicit codec in the generator layer.");
		};
	}

	static function isNullTypeName(typeName:String):Bool {
		return typeName.startsWith("Null<") && typeName.endsWith(">");
	}

	static function buildManifest(enumPath:String, companionName:String, events:Array<LiveEventData>):String {
		var buf = new StringBuf();
		buf.add('protocol ${enumPath}\n');
		buf.add('companion ${companionName}\n');
		for (event in events) {
			buf.add('event ${event.constructorName} ${event.eventName}');
			if (event.args.length == 0) {
				buf.add(' ()\n');
			} else {
				buf.add(' (${[for (arg in event.args) manifestArgument(arg)].join(", ")})\n');
			}
		}
		return buf.toString();
	}

	static function manifestArgument(arg:LiveEventArgumentData):String {
		return switch (arg.kind) {
			case FieldArguments:
				var field = arg.fields[0];
				'${arg.name}:${arg.typeName}->${field.wireName}:${kindName(field.kind)}${field.optional ? "?" : ""}';
			case TypedefPayload:
				var fields = [
					for (field in arg.fields)
						'${field.name}:${field.typeName}->${field.wireName}:${kindName(field.kind)}${field.optional ? "?" : ""}'
				];
				'${arg.name}:${arg.typeName}{${fields.join(";")}}${arg.optional ? "?" : ""}';
		};
	}

	static function kindName(kind:LiveEventFieldKind):String {
		return switch (kind) {
			case WireString: "string";
			case WireInt: "int";
			case WireBool: "bool";
			case WireFloat: "float";
			case WireStringArray: "string_array";
			case WireIntArray: "int_array";
			case RawPayload: "payload";
			case CustomCodec(_, label): 'codec:${label}';
			case Unsupported(_): "unsupported";
		};
	}

	static function metadataStringParam(entry:MetadataEntry, index:Int):Null<String> {
		if (entry.params == null || entry.params.length <= index) {
			return null;
		}
		return switch (entry.params[index].expr) {
			case EConst(CString(value, _)): value;
			case _:
				Context.error('${entry.name} expects a string literal parameter.', entry.params[index].pos);
				null;
		};
	}

	static function readWireName(field:ClassField):String {
		var entry = findMeta(field.meta.get(), ":wire");
		if (entry == null) {
			return camelToSnake(field.name);
		}
		var explicit = metadataStringParam(entry, 0);
		if (explicit == null || explicit.trim() == "") {
			Context.error("@:wire expects a non-empty string literal.", entry.pos);
		}
		return explicit;
	}

	static function readCodec(field:ClassField):Null<Expr> {
		var entry = findMeta(field.meta.get(), ":codec");
		if (entry == null) {
			return null;
		}
		if (entry.params == null || entry.params.length != 1) {
			Context.error("@:codec expects one expression returning phoenix.channels.WireCodec<T>.", entry.pos);
		}
		return entry.params[0];
	}

	static function fieldIsOptional(field:ClassField):Bool {
		return findMeta(field.meta.get(), ":optional") != null;
	}

	static function registerWireKey(enumPath:String, constructorName:String, field:LiveEventFieldData, seenWireKeys:Map<String, Position>):Void {
		if (seenWireKeys.exists(field.wireName)) {
			Context.error('LiveView event ${enumPath}.${constructorName} has duplicate payload wire key "${field.wireName}".', field.pos);
		}
		seenWireKeys.set(field.wireName, field.pos);
	}

	static function flattenFields(args:Array<LiveEventArgumentData>):Array<LiveEventFieldData> {
		var fields:Array<LiveEventFieldData> = [];
		for (arg in args) {
			for (field in arg.fields) {
				fields.push(field);
			}
		}
		return fields;
	}

	static function findMeta(entries:Metadata, name:String):Null<MetadataEntry> {
		for (entry in entries) {
			if (entry.name == name) {
				return entry;
			}
		}
		return null;
	}

	static function expressionToTypeName(expr:Expr):String {
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name;
			case EField(owner, field):
				expressionToTypeName(owner) + "." + field;
			case EParenthesis(inner):
				expressionToTypeName(inner);
			case _:
				Context.error("Expected LiveView event protocol enum type reference, for example ProfileHookEvent.", expr.pos);
				null;
		};
	}

	static function typePath(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}

	static function defaultCompanionName(enumName:String):String {
		return enumName.endsWith("Event") ? enumName.substr(0, enumName.length - "Event".length) + "Events" : enumName + "Events";
	}

	static function camelToSnake(name:String):String {
		var out = new StringBuf();
		for (i in 0...name.length) {
			var ch = name.charAt(i);
			var isUpper = ch >= "A" && ch <= "Z";
			if (isUpper && i > 0) {
				out.add("_");
			}
			out.add(ch.toLowerCase());
		}
		return out.toString();
	}
}
#end
