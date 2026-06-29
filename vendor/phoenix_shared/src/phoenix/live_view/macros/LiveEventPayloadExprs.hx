package phoenix.live_view.macros;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventArgumentData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventArgumentKind;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventFieldData;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventFieldKind;
import phoenix.live_view.macros.LiveEventProtocolModel.LiveEventOrigin;

/**
 * Shared payload expression generator for LiveView event protocol macros.
 *
 * WHAT
 * - Builds target-native payload map/object writes and typed payload reads.
 *
 * WHY
 * - Typed LiveEvent protocols are a compile-time PhoenixHx feature. Generated
 *   happy paths should lower to plain JS objects and Elixir maps instead of
 *   routing through the lower-level WirePayload/WireCodec helpers.
 *
 * HOW
 * - JS builds emit object literals and direct bracket reads guarded by
 *   JavaScript predicates.
 * - Elixir builds emit `Map.new/0`, `Map.put/3`, `Map.get/2`, and `Kernel.is_*`
 *   predicates through the existing typed externs.
 * - Custom codecs are still called explicitly; only the generated field access
 *   around them avoids the wire helper layer.
 */
class LiveEventPayloadExprs {
	public static function buildPayload(event:LiveEventData):Expr {
		return Context.defined("js") ? buildJsPayload(event) : buildElixirPayload(event);
	}

	public static function decodeField(field:LiveEventFieldData, payload:Expr):Expr {
		var rawName = field.name + "Raw";
		var rawIdent = ident(rawName, field.pos);
		var rawVar = {
			expr: EVars([{name: rawName, type: null, expr: rawPayloadGet(field, payload)}]),
			pos: field.pos
		};

		var decoded = switch (field.kind) {
			case CustomCodec(codec, _):
				{
					expr: EIf(notNil(rawIdent, field.pos), callCodecMethod(codec, "decode", [rawIdent]), macro null),
					pos: field.pos
				};
			case _:
				narrowRawValue(field, rawIdent);
		}

		return {expr: EBlock([rawVar, decoded]), pos: field.pos};
	}

	public static function payloadSource(event:LiveEventData, payload:Expr):Expr {
		return switch (event.origin) {
			case SubmitEvent(root) | ChangeEvent(root):
				formRootGet(root, payload, event.pos);
			case HookEvent | TemplateEvent:
				payload;
		};
	}

	public static function buildPushBody(event:LiveEventData):Expr {
		var payload = buildPayload(event);
		return macro {
			if (hook.pushEvent != null) {
				hook.pushEvent($v{event.eventName}, $payload);
			}
		};
	}

	public static function encodeFieldValue(event:LiveEventData, field:LiveEventFieldData):Expr {
		return switch (findPayloadArgument(event)) {
			case null:
				ident(field.name, field.pos);
			case arg:
				{expr: EField(ident(arg.name, arg.pos), field.name), pos: field.pos};
		};
	}

	static function buildJsPayload(event:LiveEventData):Expr {
		var fieldsLiteral = {
			expr: EObjectDecl([
				for (field in event.fields)
					{field: field.wireName, expr: encodePayloadValue(event, field)}
			]),
			pos: event.pos
		};
		var objectLiteral = switch (event.origin) {
			case SubmitEvent(root) | ChangeEvent(root):
				{expr: EObjectDecl([{field: root, expr: fieldsLiteral}]), pos: event.pos};
			case HookEvent | TemplateEvent:
				fieldsLiteral;
		};
		return {
			expr: ECheckType({
				expr: ECall({expr: EField(typeExpr(["js"], "Syntax"), "code"), pos: event.pos}, [macro $v{"{0}"}, objectLiteral]),
				pos: event.pos
			}, macro:phoenix.channels.Payload),
			pos: event.pos
		};
	}

	static function buildElixirPayload(event:LiveEventData):Expr {
		var emptyPayload:Expr = {expr: EObjectDecl([]), pos: event.pos};
		switch (event.origin) {
			case SubmitEvent(root) | ChangeEvent(root):
				return buildElixirFormPayload(event, root, emptyPayload);
			case HookEvent | TemplateEvent:
		}

		var expressions:Array<Expr> = [{
			expr: EVars([{name: "wirePayload", type: macro:phoenix.channels.Payload, expr: emptyPayload}]),
			pos: event.pos
		}];
		for (field in event.fields) {
			expressions.push({
				expr: EBinop(OpAssign, macro wirePayload, putPayloadField(field, macro wirePayload, encodePayloadValue(event, field))),
				pos: field.pos
			});
		}
		expressions.push(macro wirePayload);
		return {expr: EBlock(expressions), pos: event.pos};
	}

