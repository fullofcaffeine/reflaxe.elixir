package phoenix.live_view.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;
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
 * Compile-time contract exported to HXX validation for one generated LiveView event.
 */
typedef GeneratedLiveEventContract = {
	var eventName:String;
	var origin:String;
	var requiredValueKeys:Array<String>;
	var allowedValueKeys:Array<String>;
}
#end

/**
 * Generates explicit server-side LiveView dispatch helpers for shared protocols.
 *
 * WHAT
 * - Reads `@:liveEvents(ProfileHookEvent)` from a
 *   `@:liveview` class and injects the named static dispatch helper.
 *
 * WHY
 * - Shared event protocols should remove handwritten decode/dispatch
 *   boilerplate while keeping Phoenix's ordinary `handle_event/3` callback
 *   visible. The LiveView still opts in by calling the generated helper.
 *
 * HOW
 * - Reuses `LiveEventProtocolModel`.
 * - Validates that each protocol constructor has a matching handler method.
 * - Validates that `handleEvent` explicitly calls the generated dispatcher.
 * - Emits direct map reads and BEAM predicate checks for generated payload
 *   decoding instead of depending on the lower-level wire helper layer.
 */
class LiveEventDispatcherBuilder {
#if macro
	/**
	 * Mutates `fields` by appending generated dispatch helpers and returns the
	 * protocol event contracts registered for HXX `phx-*` validation.
	 */
	public static function apply(cls:ClassType, fields:Array<Field>):Array<GeneratedLiveEventContract> {
		var generatedEventContracts:Array<GeneratedLiveEventContract> = [];
		if (cls.meta == null)
			return generatedEventContracts;

		for (entry in cls.meta.get()) {
			if (entry.name != ":liveEvents")
				continue;

			var binding = readBinding(entry);
			var protocol = LiveEventProtocolModel.fromTypeRef(binding.protocolRef);
			var dispatchName = binding.dispatchName != null ? binding.dispatchName : defaultDispatchName(protocol);
			validateNoFieldCollision(fields, dispatchName, entry.pos);
			var handleEvent = findHandleEvent(fields, entry.pos);
			for (event in protocol.events) {
				validateHandler(fields, event, handleEvent, cls);
			}
			if (!handleEventCallsDispatcher(handleEvent, dispatchName)) {
				reportMissingDispatcherCall(dispatchName, entry.pos);
				continue;
			}
			for (event in protocol.events) {
				generatedEventContracts.push(buildGeneratedContract(event));
			}
			fields.push(buildDispatchFunction(protocol, dispatchName, handleEvent));
		}

		return generatedEventContracts;
	}

	static function buildGeneratedContract(event:LiveEventData):GeneratedLiveEventContract {
		var requiredValueKeys:Array<String> = [];
		var allowedValueKeys:Array<String> = [];

		if (isTemplateEvent(event)) {
			for (field in event.fields) {
				allowedValueKeys.push(field.wireName);
				if (!field.optional)
					requiredValueKeys.push(field.wireName);
			}
		}

		return {
			eventName: event.eventName,
			origin: originName(event.origin),
			requiredValueKeys: requiredValueKeys,
			allowedValueKeys: allowedValueKeys
		};
	}

	static function isTemplateEvent(event:LiveEventData):Bool {
		return switch (event.origin) {
			case TemplateEvent: true;
			default: false;
		};
	}

	static function originName(origin:LiveEventOrigin):String {
		return switch (origin) {
			case HookEvent: "hook";
			case TemplateEvent: "template";
			case SubmitEvent(_): "submit";
			case ChangeEvent(_): "change";
		};
	}

	static function readBinding(entry:MetadataEntry):{protocolRef:Expr, dispatchName:Null<String>} {
		if (entry.params == null || entry.params.length < 1) {
			Context.error("@:liveEvents expects a protocol enum, for example @:liveEvents(ProfileHookEvent).", entry.pos);
		}

		if (entry.params.length == 1) {
			return {protocolRef: entry.params[0], dispatchName: null};
		}

		var dispatchName = switch (entry.params[1].expr) {
			case EConst(CIdent(value)): value;
			case EConst(CString(value, _)): value;
			case _:
				Context.error("@:liveEvents dispatch helper override must be an identifier, for example @:liveEvents(ProfileHookEvent, dispatchProfileHookEvent).",
					entry.params[1].pos);
				"";
		}
		validateDispatchName(dispatchName, entry.params[1].pos);

		return {protocolRef: entry.params[0], dispatchName: dispatchName};
	}

