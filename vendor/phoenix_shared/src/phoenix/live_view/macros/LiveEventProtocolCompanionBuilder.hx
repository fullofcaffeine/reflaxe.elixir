package phoenix.live_view.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventArgumentData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventArgumentKind;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventFieldData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventFieldKind;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventOrigin;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventProtocolData;

using haxe.macro.Tools;

/**
 * Generates the first LiveView event companion helper surface.
 *
 * WHAT
 * - Produces event-name constants plus typed `encode` and `decode` helpers for
 *   a `@:liveEventProtocol` enum.
 *
 * WHY
 * - The todo-app prototype proved the value of a shared enum, but handwritten
 *   `HookEvents.encodeClientPush/decodeServerRecv` boilerplate should become a
 *   PhoenixHx framework responsibility.
 *
 * HOW
 * - Resolves `LiveEventProtocolCompanion<ProtocolEnum>`.
 * - Reuses `LiveEventProtocolModel` as the single parser/validator.
 * - Emits direct JS object and Elixir map access for built-in field kinds so
 *   generated protocol code stays close to handwritten Phoenix boundary code.
 */
class LiveEventProtocolCompanionBuilder {
	/**
	 * Returns the generated implementation type for `LiveEventProtocolCompanion<T>`.
	 */
	public static function build():ComplexType {
		var protocolType = resolveProtocolType(Context.getLocalType());
		var protocol = LiveEventProtocolModel.fromType(protocolType, Context.currentPos());
		var companionPath = ensureGeneratedType(protocol);

		return TPath({pack: companionPath.pack, name: companionPath.name});
	}

	/**
	 * Ensures the concrete helper module exists and returns its Haxe type path.
	 */
	public static function ensureGeneratedType(protocol:LiveEventProtocolData):{pack:Array<String>, name:String} {
		var companionPath = companionPath(protocol);

		if (tryResolveType(typePath(companionPath.pack, companionPath.name)) == null) {
			Context.defineType({
				pack: companionPath.pack,
				name: companionPath.name,
				pos: Context.currentPos(),
				meta: [{name: ":native", params: [macro $v{protocol.companionName}], pos: Context.currentPos()}],
				kind: TDClass(),
				fields: buildFields(protocol)
			});
		}

		return companionPath;
	}

	static function resolveProtocolType(localType:Type):Type {
		return switch (localType.follow()) {
			case TInst(_, [protocolType]):
				protocolType;
			case _:
				Context.error("LiveEventProtocolCompanion requires one protocol enum type parameter.", Context.currentPos());
				null;
		};
	}

	static function buildFields(protocol:LiveEventProtocolData):Array<Field> {
		var fields:Array<Field> = [];
		for (event in protocol.events) {
			fields.push(buildEventConstant(event));
		}
		fields.push(buildEncodeFunction(protocol));
		fields.push(buildDecodeFunction(protocol));
		if (Context.defined("js")) {
			if (allEventsAreHookEvents(protocol)) {
				fields.push(buildPushFunction(protocol));
			}
			for (event in protocol.events) {
				if (isHookEvent(event)) {
					fields.push(buildPerEventPushFunction(protocol, event));
				}
			}
		}
		return fields;
	}

	static function buildEventConstant(event:LiveEventData):Field {
		return {
			name: event.constructorName + "Event",
			access: [APublic, AStatic, AInline],
			kind: FVar(macro:String, macro $v{event.eventName}),
			pos: event.pos
		};
	}

	static function allEventsAreHookEvents(protocol:LiveEventProtocolData):Bool {
		for (event in protocol.events) {
			if (!isHookEvent(event)) {
				return false;
			}
		}
		return true;
	}

	static function isHookEvent(event:LiveEventData):Bool {
		return switch (event.origin) {
			case HookEvent:
				true;
			case TemplateEvent | SubmitEvent(_) | ChangeEvent(_):
				false;
		};
	}

	static function buildEncodeFunction(protocol:LiveEventProtocolData):Field {
		return {
			name: "encode",
			access: [APublic, AStatic],
			kind: FFun({
				args: [{name: "event", type: protocolComplexType(protocol)}],
				ret: macro:phoenix.channels.EncodedEvent,
				expr: buildReturnBlock(buildEncodeBody(protocol))
			}),
			pos: Context.currentPos()
		};
	}

	static function buildDecodeFunction(protocol:LiveEventProtocolData):Field {
		return {
			name: "decode",
			access: [APublic, AStatic],
			kind: FFun({
				args: [
					{name: "eventName", type: macro:String},
					{name: "payload", type: macro:phoenix.channels.Payload}
				],
				ret: TPath({pack: [], name: "Null", params: [TPType(protocolComplexType(protocol))]}),
				expr: buildDecodeFunctionBlock(protocol)
			}),
			pos: Context.currentPos()
		};
	}

