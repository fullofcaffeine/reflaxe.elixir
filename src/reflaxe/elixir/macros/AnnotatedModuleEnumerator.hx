package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;
import reflaxe.elixir.macros.MigrationRegistry;
import reflaxe.elixir.macros.LiveViewEventRegistry;
import reflaxe.elixir.macros.LiveViewEventRegistry.LiveViewEventContract;
import reflaxe.elixir.macros.LiveViewTemplateUsageRegistry;
import reflaxe.elixir.macros.EctoSchemaAssociationValidator;
import reflaxe.elixir.macros.ModuleFieldMetadataRegistry;
#if phoenix_shared
import phoenix.live_view.macros.LiveEventDispatcherBuilder;
#end

/**
 * AnnotatedModuleEnumerator
 *
 * WHAT
 * - Global build macro that marks framework-annotated modules (`@:repo`, `@:presence`, `@:endpoint`, etc.)
 *   as `@:keep` so Haxe DCE cannot eliminate them when they are referenced only indirectly at runtime.
 *
 * WHY
 * - Phoenix/Ecto/OTP modules are frequently referenced by strings or generated macros (supervision trees,
 *   `use AppWeb, ...`, etc.). From Haxe’s point of view, these modules can look unused and be removed by DCE,
 *   causing runtime failures like “module X was given as a child to a supervisor but it does not exist”.
 *
 * HOW
 * - Attached via `Compiler.addGlobalMetadata("", "@:build(...)")` in `CompilerInit.Start()`.
 * - For each built class, if it carries any of the supported framework annotations, add `@:keep` (and `@:used`)
 *   to preserve the type through DCE so it reaches the Elixir AST pipeline.
 *
 * EXAMPLES
 * Haxe:
 *   @:native("MyAppWeb.Presence")
 *   @:presence
 *   class Presence implements PresenceBehavior {}
 *
 * Elixir:
 *   defmodule MyAppWeb.Presence do
 *     use Phoenix.Presence, otp_app: :my_app, pubsub_server: MyApp.PubSub
 *   end
 */
class AnnotatedModuleEnumerator {
	static final keepMetas:Array<String> = [
		":schema",
		":repo",
		":presence",
		":endpoint",
		":router",
		":phoenixWeb",
		":phoenixWebModule",
		":component",
		":controller",
		":channel",
		":socket",
		":liveview",
		":liveEvents",
		":phxHookNames",
		":phxEventNames",
		":application",
		":supervisor",
		":genserver"
	];