	static function defaultDispatchName(protocol:LiveEventProtocolData):String {
		return "dispatch" + protocol.enumName;
	}

	static function validateDispatchName(dispatchName:String, pos:Position):Void {
		if (StringTools.trim(dispatchName) == "") {
			Context.error("@:liveEvents dispatch helper name must not be empty.", pos);
		}
		if (!~/^[A-Za-z_][A-Za-z0-9_]*$/.match(dispatchName)) {
			Context.error('@:liveEvents dispatch helper "$dispatchName" must be a valid Haxe identifier.', pos);
		}
	}

	static function validateNoFieldCollision(fields:Array<Field>, dispatchName:String, pos:Position):Void {
		for (field in fields) {
			if (field.name == dispatchName) {
				Context.error('LiveView event dispatcher "$dispatchName" already exists.', pos);
			}
		}
	}

	static function findHandleEvent(fields:Array<Field>, pos:Position):Field {
		for (field in fields) {
			if ((field.name == "handleEvent" || field.name == "handle_event") && isPublicStatic(field)) {
				switch (field.kind) {
					case FFun(f) if (f != null && f.args != null && f.args.length >= 3 && f.ret != null):
					case FFun(_):
						Context.error("@:liveEvents requires handleEvent(event, params, socket) to declare three arguments and an explicit return type.",
							field.pos);
					case _:
						Context.error("@:liveEvents requires handleEvent to be a function.", field.pos);
				}
				return field;
			}
		}
		Context.error("@:liveEvents requires a public static handleEvent(event, params, socket) callback.", pos);
		return null;
	}

	static function validateHandler(fields:Array<Field>, event:LiveEventData, handleEvent:Field, cls:ClassType):Void {
		var handlerName = "handle" + event.constructorName;
		var handler = findField(fields, handlerName);
		if (handler == null) {
			var className = typePath(cls.pack, cls.name);
			Context.error('${className} declares @:liveEvents but does not define ${handlerName}(${handlerArgsDescription(event)}).', event.pos);
		}

		var expectedArgs = event.args.length + 1;
		var actualArgs = switch (handler.kind) {
			case FFun(f) if (f != null && f.args != null): f.args.length;
			case _: -1;
		}
		if (actualArgs != expectedArgs) {
			Context.error('${handlerName} must accept ${expectedArgs} argument${expectedArgs == 1 ? "" : "s"}: ${handlerArgsDescription(event)}.',
				handler.pos);
		}

		switch [handler.kind, handleEvent.kind] {
			case [FFun(handlerFn), FFun(handleFn)] if (handlerFn.ret != null && handleFn.ret != null):
				if (complexTypeLabel(handlerFn.ret) != complexTypeLabel(handleFn.ret)) {
					Context.error('${handlerName} has wrong return type. Expected ${complexTypeLabel(handleFn.ret)}.', handler.pos);
				}
			case [FFun(handlerFn), FFun(_)] if (handlerFn.ret == null):
				Context.error('${handlerName} must declare the same return type as handleEvent.', handler.pos);
			case _:
		}
	}

	static function handleEventCallsDispatcher(handleEvent:Field, dispatchName:String):Bool {
		var expr = switch (handleEvent.kind) {
			case FFun(f): f.expr;
			case _: null;
		}
		return expr != null && containsCallTo(expr, dispatchName);
	}

	static function reportMissingDispatcherCall(dispatchName:String, pos:Position):Void {
		var message = 'LiveView declares @:liveEvents but handleEvent does not call ${dispatchName}(...). Add the explicit dispatch call or remove @:liveEvents.';
		if (Context.defined("phoenixhx_live_events_strict")) {
			Context.error(message, pos);
		}
		Context.warning(message + " Dispatcher generation is skipped until the explicit call is present. Pass -D phoenixhx_live_events_strict to enforce this as an error.",
			pos);
	}

	static function buildDispatchFunction(protocol:LiveEventProtocolData, dispatchName:String, handleEvent:Field):Field {
		var handleFunction = switch (handleEvent.kind) {
			case FFun(f): f;
			case _: null;
		}
		var socketType = handleFunction.args[2].type;
		var returnType = handleFunction.ret;

		return {
			name: dispatchName,
			access: [AStatic],
			kind: FFun({
				args: [
					{name: "eventName", type: macro:String},
					{name: "payload", type: macro:phoenix.channels.Payload},
					{name: "socket", type: socketType}
				],
				ret: TPath({pack: [], name: "Null", params: [TPType(returnType)]}),
				expr: {
					expr: EBlock([
						{
							expr: EReturn(buildEventIfChain(protocol.events, 0)),
							pos: Context.currentPos()
						}
					]),
					pos: Context.currentPos()
				}
			}),
			pos: Context.currentPos()
		};
	}