	static function buildPushFunction(protocol:LiveEventProtocolData):Field {
		return {
			name: "push",
			access: [APublic, AStatic],
			kind: FFun({
				args: [
					{name: "hook", type: macro:phoenix.live_view.HookContext},
					{name: "event", type: protocolComplexType(protocol)}
				],
				ret: macro:Void,
				expr: macro {
					var encoded = encode(event);
					if (hook.pushEvent != null) {
						hook.pushEvent(encoded.event, encoded.payload);
					}
				}
			}),
			pos: Context.currentPos()
		};
	}

	static function buildPerEventPushFunction(protocol:LiveEventProtocolData, event:LiveEventData):Field {
		var args:Array<FunctionArg> = [{name: "hook", type: macro:phoenix.live_view.HookContext}];
		for (arg in event.args) {
			args.push({name: arg.name, type: argumentValueType(arg)});
		}

		return {
			name: "push" + event.constructorName,
			access: [APublic, AStatic],
			kind: FFun({
				args: args,
				ret: macro:Void,
				expr: LiveEventPayloadExprs.buildPushBody(event)
			}),
			pos: event.pos
		};
	}

	static function buildReturnBlock(value:Expr):Expr {
		return {
			expr: EBlock([{expr: EReturn(value), pos: value.pos}]),
			pos: value.pos
		};
	}

	static function buildEncodeBody(protocol:LiveEventProtocolData):Expr {
		var cases:Array<Case> = [];
		for (event in protocol.events) {
			cases.push({
				values: [constructorPattern(protocol, event)],
				guard: null,
				expr: buildEncodeCase(event)
			});
		}
		return {
			expr: ESwitch(macro event, cases, null),
			pos: Context.currentPos()
		};
	}

	static function buildEncodeCase(event:LiveEventData):Expr {
		var payload = LiveEventPayloadExprs.buildPayload(event);
		return {
			expr: EObjectDecl([
				{field: "event", expr: macro $v{event.eventName}},
				{field: "payload", expr: payload}
			]),
			pos: event.pos
		};
	}

	static function buildDecodeFunctionBlock(protocol:LiveEventProtocolData):Expr {
		var expressions:Array<Expr> = [];
		for (event in protocol.events) {
			expressions.push({
				expr: EIf({
					expr: EBinop(OpEq, macro eventName, macro $v{event.eventName}),
					pos: event.pos
				}, buildDecodeReturnBlock(protocol, event), null),
				pos: event.pos
			});
		}
		expressions.push({expr: EReturn(macro null), pos: Context.currentPos()});
		return {expr: EBlock(expressions), pos: Context.currentPos()};
	}

	static function buildDecodeReturnBlock(protocol:LiveEventProtocolData, event:LiveEventData):Expr {
		var decoded = buildDecodeCase(protocol, event);
		var expressions = switch (decoded.expr) {
			case EBlock(items): items;
			case _: [decoded];
		}
		var result = expressions.pop();
		expressions.push({expr: EReturn(result), pos: event.pos});
		return {expr: EBlock(expressions), pos: event.pos};
	}

	static function buildDecodeCase(protocol:LiveEventProtocolData, event:LiveEventData):Expr {
		var expressions:Array<Expr> = [];
		var decodedChecks:Array<Expr> = [];
		var payloadSource:Expr = macro payload;
		if (isFormEvent(event) && event.fields.length > 0) {
			payloadSource = macro eventPayload;
			expressions.push({
				expr: EVars([{name: "eventPayload", type: macro:phoenix.channels.Payload, expr: LiveEventPayloadExprs.payloadSource(event, macro payload)}]),
				pos: event.pos
			});
		}
		for (field in event.fields) {
			var fieldIdent = {expr: EConst(CIdent(field.name)), pos: field.pos};
			expressions.push({
				expr: EVars([{name: field.name, type: fieldComplexType(field), expr: LiveEventPayloadExprs.decodeField(field, payloadSource)}]),
				pos: field.pos
			});
			if (!field.optional) {
				decodedChecks.push(notNil(fieldIdent, field.pos));
			}
		}

		var constructorArgs = decodedConstructorArgs(event);
		var constructed = constructorCall(protocol, event, constructorArgs);
		var result = decodedChecks.length == 0 ? constructed : guardAll(decodedChecks, constructed);
		expressions.push(result);
		return {expr: EBlock(expressions), pos: event.pos};
	}

	static function isFormEvent(event:LiveEventData):Bool {
		return switch (event.origin) {
			case SubmitEvent(_) | ChangeEvent(_):
				true;
			case HookEvent | TemplateEvent:
				false;
		};
	}

	static function notNil(value:Expr, pos:Position):Expr {
		if (Context.defined("js")) {
			return {expr: EBinop(OpNotEq, value, macro null), pos: pos};
		}
		return {
			expr: EUnop(OpNot, false, {
				expr: ECall({expr: EField(typeExpr(["elixir"], "Kernel"), "isNil"), pos: pos}, [value]),
				pos: pos
			}),
			pos: pos
		};
	}

	static function guardAll(checks:Array<Expr>, success:Expr):Expr {
		var condition = checks[0];
		for (i in 1...checks.length) {
			condition = {
				expr: EBinop(OpBoolAnd, condition, checks[i]),
				pos: checks[i].pos
			};
		}
		return {
			expr: EIf(condition, success, macro null),
			pos: success.pos
		};
	}