	public static function ensureKept():Null<Array<Field>> {
		#if eval
		final clsRef = Context.getLocalClass();
		if (clsRef == null)
			return null;

		final cls = clsRef.get();
		final meta = cls.meta;
		if (meta == null)
			return null;

		final fields = Context.getBuildFields();
		ModuleFieldMetadataRegistry.capture(cls, fields);
		neutralizeModuleLevelRoutesFieldInitializer(cls, fields);
		final isSchema = meta.has(":schema");
		final isLiveView = meta.has(":liveview");
		if (meta.has(":liveEvents") && !isLiveView) {
			Context.error("@:liveEvents can only be used on @:liveview classes.", cls.pos);
		}

		if (isSchema) {
			normalizeSchemaMetadata(cls);
			validateSchemaTableNameIfKnown(cls);
			maybeInjectManyToManyJoinThrough(cls, fields);
			EctoSchemaAssociationValidator.ensureAfterTypingHook();
			if (meta.has(":changeset")) {
				maybeInjectSchemaChangesetDeclaration(cls, fields);
			}
			for (field in fields) {
				if (isSchemaField(field))
					ensureSchemaFieldKept(field);
			}
		}

		if (isLiveView) {
			final generatedProtocolContracts = applyLiveEventDispatchers(cls, fields);
			if (generatedProtocolContracts.length > 0) {
				final moduleName = (cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name;
				LiveViewEventRegistry.registerContracts(moduleName, generatedProtocolContracts, cls.pos);
			}
			registerLiveViewEvents(cls, fields);
			registerLiveViewTemplatePhxUsage(cls, fields);
		}

		var shouldKeepModule = false;
		for (metaName in keepMetas) {
			if (meta.has(metaName)) {
				shouldKeepModule = true;
				break;
			}
		}

		// Module-level fields are compiled as KModuleFields classes, with metadata on
		// synthetic static fields instead of class metadata. Mirror keep detection there.
		if (!shouldKeepModule) {
			switch (cls.kind) {
				case KModuleFields(_):
					for (field in fields) {
						for (metaName in keepMetas) {
							var alternate = metaName.charAt(0) == ":" ? metaName.substr(1) : null;
							if (fieldMetaHas(field.meta, metaName) || (alternate != null && fieldMetaHas(field.meta, alternate))) {
								shouldKeepModule = true;
								break;
							}
						}
						if (shouldKeepModule)
							break;
					}
				default:
			}
		}

		if (!isSchema && !shouldKeepModule)
			return null;

		#if debug_annotated_module_enumerator
		trace('[AnnotatedModuleEnumerator] keep ' + ((cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name));
		#end

		if (!shouldKeepModule)
			return fields;

		final keepAllPublicStatic = meta.has(":controller")
			|| anyFieldHasMeta(fields, ":controller")
			|| meta.has(":channel")
			|| anyFieldHasMeta(fields, ":channel")
			|| meta.has(":socket")
			|| anyFieldHasMeta(fields, ":socket")
			|| meta.has(":router")
			|| anyFieldHasMeta(fields, ":router")
			|| anyFieldHasMeta(fields, "router")
			|| meta.has(":endpoint")
			|| anyFieldHasMeta(fields, ":endpoint")
			|| meta.has(":phoenixWeb")
			|| meta.has(":phoenixWebModule");

		final keepOnlyComponentFunctions = meta.has(":component");
		final keepNames = buildKeepNameSet(meta);

		for (field in fields) {
			if (keepAllPublicStatic) {
				ensureFieldKept(field);
				continue;
			}
			if (keepOnlyComponentFunctions) {
				if (fieldMetaHas(field.meta, ":component"))
					ensureFieldKept(field);
				continue;
			}
			if (keepNames.exists(field.name))
				ensureFieldKept(field);
		}

		if (!meta.has(":keep"))
			meta.add(":keep", [], cls.pos);
		if (!meta.has(":used"))
			meta.add(":used", [], cls.pos);
		return fields;
		#end
		return null;
	}

	static function neutralizeModuleLevelRoutesFieldInitializer(cls:haxe.macro.Type.ClassType, fields:Array<Field>):Void {
		if (fields == null || cls == null)
			return;

		var isModuleFields = switch (cls.kind) {
			case KModuleFields(_):
				true;
			default:
				false;
		};
		if (!isModuleFields)
			return;

		var classHasRouterMeta = cls.meta != null && cls.meta.has(":router");
		for (field in fields) {
			if (field == null || field.name != "routes")
				continue;

			var fieldHasRouterMeta = fieldMetaHas(field.meta, ":router") || fieldMetaHas(field.meta, "router");
			if (!classHasRouterMeta && !fieldHasRouterMeta)
				continue;

			switch (field.kind) {
				case FVar(fieldType, _):
					field.kind = FVar(fieldType, macro null);
				case FProp(get, set, fieldType, _):
					field.kind = FProp(get, set, fieldType, macro null);
				default:
			}
		}
	}

	static function applyLiveEventDispatchers(cls:haxe.macro.Type.ClassType, fields:Array<Field>):Array<LiveViewEventContract> {
		if (cls.meta == null || !cls.meta.has(":liveEvents"))
			return [];

		#if phoenix_shared
		return LiveEventDispatcherBuilder.apply(cls, fields);
		#else
		Context.error("@:liveEvents requires the phoenix_shared library support on the classpath.", cls.pos);
		return [];
		#end
	}

	static function registerLiveViewEvents(cls:haxe.macro.Type.ClassType, fields:Array<Field>):Void {
		// Register LiveView event names from `handle_event/3` switch cases.
		//
		// Supported shapes:
		// - `return switch (event) { case "increment": ... }`
		// - `switch (event) { case EventName.Increment: ... }` (compile-time string constants)
		//
		// NOTE: This is intentionally conservative. It does not attempt to infer events from
		// dynamic expressions or from template strings; it only harvests compile-time constants.
		final moduleName = (cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name;
		if (fields == null)
			return;

		for (field in fields) {
			if (field == null)
				continue;
			if (field.name != "handle_event" && field.name != "handleEvent")
				continue;

			// Prefer `@:native("handle_event")` static functions, but accept canonical name too.
			if (!isPublicStatic(field))
				continue;

			var eventVarName:Null<String> = null;
			final expr = switch (field.kind) {
				case FFun(f):
					if (f != null && f.args != null && f.args.length > 0) {
						eventVarName = f.args[0].name;
					}
					f.expr;
				default:
					null;
			}
			if (expr == null)
				continue;
			if (eventVarName == null || eventVarName.length == 0)
				eventVarName = "event";

			var events:Array<String> = [];
			collectSwitchCaseConstants(expr, eventVarName, events);
			collectEventEqualityConstants(expr, eventVarName, events);
			if (events.length > 0) {
				LiveViewEventRegistry.registerMany(moduleName, events, field.pos);
			}
		}
	}

	static function registerLiveViewTemplatePhxUsage(cls:haxe.macro.Type.ClassType, fields:Array<Field>):Void {
		// Best-effort: scan `render/1` bodies for HXX.hxx(...) templates and record `phx-*` names
		// used in those templates for editor tooling indexes.
		//
		// This intentionally operates on the *Haxe AST* (pre-Elixir pipeline) so it can run in
		// tooling-only macro contexts (e.g. docs:hxx:index) without needing to run the full compiler.
		final moduleName = (cls.pack.length > 0) ? (cls.pack.join(".") + "." + cls.name) : cls.name;
		if (fields == null)
			return;

		for (field in fields) {
			if (field == null)
				continue;
			if (field.name != "render")
				continue;
			var body:Null<Expr> = switch (field.kind) {
				case FFun(f): f != null ? f.expr : null;
				default: null;
			};
			if (body == null)
				continue;

			var templates:Array<Expr> = [];
			collectHxxTemplateArguments(body, templates);
			if (templates.length == 0)
				continue;

			for (t in templates) {
				if (t == null)
					continue;
				var buf = new StringBuf();
				collectConstTemplateText(t, buf);
				var reconstructed = buf.toString();
				if (reconstructed != null && reconstructed.length > 0) {
					scanTemplateForPhxUsage(moduleName, reconstructed, field.pos);
					scanTemplateForComponentAndSlotUsage(moduleName, reconstructed);
				}
			}
		}
	}

	static function collectHxxTemplateArguments(expr:Expr, out:Array<Expr>):Void {
		if (expr == null || expr.expr == null)
			return;
		switch (expr.expr) {
			case EReturn(e):
				collectHxxTemplateArguments(e, out);
			case ECall(fn, args):
				if (isHxxStaticCall(fn, "hxx") && args != null && args.length > 0) {
					out.push(args[0]);
				}
				collectHxxTemplateArguments(fn, out);
				if (args != null)
					for (a in args)
						collectHxxTemplateArguments(a, out);
			case EBlock(exprs):
				if (exprs != null)
					for (e in exprs)
						collectHxxTemplateArguments(e, out);
			case EIf(cond, eThen, eElse):
				collectHxxTemplateArguments(cond, out);
				collectHxxTemplateArguments(eThen, out);
				if (eElse != null)
					collectHxxTemplateArguments(eElse, out);
			case ESwitch(target, cases, def):
				collectHxxTemplateArguments(target, out);
				if (cases != null) {
					for (c in cases) {
						if (c == null)
							continue;
						if (c.values != null)
							for (v in c.values)
								collectHxxTemplateArguments(v, out);
						if (c.expr != null)
							collectHxxTemplateArguments(c.expr, out);
					}
				}
				if (def != null)
					collectHxxTemplateArguments(def, out);
			case EWhile(cond, body, _):
				collectHxxTemplateArguments(cond, out);
				collectHxxTemplateArguments(body, out);
			case EFor(it, body):
				collectHxxTemplateArguments(it, out);
				collectHxxTemplateArguments(body, out);
			case ETry(e, catches):
				collectHxxTemplateArguments(e, out);
				if (catches != null) {
					for (c in catches)
						if (c != null && c.expr != null)
							collectHxxTemplateArguments(c.expr, out);
				}
			case EBinop(_, a, b):
				collectHxxTemplateArguments(a, out);
				collectHxxTemplateArguments(b, out);
			case EUnop(_, _, a):
				collectHxxTemplateArguments(a, out);
			case EParenthesis(a):
				collectHxxTemplateArguments(a, out);
			case EMeta(_, a):
				collectHxxTemplateArguments(a, out);
			default:
		}
	}

	static function isHxxStaticCall(fn:Expr, name:String):Bool {
		if (fn == null || fn.expr == null)
			return false;
		return switch (fn.expr) {
			case EConst(CIdent(identName)):
				identName == name;
			case EField(owner, fieldName):
				if (fieldName != name)
					return false;
				if (owner == null || owner.expr == null)
					return false;
				switch (owner.expr) {
					case EConst(CIdent("HXX")):
						true;
					case EField(_, "HXX"):
						true;
					default:
						false;
				}
			case EMeta(_, inner):
				isHxxStaticCall(inner, name);
			case EParenthesis(inner):
				isHxxStaticCall(inner, name);
			default:
				false;
		};
	}

	static function collectConstTemplateText(expr:Expr, buf:StringBuf):Void {
		if (expr == null || expr.expr == null)
			return;
		switch (expr.expr) {
			case EConst(CString(s, _)):
				buf.add(s);
			case EBinop(OpAdd, a, b):
				collectConstTemplateText(a, buf);
				collectConstTemplateText(b, buf);
			case EParenthesis(inner):
				collectConstTemplateText(inner, buf);
			case EMeta(_, inner):
				collectConstTemplateText(inner, buf);
			default:
				// Only inline compile-time known string constants; skip dynamic inserts (assigns, etc.)
				var s = tryEvalConstString(expr);
				if (s != null)
					buf.add(s);
		}
	}

	static function scanTemplateForPhxUsage(moduleName:String, template:String, pos:haxe.macro.Expr.Position):Void {
		if (moduleName == null || moduleName.length == 0)
			return;
		if (template == null || template.length == 0)
			return;

		// Keep aligned with HEEx attribute validation.
		final eventAttrs:Array<String> = [
			"phx-click",
			"phx-submit",
			"phx-change",
			"phx-blur",
			"phx-focus",
			"phx-keydown",
			"phx-keyup",
			"phx-window-keydown",
			"phx-window-keyup",
			"phx-click-away"
		];

		inline function isWs(ch:String):Bool
			return ch != null && ~/^\\s$/.match(ch);
		inline function isAttrChar(ch:String):Bool {
			if (ch == null || ch.length == 0)
				return false;
			var c = ch.charCodeAt(0);
			return (c >= "A".code && c <= "Z".code) || (c >= "a".code && c <= "z".code) || (c >= "0".code && c <= "9".code) || ch == "-" || ch == "_";
		}
		function isEventAttr(name:String):Bool {
			for (ev in eventAttrs)
				if (ev == name)
					return true;
			return false;
		}

		var scanIndex = 0;
		while (scanIndex < template.length) {
			var attrStart = template.indexOf("phx-", scanIndex);
			if (attrStart == -1)
				break;
			var nameEnd = attrStart;
			while (nameEnd < template.length && isAttrChar(template.charAt(nameEnd)))
				nameEnd++;
			var attrName = template.substr(attrStart, nameEnd - attrStart);
			var isHook = attrName == "phx-hook";
			var isEvent = isEventAttr(attrName);
			if (!isHook && !isEvent) {
				scanIndex = nameEnd;
				continue;
			}

			var cursor = nameEnd;
			while (cursor < template.length && isWs(template.charAt(cursor)))
				cursor++;
			if (cursor >= template.length || template.charAt(cursor) != "=") {
				scanIndex = nameEnd;
				continue;
			}
			cursor++;
			while (cursor < template.length && isWs(template.charAt(cursor)))
				cursor++;
			if (cursor >= template.length)
				break;

			var value:Null<String> = null;
			var ch = template.charAt(cursor);
			if (ch == "\"" || ch == "'") {
				var q = ch;
				cursor++;
				var valueStart = cursor;
				while (cursor < template.length && template.charAt(cursor) != q)
					cursor++;
				if (cursor < template.length)
					value = template.substr(valueStart, cursor - valueStart);
				scanIndex = cursor + 1;
			} else if (ch == "{") {
				// Only record constant forms like {"..."} / {'...'}.
				var exprStart = cursor + 1;
				cursor++;
				var braceDepth = 1;
				while (cursor < template.length && braceDepth > 0) {
					var ch2 = template.charAt(cursor);
					if (ch2 == "{")
						braceDepth++;
					else if (ch2 == "}")
						braceDepth--;
					cursor++;
				}
				var exprEndExclusive = cursor - 1;
				if (exprEndExclusive > exprStart) {
					var inner = StringTools.trim(template.substr(exprStart, exprEndExclusive - exprStart));
					if (inner.length >= 2) {
						var q0 = inner.charAt(0);
						var q1 = inner.charAt(inner.length - 1);
						if ((q0 == "\"" && q1 == "\"") || (q0 == "'" && q1 == "'")) {
							value = inner.substr(1, inner.length - 2);
						}
					}
				}
				scanIndex = cursor;
			} else {
				// Bareword until whitespace or tag end.
				var valueStart = cursor;
				while (cursor < template.length) {
					var ch2 = template.charAt(cursor);
					if (isWs(ch2) || ch2 == ">" || ch2 == "/")
						break;
					cursor++;
				}
				if (cursor > valueStart)
					value = template.substr(valueStart, cursor - valueStart);
				scanIndex = cursor;
			}

			if (value != null) {
				var trimmed = StringTools.trim(value);
				if (trimmed.length > 0) {
					// HXX attribute interpolations commonly appear as `${ConstName.Value}` inside the
					// template string (not Haxe string interpolation). If the inner expression is a
					// compile-time string constant, record the resolved value; otherwise, skip.
					if (StringTools.startsWith(trimmed, "${") && StringTools.endsWith(trimmed, "}")) {
						var inner = StringTools.trim(trimmed.substr(2, trimmed.length - 3));
						var resolved:Null<String> = null;
						try {
							var parsed = Context.parse(inner, pos);
							resolved = tryEvalConstString(parsed);
						} catch (_:Dynamic) {
							resolved = null;
						}
						if (resolved == null) {
							// Do not record dynamic values.
							trimmed = "";
						} else {
							trimmed = StringTools.trim(resolved);
						}
					}

					if (trimmed.length > 0) {
						if (isHook)
							LiveViewTemplateUsageRegistry.registerHook(moduleName, trimmed);
						else if (isEvent)
							LiveViewTemplateUsageRegistry.registerEvent(moduleName, trimmed);
					}
				}
			}
		}
		var _ = pos;
	}

	static function scanTemplateForComponentAndSlotUsage(moduleName:String, template:String):Void {
		if (moduleName == null || moduleName.length == 0)
			return;
		if (template == null || template.length == 0)
			return;

		inline function isWs(ch:String):Bool
			return ch != null && ~/^\\s$/.match(ch);
		inline function isTagNameChar(ch:String):Bool {
			if (ch == null || ch.length == 0)
				return false;
			var c = ch.charCodeAt(0);
			return (c >= "A".code && c <= "Z".code) || (c >= "a".code && c <= "z".code) || (c >= "0".code && c <= "9".code) || ch == "-" || ch == "_"
				|| ch == "." || ch == ":";
		}

		var i = 0;
		while (i < template.length) {
			var lt = template.indexOf("<", i);
			if (lt == -1)
				break;
			if (lt + 1 >= template.length)
				break;

			var next = template.charAt(lt + 1);
			// Skip HTML comments.
			if (next == "!" && template.substr(lt, 4) == "<!--") {
				var end = template.indexOf("-->", lt + 4);
				i = end == -1 ? (lt + 4) : (end + 3);
				continue;
			}
			// Skip HEEx/EEx markers.
			if (next == "%" || next == "=") {
				i = lt + 1;
				continue;
			}

			var nameStart = lt + 1;
			if (next == "/")
				nameStart++;
			while (nameStart < template.length && isWs(template.charAt(nameStart)))
				nameStart++;
			if (nameStart >= template.length)
				break;

			var nameEnd = nameStart;
			while (nameEnd < template.length && isTagNameChar(template.charAt(nameEnd)))
				nameEnd++;
			if (nameEnd <= nameStart) {
				i = lt + 1;
				continue;
			}

			var tagName = template.substr(nameStart, nameEnd - nameStart);
			if (tagName == null || tagName.length == 0) {
				i = nameEnd;
				continue;
			}

			// Only record opening tags.
			if (next != "/") {
				if (StringTools.startsWith(tagName, ".") || tagName.indexOf(".") != -1) {
					LiveViewTemplateUsageRegistry.registerComponent(moduleName, tagName);
				} else if (StringTools.startsWith(tagName, ":") && tagName.length > 1) {
					LiveViewTemplateUsageRegistry.registerSlot(moduleName, tagName.substr(1));
				}
			}

			i = nameEnd;
		}
	}

	static function collectSwitchCaseConstants(expr:Expr, switchVarName:String, out:Array<String>):Void {
		if (expr == null)
			return;
		if (expr.expr == null)
			return;
		switch (expr.expr) {
			case EReturn(e):
				collectSwitchCaseConstants(e, switchVarName, out);
			case ESwitch(target, cases, _default):
				// Only collect events from `switch(<eventVar>)` to avoid false positives from
				// other unrelated switches inside handle_event bodies.
				if (switchTargetIsVar(target, switchVarName)) {
					for (c in cases) {
						if (c == null || c.values == null)
							continue;
						for (v in c.values) {
							var s = tryEvalConstString(v);
							if (s != null)
								out.push(s);
						}
					}
				}

				// Always recurse into case bodies to find additional event switches (e.g. nested logic).
				for (c in cases) {
					if (c == null)
						continue;
					if (c.expr != null)
						collectSwitchCaseConstants(c.expr, switchVarName, out);
				}
				if (_default != null)
					collectSwitchCaseConstants(_default, switchVarName, out);
			case EBlock(exprs):
				if (exprs != null)
					for (e in exprs)
						collectSwitchCaseConstants(e, switchVarName, out);
			case EIf(cond, eThen, eElse):
				collectSwitchCaseConstants(cond, switchVarName, out);
				collectSwitchCaseConstants(eThen, switchVarName, out);
				if (eElse != null)
					collectSwitchCaseConstants(eElse, switchVarName, out);
			case EWhile(cond, body, _):
				collectSwitchCaseConstants(cond, switchVarName, out);
				collectSwitchCaseConstants(body, switchVarName, out);
			case EFor(it, body):
				collectSwitchCaseConstants(it, switchVarName, out);
				collectSwitchCaseConstants(body, switchVarName, out);
			case ETry(e, catches):
				collectSwitchCaseConstants(e, switchVarName, out);
				if (catches != null) {
					for (c in catches)
						if (c != null && c.expr != null)
							collectSwitchCaseConstants(c.expr, switchVarName, out);
				}
			case ECall(fn, args):
				collectSwitchCaseConstants(fn, switchVarName, out);
				if (args != null)
					for (a in args)
						collectSwitchCaseConstants(a, switchVarName, out);
			case EBinop(_, a, b):
				collectSwitchCaseConstants(a, switchVarName, out);
				collectSwitchCaseConstants(b, switchVarName, out);
			case EUnop(_, _, a):
				collectSwitchCaseConstants(a, switchVarName, out);
			case EParenthesis(a):
				collectSwitchCaseConstants(a, switchVarName, out);
			case EMeta(_, a):
				collectSwitchCaseConstants(a, switchVarName, out);
			case _:
		}
	}

	static function collectEventEqualityConstants(expr:Expr, eventVarName:String, out:Array<String>):Void {
		if (expr == null || expr.expr == null)
			return;
		switch (expr.expr) {
			case EReturn(e):
				collectEventEqualityConstants(e, eventVarName, out);
			case EIf(cond, eThen, eElse):
				collectEventEqualityConstants(cond, eventVarName, out);
				collectEventEqualityConstants(eThen, eventVarName, out);
				if (eElse != null)
					collectEventEqualityConstants(eElse, eventVarName, out);
			case EBinop(OpEq, a, b):
				if (exprIsVar(a, eventVarName)) {
					var s = tryEvalConstString(b);
					if (s != null)
						out.push(s);
				} else if (exprIsVar(b, eventVarName)) {
					var s = tryEvalConstString(a);
					if (s != null)
						out.push(s);
				}
				// Recurse to find nested comparisons.
				collectEventEqualityConstants(a, eventVarName, out);
				collectEventEqualityConstants(b, eventVarName, out);
			case ESwitch(target, cases, _default):
				collectEventEqualityConstants(target, eventVarName, out);
				if (cases != null) {
					for (c in cases) {
						if (c == null)
							continue;
						if (c.values != null)
							for (v in c.values)
								collectEventEqualityConstants(v, eventVarName, out);
						if (c.expr != null)
							collectEventEqualityConstants(c.expr, eventVarName, out);
					}
				}
				if (_default != null)
					collectEventEqualityConstants(_default, eventVarName, out);
			case EBlock(exprs):
				if (exprs != null)
					for (e in exprs)
						collectEventEqualityConstants(e, eventVarName, out);
			case EWhile(cond, body, _):
				collectEventEqualityConstants(cond, eventVarName, out);
				collectEventEqualityConstants(body, eventVarName, out);
			case EFor(it, body):
				collectEventEqualityConstants(it, eventVarName, out);
				collectEventEqualityConstants(body, eventVarName, out);
			case ETry(e, catches):
				collectEventEqualityConstants(e, eventVarName, out);
				if (catches != null) {
					for (c in catches)
						if (c != null && c.expr != null)
							collectEventEqualityConstants(c.expr, eventVarName, out);
				}
			case ECall(fn, args):
				collectEventEqualityConstants(fn, eventVarName, out);
				if (args != null)
					for (a in args)
						collectEventEqualityConstants(a, eventVarName, out);
			case EUnop(_, _, a):
				collectEventEqualityConstants(a, eventVarName, out);
			case EParenthesis(a):
				collectEventEqualityConstants(a, eventVarName, out);
			case EMeta(_, a):
				collectEventEqualityConstants(a, eventVarName, out);
			default:
		}
	}

	static function exprIsVar(expr:Expr, varName:String):Bool {
		if (expr == null || expr.expr == null || varName == null || varName.length == 0)
			return false;
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name == varName;
			case EParenthesis(inner):
				exprIsVar(inner, varName);
			case EMeta(_, inner):
				exprIsVar(inner, varName);
			default:
				false;
		};
	}

	static function switchTargetIsVar(expr:Expr, varName:String):Bool {
		if (expr == null || varName == null || varName.length == 0)
			return false;
		if (expr.expr == null)
			return false;
		return switch (expr.expr) {
			case EConst(CIdent(name)):
				name == varName;
			case EParenthesis(inner):
				switchTargetIsVar(inner, varName);
			case EMeta(_, inner):
				switchTargetIsVar(inner, varName);
			default:
				false;
		};
	}

	static function normalizeSchemaMetadata(cls:haxe.macro.Type.ClassType):Void {
		// Normalize @:schema(<const>) to @:schema("...") when possible so downstream phases
		// can rely on a single representation.
		//
		// This enables typed, constant-based usage such as:
		//   enum abstract DbTable(String) { var Posts = "posts"; }
		//   @:schema(DbTable.Posts)
		//
		// NOTE: We intentionally restrict normalization to *compile-time* string constants.
		final schemaMetas = cls.meta.extract(":schema");
		if (schemaMetas == null || schemaMetas.length == 0)
			return;

		final params = schemaMetas[0].params;
		if (params == null || params.length == 0)
			return;

		final first = params[0];
		switch (first.expr) {
			case EConst(CString(_, _)):
				return;
			default:
		}

		final constString = tryEvalConstString(first);
		if (constString == null)
			return;

		schemaMetas[0].params[0] = {expr: EConst(CString(constString)), pos: first.pos};
	}

	static function validateSchemaTableNameIfKnown(cls:haxe.macro.Type.ClassType):Void {
		final tableName = extractSchemaTableName(cls);
		if (tableName == null)
			return;
		MigrationRegistry.validateTableExistsDeferred(tableName, cls.pos);
	}

	static function maybeInjectManyToManyJoinThrough(cls:haxe.macro.Type.ClassType, fields:Array<Field>):Void {
		final tableName = extractSchemaTableName(cls);
		if (tableName == null)
			return;

		for (field in fields) {
			final manyToMany = findMeta(field.meta, ":many_to_many");
			if (manyToMany == null)
				continue;

			final params = manyToMany.params;
			if (params == null)
				continue;

			// Normalize string-constant expressions inside params when possible.
			for (i in 0...params.length) {
				final s = tryEvalConstString(params[i]);
				if (s != null) {
					params[i] = {expr: EConst(CString(s)), pos: params[i].pos};
				}
			}

			// Detect existing options object and whether it contains join_through/through.
			var optionsExpr:Null<Expr> = null;
			var hasJoinThrough = false;
			var joinThroughValue:Null<String> = null;

			for (p in params) {
				switch (p.expr) {
					case EObjectDecl(pairs):
						optionsExpr = p;
						// Normalize option values like `{through: DbTable.PostsTags}` to string literals when possible.
						for (pair in pairs) {
							final s = tryEvalConstString(pair.expr);
							if (s != null) {
								pair.expr = {expr: EConst(CString(s)), pos: pair.expr.pos};
							}
						}
						for (pair in pairs) {
							if (pair.field == "join_through" || pair.field == "through") {
								hasJoinThrough = true;
								switch (pair.expr.expr) {
									case EConst(CString(v, _)):
										joinThroughValue = v;
									default:
								}
							}
						}
					default:
				}
			}

			if (hasJoinThrough) {
				if (joinThroughValue != null) {
					MigrationRegistry.validateTableExistsDeferred(joinThroughValue, field.pos);
				}
				continue;
			}

			final targetTypeName = extractAssociationTargetTypeName(field);
			if (targetTypeName == null)
				continue;

			final targetTableName = extractSchemaTableNameByTypeName(targetTypeName);
			if (targetTableName == null)
				continue;

			final expectedJoinTable = tableName + "_" + targetTableName;
			final joinThroughExpr:Expr = {expr: EConst(CString(expectedJoinTable)), pos: field.pos};
			MigrationRegistry.validateTableExistsDeferred(expectedJoinTable, field.pos);

			if (optionsExpr == null) {
				// Append a new options object.
				params.push({
					expr: EObjectDecl([
						{
							field: "through",
							expr: joinThroughExpr
						}
					]),
					pos: field.pos
				});
				continue;
			}

			// Mutate existing options object to add through: "...".
			switch (optionsExpr.expr) {
				case EObjectDecl(pairs):
					pairs.push({
						field: "through",
						expr: joinThroughExpr
					});
				default:
			}
		}
	}

	/**
	 * Inject a typed static `changeset/2` declaration for `@:schema` modules when missing.
	 *
	 * WHY:
	 * - The Elixir backend can auto-generate `def changeset/2` from schema metadata.
	 * - Without a Haxe declaration, app code cannot call `User.changeset(...)` with type-checking
	 *   unless users add manual `extern` boilerplate.
	 *
	 * HOW:
	 * - If no field named `changeset` exists, inject:
	 *   `extern public static function changeset<Attrs>(record: ThisSchema, attrs: Attrs): Changeset<ThisSchema, Attrs>;`
	 * - This keeps user-defined changesets untouched and removes boilerplate for generated ones.
	 */
	static function maybeInjectSchemaChangesetDeclaration(cls:haxe.macro.Type.ClassType, fields:Array<Field>):Void {
		for (field in fields) {
			if (field != null && field.name == "changeset") {
				return;
			}
		}

		final schemaType:ComplexType = TPath({
			pack: cls.pack.copy(),
			name: cls.name
		});

		final attrsType:ComplexType = TPath({
			pack: [],
			name: "Attrs"
		});

		final changesetType:ComplexType = TPath({
			pack: ["ecto"],
			name: "Changeset",
			params: [TPType(schemaType), TPType(attrsType)]
		});

		fields.push({
			name: "changeset",
			pos: cls.pos,
			access: [APublic, AStatic, AExtern],
			kind: FFun({
				params: [{name: "Attrs"}],
				args: [{name: "record", type: schemaType}, {name: "attrs", type: attrsType}],
				ret: changesetType,
				expr: null
			}),
			meta: [{name: ":generated", params: [macro "schema_changeset_signature"], pos: cls.pos}],
			doc: "Auto-generated typed declaration for schema changeset/2."
		});
	}

	static function extractSchemaTableName(cls:haxe.macro.Type.ClassType):Null<String> {
		final schemaMetas = cls.meta.extract(":schema");
		if (schemaMetas == null || schemaMetas.length == 0)
			return null;

		final params = schemaMetas[0].params;
		if (params == null || params.length == 0)
			return null;

		switch (params[0].expr) {
			case EConst(CString(table, _)):
				return table;
			default:
				return tryEvalConstString(params[0]);
		}
	}

	static function extractSchemaTableNameByTypeName(typeName:String):Null<String> {
		try {
			final t = Context.getType(typeName);
			return switch (t) {
				case TInst(ct, _):
					extractSchemaTableName(ct.get());
				case _:
					null;
			}
		} catch (_:Dynamic) {
			return null;
		}
	}

	static function extractAssociationTargetTypeName(field:Field):Null<String> {
		final t = switch (field.kind) {
			case FVar(ct, _) | FProp(_, _, ct, _):
				ct;
			default:
				null;
		}
		if (t == null)
			return null;

		// Handle Array<T> (has_many / many_to_many) and direct types (belongs_to / has_one).
		return switch (t) {
			case TPath(p):
				if (p.name == "Array" && p.params != null && p.params.length == 1) {
					switch (p.params[0]) {
						case TPType(TPath(inner)): inner.pack != null && inner.pack.length > 0 ? inner.pack.join(".") + "." + inner.name : inner.name;
						default:
							null;
					}
				} else {
					p.pack != null
					&& p.pack.length > 0 ? p.pack.join(".") + "." + p.name : p.name;
				}
			default:
				null;
		}
	}

	static function findMeta(meta:Null<Array<MetadataEntry>>, name:String):Null<MetadataEntry> {
		if (meta == null)
			return null;
		for (m in meta) {
			if (m.name == name)
				return m;
		}
		return null;
	}

	static function tryEvalConstString(expr:Expr):Null<String> {
		if (expr == null || expr.expr == null)
			return null;

		// Fast path: literal string.
		switch (expr.expr) {
			case EConst(CString(s, _)):
				return s;
			default:
		}

		function extractStringConst(expr:Null<TypedExpr>):Null<String> {
			if (expr == null)
				return null;
			return switch (expr.expr) {
				case TConst(TString(s)):
					s;
				case TMeta(_, inner):
					extractStringConst(inner);
				case TCast(inner, _):
					extractStringConst(inner);
				case TParenthesis(inner):
					extractStringConst(inner);
				default:
					null;
			};
		}

		function extractTypePath(expr:Expr):Null<String> {
			if (expr == null || expr.expr == null)
				return null;
			return switch (expr.expr) {
				case EConst(CIdent(name)):
					name;
				case EField(inner, name):
					var base = extractTypePath(inner);
					base != null ? (base + "." + name) : null;
				case EParenthesis(inner):
					extractTypePath(inner);
				case EMeta(_, inner):
					extractTypePath(inner);
				default:
					null;
			};
		}

		// Best-effort: if this is a type-path field access (`DbTable.Posts`), resolve by reading the
		// owner's static field expr. This avoids "Type is not ready to be accessed" failures.
		switch (expr.expr) {
			case EField(owner, fieldName):
				var ownerTypePath = extractTypePath(owner);
				if (ownerTypePath != null && ownerTypePath.length > 0 && fieldName != null && fieldName.length > 0) {
					try {
						var ownerType = Context.getType(ownerTypePath);
						switch (haxe.macro.TypeTools.follow(ownerType)) {
							case TAbstract(aRef, _):
								var abs = aRef.get();
								if (abs != null && abs.impl != null) {
									var impl = abs.impl.get();
									if (impl != null) {
										for (f in impl.statics.get()) {
											if (f != null && f.name == fieldName) {
												var s = extractStringConst(f.expr());
												if (s != null)
													return s;
											}
										}
									}
								}
							case TInst(cRef, _):
								var cls = cRef.get();
								if (cls != null) {
									for (f in cls.statics.get()) {
										if (f != null && f.name == fieldName) {
											var s = extractStringConst(f.expr());
											if (s != null)
												return s;
										}
									}
								}
							default:
						}
					} catch (_:Dynamic) {}
				}
			default:
		}

		// Fallback: ask Haxe to type the expression (can fail in some macro ordering cases).
		try {
			final typed = Context.typeExpr(expr);
			return extractStringConst(typed);
		} catch (_:Dynamic) {
			return null;
		}
	}

	static function ensureFieldKept(field:Field):Void {
		if (!isPublicStatic(field))
			return;
		if (field.meta == null)
			field.meta = [];
		if (!fieldMetaHas(field.meta, ":keep")) {
			field.meta.push({name: ":keep", params: [], pos: field.pos});
		}
	}

	static function ensureSchemaFieldKept(field:Field):Void {
		if (field.access != null) {
			for (a in field.access) {
				if (a == APrivate)
					return;
			}
		}
		if (field.meta == null)
			field.meta = [];
		if (!fieldMetaHas(field.meta, ":keep")) {
			field.meta.push({name: ":keep", params: [], pos: field.pos});
		}
	}

	static function isSchemaField(field:Field):Bool {
		return switch (field.kind) {
			case FVar(_, _) | FProp(_, _, _, _):
				fieldMetaHas(field.meta, ":field")
				|| fieldMetaHas(field.meta, ":virtual")
				|| fieldMetaHas(field.meta, ":belongs_to")
				|| fieldMetaHas(field.meta, ":has_many")
				|| fieldMetaHas(field.meta, ":has_one")
				|| fieldMetaHas(field.meta, ":many_to_many");
			default:
				false;
		}
	}

	static function isPublicStatic(field:Field):Bool {
		if (field.access == null)
			return false;
		var isStatic = false;
		for (a in field.access) {
			if (a == AStatic)
				isStatic = true;
			if (a == APrivate)
				return false;
		}
		return isStatic;
	}

	static function anyFieldHasMeta(fields:Array<Field>, metaName:String):Bool {
		if (fields == null)
			return false;
		for (field in fields) {
			if (fieldMetaHas(field.meta, metaName))
				return true;
		}
		return false;
	}

	static function fieldMetaHas(meta:Null<Array<MetadataEntry>>, metaName:String):Bool {
		if (meta == null)
			return false;
		for (m in meta) {
			if (m.name == metaName)
				return true;
		}
		return false;
	}

	static function buildKeepNameSet(classMeta:haxe.macro.Type.MetaAccess):Map<String, Bool> {
		final names:Map<String, Bool> = new Map();

		if (classMeta.has(":application")) {
			names.set("start", true);
			names.set("stop", true);
			names.set("prep_stop", true);
			names.set("prepStop", true);
			names.set("config_change", true);
			names.set("configChange", true);
		}

		if (classMeta.has(":supervisor")) {
			names.set("child_spec", true);
			names.set("childSpec", true);
			names.set("start_link", true);
			names.set("startLink", true);
			names.set("init", true);
		}

		if (classMeta.has(":genserver")) {
			names.set("child_spec", true);
			names.set("childSpec", true);
			names.set("start_link", true);
			names.set("startLink", true);
			names.set("init", true);
			names.set("handle_call", true);
			names.set("handleCall", true);
			names.set("handle_cast", true);
			names.set("handleCast", true);
			names.set("handle_info", true);
			names.set("handleInfo", true);
			names.set("handle_continue", true);
			names.set("handleContinue", true);
			names.set("terminate", true);
			names.set("code_change", true);
			names.set("codeChange", true);
		}

		if (classMeta.has(":liveview")) {
			names.set("mount", true);
			names.set("render", true);
			names.set("handle_event", true);
			names.set("handleEvent", true);
			names.set("handle_info", true);
			names.set("handleInfo", true);
			names.set("handle_params", true);
			names.set("handleParams", true);
			names.set("terminate", true);
		}

		return names;
	}
}
#end