	static function buildEventIfChain(events:Array<LiveEventData>, index:Int):Expr {
		if (index >= events.length)
			return macro null;
		var event = events[index];
		return {
			expr: EIf({
				expr: EBinop(OpEq, macro eventName, macro $v{event.eventName}),
				pos: event.pos
			}, buildEventDispatchValue(event), buildEventIfChain(events, index + 1)),
			pos: event.pos
		};
	}

	static function buildEventDispatchValue(event:LiveEventData):Expr {
		if (event.fields.length == 0) {
			return buildHandlerCall(event);
		}

		var expressions:Array<Expr> = [];
		var missingChecks:Array<Expr> = [];
		var payloadLocal = localNameAvoidingFields(event, "eventPayload");
		var payloadSource:Expr = ident(payloadLocal, event.pos);
		if (isFormEvent(event)) {
			var rootLocal = localNameAvoidingFields(event, "eventPayloadRoot");
			expressions.push({
				expr: EVars([{name: rootLocal, type: macro:phoenix.channels.Payload, expr: LiveEventPayloadExprs.payloadSource(event, macro payload)}]),
				pos: event.pos
			});
			expressions.push({
				expr: EVars([{name: payloadLocal, type: macro:phoenix.channels.Payload, expr: LiveEventPayloadExprs.mapOrEmpty(ident(rootLocal, event.pos), event.pos)}]),
				pos: event.pos
			});
		} else {
			expressions.push({
				expr: EVars([{name: payloadLocal, type: macro:phoenix.channels.Payload, expr: LiveEventPayloadExprs.mapOrEmpty(macro payload, event.pos)}]),
				pos: event.pos
			});
		}
		for (field in event.fields) {
			var fieldIdent = {expr: EConst(CIdent(field.name)), pos: field.pos};
			expressions.push({
				expr: EVars([{name: field.name, type: fieldComplexType(field), expr: LiveEventPayloadExprs.decodeField(field, payloadSource, true)}]),
				pos: field.pos
			});
			if (!field.optional) {
				missingChecks.push(isNil(fieldIdent, field.pos));
			}
		}

		if (missingChecks.length > 0) {
			expressions.push({
				expr: EIf(anyOf(missingChecks), buildInvalidPayloadResult(), buildHandlerCall(event)),
				pos: event.pos
			});
		} else {
			var resultName = handlerResultLocalName(event);
			// Optional-only payload events need an explicit final value after decode bindings.
			expressions.push({
				expr: EVars([{name: resultName, type: null, expr: buildHandlerCall(event)}]),
				pos: event.pos
			});
			expressions.push({expr: EConst(CIdent(resultName)), pos: event.pos});
		}
		return {expr: EBlock(expressions), pos: event.pos};
	}

	static function handlerResultLocalName(event:LiveEventData):String {
		var used = new Map<String, Bool>();
		for (field in event.fields) {
			used.set(field.name, true);
		}
		for (candidate in ["handlerResult", "protocolResult", "liveEventResult", "dispatchResult", "eventResult"]) {
			if (!used.exists(candidate)) {
				return candidate;
			}
		}
		return "liveEventHandlerResult";
	}

	static function localNameAvoidingFields(event:LiveEventData, base:String):String {
		var used = new Map<String, Bool>();
		for (field in event.fields) {
			used.set(field.name, true);
			used.set(field.name + "Raw", true);
		}
		if (!used.exists(base)) {
			return base;
		}
		var index = 2;
		while (used.exists(base + index)) {
			index++;
		}
		return base + index;
	}

	static function isFormEvent(event:LiveEventData):Bool {
		return switch (event.origin) {
			case SubmitEvent(_) | ChangeEvent(_):
				true;
			case HookEvent | TemplateEvent:
				false;
		};
	}

	static function isNil(value:Expr, pos:Position):Expr {
		return {
			expr: ECall({expr: EField(typeExpr(["elixir"], "Kernel"), "isNil"), pos: pos}, [value]),
			pos: pos
		};
	}

	static function buildInvalidPayloadResult():Expr {
		return macro NoReply(socket);
	}

