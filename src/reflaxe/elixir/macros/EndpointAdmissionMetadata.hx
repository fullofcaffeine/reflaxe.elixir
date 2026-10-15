package reflaxe.elixir.macros;

#if (macro || reflaxe_runtime)
import haxe.macro.Context;
import haxe.macro.Type;
import haxe.macro.TypeTools;
import reflaxe.elixir.ast.builders.DynamicStaticFieldPlan;

/**
 * Checks an endpoint's early request callback before generating native glue.
 *
 * A router plug cannot run before Phoenix's HTTPS redirect or socket dispatch.
 * `@:endpointAdmission` selects one ordinary static Conn<T> -> Conn<T> method.
 * The endpoint transform calls it before `super(conn, opts)`, and respects halt.
 * Product policy stays in the method; this class validates only its callable shape.
 */
class EndpointAdmissionMetadata {
	/** Return the target function name, or null when no callback was selected. */
	public static function read(owner:ClassType):Null<String> {
		if (owner.meta.has(":endpointAdmission"))
			Context.error("@:endpointAdmission belongs on a static method, not a class", owner.pos);

		for (field in owner.fields.get())
			if (field.meta.has(":endpointAdmission"))
				Context.error("@:endpointAdmission requires a static method", field.pos);

		var selected:Null<ClassField> = null;
		for (field in owner.statics.get()) {
			final entries = field.meta.extract(":endpointAdmission");
			if (entries.length == 0)
				continue;
			if (!owner.meta.has(":endpoint"))
				Context.error("@:endpointAdmission requires an @:endpoint class", field.pos);
			// Gettext emits a native backend skeleton instead of the endpoint's functions.
			if (owner.meta.has(":gettext"))
				Context.error("An endpoint admission callback cannot be combined with @:gettext generation", field.pos);
			if (selected != null || entries.length != 1)
				Context.error("Only one @:endpointAdmission method is allowed per endpoint", field.pos);
			if (entries[0].params.length != 0)
				Context.error("@:endpointAdmission takes no metadata arguments", entries[0].pos);
			switch field.kind {
				case FMethod(MethNormal):
				default:
					Context.error("@:endpointAdmission requires a non-inline, non-dynamic static method", field.pos);
			}
			if (field.params.length != 0)
				Context.error("@:endpointAdmission requires a concrete connection type, not a generic method", field.pos);
			switch Context.follow(field.type) {
				case TFun(args, result)
					if (args.length == 1
						&& !args[0].opt
						&& isConn(args[0].t)
						&& isConn(result)
						&& TypeTools.toString(Context.follow(args[0].t)) == TypeTools.toString(Context.follow(result))):
				default:
					Context.error("@:endpointAdmission requires one non-optional plug.Conn<T> argument and the same return type", field.pos);
			}
			selected = field;
		}
		return selected == null ? null : DynamicStaticFieldPlan.resolveTargetFunctionName(selected, owner);
	}

	/** Check the declared abstract, without accepting its broad native Term conversion. */
	static function isConn(type:Type):Bool {
		return switch Context.follow(type) {
			case TAbstract(ref, [_]): final abstractType = ref.get(); abstractType.module == "plug.Conn" && abstractType.name == "Conn";
			default: false;
		};
	}
}
#end
