package phoenix.live_view.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.ExprTools;
import haxe.macro.Printer;
import haxe.macro.Type;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventFieldData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventFieldKind;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventProtocolData;
#end

/**
 * Generates explicit server-side LiveView dispatch helpers for shared protocols.
 *
 * WHAT
 * - Reads `@:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent")` from a
 *   `@:liveview` class and injects the named static dispatch helper.
 *
 * WHY
 * - Shared event protocols should remove handwritten decode/dispatch
 *   boilerplate while keeping Phoenix's ordinary `handle_event/3` callback
 *   visible. The LiveView still opts in by calling the generated helper.
 *
 * HOW
 * - Reuses `LiveEventProtocolModel` and the generated companion `decode`.
 * - Validates that each protocol constructor has a matching handler method.
 * - Validates that `handleEvent` explicitly calls the generated dispatcher.
 */
class LiveEventDispatcherBuilder {
#if macro
	/**
	 * Mutates `fields` by appending generated dispatch helpers and returns the
	 * protocol event names registered for HXX `phx-*` validation.
	 */
	public static function apply(cls:ClassType, fields:Array<Field>):Array<String> {
		var generatedEventNames:Array<String> = [];
		if (cls.meta == null)
			return generatedEventNames;

		for (entry in cls.meta.get()) {
			if (entry.name != ":liveEvents")
				continue;

			var binding = readBinding(entry);
			var protocol = LiveEventProtocolModel.fromTypeRef(binding.protocolRef);
			validateNoFieldCollision(fields, binding.dispatchName, entry.pos);
			var handleEvent = findHandleEvent(fields, entry.pos);
			for (event in protocol.events) {
				validateHandler(fields, event, handleEvent, cls);
			}
			if (!handleEventCallsDispatcher(handleEvent, binding.dispatchName)) {
				reportMissingDispatcherCall(binding.dispatchName, entry.pos);
				continue;
			}
			for (event in protocol.events) {
				generatedEventNames.push(event.eventName);
			}
			fields.push(buildDispatchFunction(protocol, binding.dispatchName, handleEvent));
		}

		return generatedEventNames;
	}

	static function readBinding(entry:MetadataEntry):{protocolRef:Expr, dispatchName:String} {
		if (entry.params == null || entry.params.length < 2) {
			Context.error('@:liveEvents expects a protocol enum and dispatch helper name, for example @:liveEvents(ProfileHookEvent, "dispatchProfileHookEvent").',
				entry.pos);
		}

		var dispatchName = switch (entry.params[1].expr) {
			case EConst(CString(value, _)): value;
			case _:
				Context.error("@:liveEvents dispatch helper name must be a string literal.", entry.params[1].pos);
				"";
		}
		if (StringTools.trim(dispatchName) == "") {
			Context.error("@:liveEvents dispatch helper name must not be empty.", entry.params[1].pos);
		}

		return {protocolRef: entry.params[0], dispatchName: dispatchName};
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

		var expectedArgs = event.fields.length + 1;
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
		var expressions:Array<Expr> = [];
		var missingChecks:Array<Expr> = [];
		for (field in event.fields) {
			var fieldIdent = {expr: EConst(CIdent(field.name)), pos: field.pos};
			expressions.push({
				expr: EVars([{name: field.name, type: fieldComplexType(field), expr: callWirePayloadGet(field, macro payload)}]),
				pos: field.pos
			});
			if (!field.optional) {
				missingChecks.push({
					expr: EBinop(OpEq, fieldIdent, macro null),
					pos: field.pos
				});
			}
		}

		if (missingChecks.length > 0) {
			expressions.push({
				expr: EIf(anyOf(missingChecks), macro null, buildHandlerCall(event)),
				pos: event.pos
			});
		} else {
			expressions.push(buildHandlerCall(event));
		}
		return {expr: EBlock(expressions), pos: event.pos};
	}

	static function buildHandlerCall(event:LiveEventData):Expr {
		var args:Array<Expr> = [for (field in event.fields) {expr: EConst(CIdent(field.name)), pos: field.pos}];
		args.push(macro socket);
		return {
			expr: ECall({expr: EConst(CIdent("handle" + event.constructorName)), pos: event.pos}, args),
			pos: event.pos
		};
	}

	static function fieldTypeLabel(field:LiveEventFieldData):String {
		return switch (field.kind) {
			case WireString: "String";
			case WireInt: "Int";
			case WireBool: "Bool";
			case WireFloat: "Float";
			case WireStringArray: "Array<String>";
			case WireIntArray: "Array<Int>";
			case WirePayload: "phoenix.channels.Payload";
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
			case WirePayload: macro:phoenix.channels.Payload;
			case Unsupported(_): macro:String;
		};
	}

	static function callWirePayloadGet(field:LiveEventFieldData, payload:Expr):Expr {
		return {
			expr: ECall(wirePayloadMethod(getMethod(field.kind)), [payload, macro $v{field.wireName}]),
			pos: field.pos
		};
	}

	static function wirePayloadMethod(methodName:String):Expr {
		return {
			expr: EField(typeExpr(["phoenix", "channels"], "WirePayload"), methodName),
			pos: Context.currentPos()
		};
	}

	static function getMethod(kind:LiveEventFieldKind):String {
		return switch (kind) {
			case WireString: "getString";
			case WireInt: "getInt";
			case WireBool: "getBool";
			case WireFloat: "getFloat";
			case WireStringArray: "getStringArray";
			case WireIntArray: "getIntArray";
			case WirePayload: "getPayload";
			case Unsupported(_): "getString";
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
		var args = [for (field in event.fields) '${field.name}:${field.optional ? "Null<" + fieldTypeLabel(field) + ">" : fieldTypeLabel(field)}'];
		args.push("socket");
		return args.join(", ");
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

	static function typePath(pack:Array<String>, name:String):String {
		return pack.length == 0 ? name : pack.join(".") + "." + name;
	}

	static function complexTypeLabel(type:ComplexType):String {
		return new Printer().printComplexType(type);
	}
#end
}