	static function buildHandlerCall(event:LiveEventData):Expr {
		var args:Array<Expr> = decodedHandlerArgs(event);
		args.push(macro socket);
		return {
			expr: ECall({expr: EConst(CIdent("handle" + event.constructorName)), pos: event.pos}, args),
			pos: event.pos
		};
	}

	static function decodedHandlerArgs(event:LiveEventData):Array<Expr> {
		return switch (findPayloadArgument(event)) {
			case null:
				[for (arg in event.args) {expr: EConst(CIdent(arg.name)), pos: arg.pos}];
			case arg:
				[buildPayloadObject(arg)];
		};
	}

	static function buildPayloadObject(arg:LiveEventArgumentData):Expr {
		return keywordMap({
			expr: EObjectDecl([
				for (field in arg.fields)
					{field: field.name, expr: {expr: EConst(CIdent(field.name)), pos: field.pos}}
			]),
			pos: arg.pos
		});
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

	static function fieldTypeLabel(field:LiveEventFieldData):String {
		return switch (field.kind) {
			case WireString: "String";
			case WireInt: "Int";
			case WireBool: "Bool";
			case WireFloat: "Float";
			case WireStringArray: "Array<String>";
			case WireIntArray: "Array<Int>";
			case RawPayload: "phoenix.channels.Payload";
			case CustomCodec(_, _): field.typeName;
			case Unsupported(_): field.typeName;
		};
	}

	static function fieldComplexType(field:LiveEventFieldData):ComplexType {
		return TPath({pack: [], name: "Null", params: [TPType(fieldBaseType(field))]});
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
			case Unsupported(_): macro:String;
		};
	}

	static function anyOf(checks:Array<Expr>):Expr {
		var condition = checks[0];
		for (i in 1...checks.length) {
			condition = {
				expr: EBinop(OpBoolOr, condition, checks[i]),
				pos: checks[i].pos
			};
		}
		return condition;
	}

	static function handlerArgsDescription(event:LiveEventData):String {
		var args = [for (arg in event.args) argumentDescription(arg)];
		args.push("socket");
		return args.join(", ");
	}

	static function argumentDescription(arg:LiveEventArgumentData):String {
		return switch (arg.kind) {
			case FieldArguments:
				var field = arg.fields[0];
				'${arg.name}:${field.optional ? "Null<" + fieldTypeLabel(field) + ">" : fieldTypeLabel(field)}';
			case TypedefPayload:
				'${arg.name}:${arg.typeName}';
		};
	}

	static function containsCallTo(expr:Expr, functionName:String):Bool {
		var found = false;
		function visit(e:Expr):Void {
			if (e == null || found)
				return;
			switch (e.expr) {
				case ECall(target, _):
					if (exprNamesFunction(target, functionName)) {
						found = true;
						return;
					}
				case _:
			}
			ExprTools.iter(e, visit);
		}
		visit(expr);
		return found;
	}

	static function exprNamesFunction(expr:Expr, functionName:String):Bool {
		return switch (expr.expr) {
			case EConst(CIdent(name)): name == functionName;
			case EField(_, name): name == functionName;
			case _: false;
		};
	}

	static function findField(fields:Array<Field>, name:String):Null<Field> {
		for (field in fields) {
			if (field.name == name)
				return field;
		}
		return null;
	}

	static function isPublicStatic(field:Field):Bool {
		var hasPublic = false;
		var hasStatic = false;
		if (field.access == null)
			return false;
		for (access in field.access) {
			switch (access) {
				case APublic:
					hasPublic = true;
				case AStatic:
					hasStatic = true;
				case _:
			}
		}
		return hasPublic && hasStatic;
	}

	static function typeExpr(pack:Array<String>, name:String):Expr {
		var parts = pack.concat([name]);
		var expr:Expr = {expr: EConst(CIdent(parts.shift())), pos: Context.currentPos()};
		for (part in parts) {
			expr = {expr: EField(expr, part), pos: Context.currentPos()};
		}
		return expr;
	}

	static function ident(name:String, pos:Position):Expr {
		return {expr: EConst(CIdent(name)), pos: pos};
	}

	static function keywordMap(expr:Expr):Expr {
		if (Context.defined("js")) {
			return expr;
		}
		return macro phoenix.live_view.LiveEventProtocol.keywordMap($expr);
	}

	static function typePath(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}

	static function complexTypeLabel(type:ComplexType):String {
		return new Printer().printComplexType(type);
	}
#end
}
