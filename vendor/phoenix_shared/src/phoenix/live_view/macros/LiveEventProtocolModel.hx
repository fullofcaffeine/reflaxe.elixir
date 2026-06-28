package phoenix.live_view.macros;

#if macro
import haxe.crypto.Sha1;
import haxe.macro.Context;
import haxe.macro.Expr;
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
	var fields:Array<LiveEventFieldData>;
	var pos:Position;
}

/**
 * Normalized payload field metadata with both Haxe and wire names preserved.
 */
typedef LiveEventFieldData = {
	var name:String;
	var wireName:String;
	var typeName:String;
	var kind:LiveEventFieldKind;
	var optional:Bool;
	var pos:Position;
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
	WirePayload;
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
				fields: readFields(enumPath, constructor),
				pos: constructor.pos
			});
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

	static function readFields(enumPath:String, constructor:EnumField):Array<LiveEventFieldData> {
		return switch (constructor.type.follow()) {
			case TFun(args, _):
				var seenWireKeys = new Map<String, Position>();
				var fields:Array<LiveEventFieldData> = [];
				for (arg in args) {
					var wireName = camelToSnake(arg.name);
					if (seenWireKeys.exists(wireName)) {
						Context.error('LiveView event ${enumPath}.${constructor.name} has duplicate payload wire key "$wireName".', constructor.pos);
					}
					seenWireKeys.set(wireName, constructor.pos);

					var field = buildField(arg.name, wireName, arg.t, arg.opt, constructor.pos);
					switch (field.kind) {
						case Unsupported(reason):
							Context.error('${enumPath}.${constructor.name} payload field "${arg.name}" uses unsupported type ${field.typeName}. ${reason}', constructor.pos);
						case _:
					}
					fields.push(field);
				}
				fields;
			case _:
				[];
		};
	}

	static function buildField(name:String, wireName:String, type:Type, optional:Bool, pos:Position):LiveEventFieldData {
		var typeName = type.toString();
		return {
			name: name,
			wireName: wireName,
			typeName: typeName,
			kind: classifyFieldType(typeName),
			optional: optional || typeName.startsWith("Null<"),
			pos: pos
		};
	}

	static function classifyFieldType(typeName:String):LiveEventFieldKind {
		return switch (typeName) {
			case "String": WireString;
			case "Int": WireInt;
			case "Bool": WireBool;
			case "Float": WireFloat;
			case "Array<String>": WireStringArray;
			case "Array<Int>": WireIntArray;
			case "phoenix.channels.Payload" | "elixir.types.Term" | "js.lib.Object": WirePayload;
			case name if (name.startsWith("Null<") && name.endsWith(">")):
				classifyFieldType(name.substr(5, name.length - 6));
			case _:
				Unsupported("Use String, Int, Bool, Float, Array<String>, Array<Int>, Payload, or add an explicit codec in the generator layer.");
		};
	}

	static function buildManifest(enumPath:String, companionName:String, events:Array<LiveEventData>):String {
		var buf = new StringBuf();
		buf.add('protocol ${enumPath}\n');
		buf.add('companion ${companionName}\n');
		for (event in events) {
			buf.add('event ${event.constructorName} ${event.eventName}');
			if (event.fields.length == 0) {
				buf.add(' ()\n');
			} else {
				var encodedFields = [
					for (field in event.fields)
						'${field.name}:${field.typeName}->${field.wireName}:${kindName(field.kind)}${field.optional ? "?" : ""}'
				];
				buf.add(' (${encodedFields.join(", ")})\n');
			}
		}
		return buf.toString();
	}

	static function kindName(kind:LiveEventFieldKind):String {
		return switch (kind) {
			case WireString: "string";
			case WireInt: "int";
			case WireBool: "bool";
			case WireFloat: "float";
			case WireStringArray: "string_array";
			case WireIntArray: "int_array";
			case WirePayload: "payload";
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