	static function buildElixirFormPayload(event:LiveEventData, root:String, emptyPayload:Expr):Expr {
		var expressions:Array<Expr> = [
			{
				expr: EVars([{name: "formPayload", type: macro:phoenix.channels.Payload, expr: emptyPayload}]),
				pos: event.pos
			},
			{
				expr: EVars([{name: "wirePayload", type: macro:phoenix.channels.Payload, expr: emptyPayload}]),
				pos: event.pos
			}
		];
		for (field in event.fields) {
			expressions.push({
				expr: EBinop(OpAssign, macro formPayload, putPayloadField(field, macro formPayload, encodePayloadValue(event, field))),
				pos: field.pos
			});
		}
		expressions.push({
			expr: EBinop(OpAssign, macro wirePayload, putPayloadRoot(root, macro wirePayload, macro formPayload, event.pos)),
			pos: event.pos
		});
		expressions.push(macro wirePayload);
		return {expr: EBlock(expressions), pos: event.pos};
	}

	static function encodePayloadValue(event:LiveEventData, field:LiveEventFieldData):Expr {
		var value = encodeFieldValue(event, field);
		return switch (field.kind) {
			case CustomCodec(codec, _):
				callCodecMethod(codec, "encode", [value]);
			case _:
				value;
		};
	}

	static function putPayloadField(field:LiveEventFieldData, payload:Expr, value:Expr):Expr {
		return {
			expr: ECall({expr: EField(typeExpr(["elixir"], "ElixirMap"), "put"), pos: field.pos}, [
				payload,
				macro $v{field.wireName},
				value
			]),
			pos: field.pos
		};
	}

	static function putPayloadRoot(root:String, payload:Expr, value:Expr, pos:Position):Expr {
		return {
			expr: ECall({expr: EField(typeExpr(["elixir"], "ElixirMap"), "put"), pos: pos}, [
				payload,
				macro $v{root},
				value
			]),
			pos: pos
		};
	}

	static function rawPayloadGet(field:LiveEventFieldData, payload:Expr):Expr {
		if (Context.defined("js")) {
			return {
				expr: ECall({expr: EField(typeExpr(["js"], "Syntax"), "code"), pos: field.pos}, [
					macro $v{"({0} == null ? null : {0}[{1}])"},
					payload,
					macro $v{field.wireName}
				]),
				pos: field.pos
			};
		}

		var mapRead = {
			expr: ECall({expr: EField(typeExpr(["elixir"], "ElixirMap"), "get"), pos: field.pos}, [
				payload,
				macro $v{field.wireName}
			]),
			pos: field.pos
		};
		return {
			expr: EIf(isElixirMap(payload, field.pos), mapRead, macro null),
			pos: field.pos
		};
	}

	static function formRootGet(root:String, payload:Expr, pos:Position):Expr {
		if (Context.defined("js")) {
			return {
				expr: ECall({expr: EField(typeExpr(["js"], "Syntax"), "code"), pos: pos}, [
					macro $v{"({0} == null ? null : {0}[{1}])"},
					payload,
					macro $v{root}
				]),
				pos: pos
			};
		}

		var rootRead = {
			expr: ECall({expr: EField(typeExpr(["elixir"], "ElixirMap"), "get"), pos: pos}, [
				payload,
				macro $v{root}
			]),
			pos: pos
		};
		return {
			expr: EIf(isElixirMap(payload, pos), rootRead, macro null),
			pos: pos
		};
	}

	static function narrowRawValue(field:LiveEventFieldData, raw:Expr):Expr {
		if (Context.defined("js")) {
			var code = switch (field.kind) {
				case WireString:
					"(typeof {0} === 'string' ? {0} : null)";
				case WireInt:
					"(Number.isInteger({0}) ? {0} : null)";
				case WireBool:
					"(typeof {0} === 'boolean' ? {0} : null)";
				case WireFloat:
					"(typeof {0} === 'number' ? {0} : null)";
				case WireStringArray:
					"(Array.isArray({0}) && {0}.every(function(v){ return typeof v === 'string'; }) ? {0} : null)";
				case WireIntArray:
					"(Array.isArray({0}) && {0}.every(function(v){ return Number.isInteger(v); }) ? {0} : null)";
				case RawPayload:
					"({0} !== null && typeof {0} === 'object' && !Array.isArray({0}) ? {0} : null)";
				case CustomCodec(_, _) | Unsupported(_):
					"null";
			};
			return {
				expr: ECall({expr: EField(typeExpr(["js"], "Syntax"), "code"), pos: field.pos}, [macro $v{code}, raw]),
				pos: field.pos
			};
		}

		var predicate = switch (field.kind) {
			case WireString:
				kernelPredicate("isBinary", raw, field.pos);
			case WireInt:
				if (isDomStringOrigin(field)) {
					return narrowTemplateIntRaw(field, raw);
				}
				kernelPredicate("isInteger", raw, field.pos);
			case WireBool:
				if (isFormEvent(field)) {
					return narrowFormBoolRaw(field, raw);
				}
				kernelPredicate("isBoolean", raw, field.pos);
			case WireFloat:
				if (isFormEvent(field)) {
					return narrowFormFloatRaw(field, raw);
				}
				{
					expr: EBinop(OpBoolOr, kernelPredicate("isFloat", raw, field.pos), kernelPredicate("isInteger", raw, field.pos)),
					pos: field.pos
				};
			case WireStringArray | WireIntArray:
				kernelPredicate("isList", raw, field.pos);
			case RawPayload:
				kernelPredicate("isMap", raw, field.pos);
			case CustomCodec(_, _) | Unsupported(_):
				macro false;
		};
		return {
			expr: EIf(predicate, {expr: ECast(raw, null), pos: field.pos}, macro null),
			pos: field.pos
		};
	}