	static function constructorPattern(protocol:LiveEventProtocolData, event:LiveEventData):Expr {
		var constructor = constructorRef(protocol, event);
		if (event.args.length == 0) {
			return constructor;
		}
		return {
			expr: ECall(constructor, [for (arg in event.args) {expr: EConst(CIdent(arg.name)), pos: arg.pos}]),
			pos: event.pos
		};
	}

	static function constructorCall(protocol:LiveEventProtocolData, event:LiveEventData, args:Array<Expr>):Expr {
		if (event.args.length == 0) {
			return constructorRef(protocol, event);
		}
		return {
			expr: ECall(constructorRef(protocol, event), args),
			pos: event.pos
		};
	}

	static function encodeFieldValue(event:LiveEventData, field:LiveEventFieldData):Expr {
		return switch (findPayloadArgument(event)) {
			case null:
				{expr: EConst(CIdent(field.name)), pos: field.pos};
			case arg:
				{expr: EField({expr: EConst(CIdent(arg.name)), pos: arg.pos}, field.name), pos: field.pos};
		};
	}

	static function decodedConstructorArgs(event:LiveEventData):Array<Expr> {
		return switch (findPayloadArgument(event)) {
			case null:
				[for (arg in event.args) {expr: EConst(CIdent(arg.name)), pos: arg.pos}];
			case arg:
				[buildPayloadObject(arg)];
		};
	}

	static function buildPayloadObject(arg:LiveEventArgumentData):Expr {
		return {
			expr: EObjectDecl([
				for (field in arg.fields)
					{field: field.name, expr: {expr: EConst(CIdent(field.name)), pos: field.pos}}
			]),
			pos: arg.pos
		};
	}

	static function findPayloadArgument(event:LiveEventData):Null<LiveEventArgumentData> {
		for (arg in event.args) {
			switch (arg.kind) {
				case TypedefPayload:
					return arg;
				case FieldArguments:
			}
		}
		return null;
	}

	static function constructorRef(protocol:LiveEventProtocolData, event:LiveEventData):Expr {
		return {
			expr: EField(protocolTypeExpr(protocol), event.constructorName),
			pos: event.pos
		};
	}

	static function fieldComplexType(field:LiveEventFieldData):ComplexType {
		return TPath({pack: [], name: "Null", params: [TPType(fieldBaseType(field))]});
	}

	static function fieldValueType(field:LiveEventFieldData):ComplexType {
		var base = fieldBaseType(field);
		return field.optional ? TPath({pack: [], name: "Null", params: [TPType(base)]}) : base;
	}

	static function argumentValueType(arg:LiveEventArgumentData):ComplexType {
		return switch (arg.kind) {
			case FieldArguments:
				fieldValueType(arg.fields[0]);
			case TypedefPayload:
				arg.type.toComplexType();
		};
	}

	static function fieldBaseType(field:LiveEventFieldData):ComplexType {
		return switch (field.kind) {
			case WireString: macro:String;
			case WireInt: macro:Int;
			case WireBool: macro:Bool;
			case WireFloat: macro:Float;
			case WireStringArray: macro:Array<String>;
			case WireIntArray: macro:Array<Int>;
			case RawPayload: macro:phoenix.channels.Payload;
			case CustomCodec(_, _): field.type.toComplexType();
			case Unsupported(_): macro:Dynamic;
		};
	}

	static function protocolComplexType(protocol:LiveEventProtocolData):ComplexType {
		if (protocol.enumModule == protocol.enumPath) {
			return TPath({pack: protocol.enumPack, name: protocol.enumName});
		}

		var moduleParts = protocol.enumModule.split(".");
		var moduleName = moduleParts.pop();
		return TPath({pack: moduleParts, name: moduleName, sub: protocol.enumName});
	}

	static function companionPath(protocol:LiveEventProtocolData):{pack:Array<String>, name:String} {
		return {pack: protocol.enumPack, name: "_" + protocol.companionName + "Generated"};
	}

	static function typeExpr(pack:Array<String>, name:String):Expr {
		var parts = pack.concat([name]);
		var expr:Expr = {expr: EConst(CIdent(parts.shift())), pos: Context.currentPos()};
		for (part in parts) {
			expr = {expr: EField(expr, part), pos: Context.currentPos()};
		}
		return expr;
	}

	static function protocolTypeExpr(protocol:LiveEventProtocolData):Expr {
		var parts = protocol.enumModule.split(".");
		if (protocol.enumModule != protocol.enumPath) {
			parts.push(protocol.enumName);
		}
		var expr:Expr = {expr: EConst(CIdent(parts.shift())), pos: Context.currentPos()};
		for (part in parts) {
			expr = {expr: EField(expr, part), pos: Context.currentPos()};
		}
		return expr;
	}

	static function typePath(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}

	static function tryResolveType(path:String):Null<Type> {
		return try {
			Context.getType(path);
		} catch (_:Any) {
			null;
		};
	}
}
#end