	static function narrowTemplateIntRaw(field:LiveEventFieldData, raw:Expr):Expr {
		var parsed = macro Std.parseInt($raw);
		return {
			expr: EIf(kernelPredicate("isInteger", raw, field.pos), {expr: ECast(raw, null), pos: field.pos}, {
				expr: EIf(kernelPredicate("isBinary", raw, field.pos), parsed, macro null),
				pos: field.pos
			}),
			pos: field.pos
		};
	}

	static function narrowFormBoolRaw(field:LiveEventFieldData, raw:Expr):Expr {
		var rawText = {
			expr: ECall({expr: EField(typeExpr(["elixir"], "Kernel"), "toString"), pos: field.pos}, [raw]),
			pos: field.pos
		};
		return {
			expr: EIf(kernelPredicate("isBoolean", raw, field.pos), raw, {
				expr: EIf(kernelPredicate("isBinary", raw, field.pos), {
					expr: EIf({expr: EBinop(OpEq, rawText, macro "true"), pos: field.pos}, macro true, {
						expr: EIf({expr: EBinop(OpEq, rawText, macro "false"), pos: field.pos}, macro false, macro null),
						pos: field.pos
					}),
					pos: field.pos
				}, macro null),
				pos: field.pos
			}),
			pos: field.pos
		};
	}

	static function narrowFormFloatRaw(field:LiveEventFieldData, raw:Expr):Expr {
		return {
			expr: EIf({
				expr: EBinop(OpBoolOr, kernelPredicate("isFloat", raw, field.pos), kernelPredicate("isInteger", raw, field.pos)),
				pos: field.pos
			}, {expr: ECast(raw, null), pos: field.pos}, {
				expr: EIf(kernelPredicate("isBinary", raw, field.pos), macro Std.parseFloat($raw), macro null),
				pos: field.pos
			}),
			pos: field.pos
		};
	}

	static function isDomStringOrigin(field:LiveEventFieldData):Bool {
		return switch (field.origin) {
			case TemplateEvent | SubmitEvent(_) | ChangeEvent(_):
				true;
			case HookEvent:
				false;
		};
	}

	static function isFormEvent(field:LiveEventFieldData):Bool {
		return switch (field.origin) {
			case SubmitEvent(_) | ChangeEvent(_):
				true;
			case HookEvent | TemplateEvent:
				false;
		};
	}

	static function isElixirMap(value:Expr, pos:Position):Expr {
		return {
			expr: EBinop(OpBoolAnd, notNil(value, pos), kernelPredicate("isMap", value, pos)),
			pos: pos
		};
	}

	static function kernelPredicate(name:String, value:Expr, pos:Position):Expr {
		return {
			expr: ECall({expr: EField(typeExpr(["elixir"], "Kernel"), name), pos: pos}, [value]),
			pos: pos
		};
	}

	static function callCodecMethod(codec:Expr, method:String, args:Array<Expr>):Expr {
		return {
			expr: ECall({expr: EField(codec, method), pos: codec.pos}, args),
			pos: codec.pos
		};
	}

	static function notNil(value:Expr, pos:Position):Expr {
		if (Context.defined("js")) {
			return {expr: EBinop(OpNotEq, value, macro null), pos: pos};
		}
		return {expr: EUnop(OpNot, false, kernelPredicate("isNil", value, pos)), pos: pos};
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

	static function ident(name:String, pos:Position):Expr {
		return {expr: EConst(CIdent(name)), pos: pos};
	}

	static function typeExpr(pack:Array<String>, name:String):Expr {
		var parts = pack.concat([name]);
		var expr:Expr = {expr: EConst(CIdent(parts.shift())), pos: Context.currentPos()};
		for (part in parts) {
			expr = {expr: EField(expr, part), pos: Context.currentPos()};
		}
		return expr;
	}
}
#end
