package reflaxe.elixir.ast.builders;

#if (macro || reflaxe_runtime)
import haxe.macro.Type;
import reflaxe.elixir.ast.NameUtils;

using reflaxe.helpers.NameMetaHelper;

/**
 * Gives all compiler stages one target plan for a dynamic static function.
 *
 * Haxe treats `static dynamic function` as a mutable function value. The target
 * keeps the original function definition and uses separate accessors for the
 * current value. This plan prevents the definition, read, write, and call paths
 * from deriving different names.
 */
typedef DynamicStaticFieldPlanData = {
	var sourceName:String;
	var storageKey:String;
	var targetFunctionName:String;
	var arity:Int;
	var getterName:String;
	var setterName:String;
}

class DynamicStaticFieldPlan {
	public static function create(classType:ClassType, field:ClassField):DynamicStaticFieldPlanData {
		var storageKey = NameUtils.toSnakeCase(field.name);
		return {
			sourceName: field.name,
			storageKey: storageKey,
			targetFunctionName: resolveTargetFunctionName(field, classType),
			arity: functionArity(field),
			getterName: "__get_" + storageKey,
			setterName: "__set_" + storageKey
		};
	}

	/**
	 * Resolves the name that the generated Elixir function definition uses.
	 */
	public static function resolveTargetFunctionName(field:ClassField, classType:ClassType):String {
		if (field == null)
			return "";

		var nativeName = field.getNameOrNative();
		if (nativeName != null && nativeName != field.name)
			return nativeName;

		if (classType != null && classType.meta != null && classType.meta.has(":liveview")) {
			var callbackName = normalizeLiveViewCallbackName(field.name);
			if (callbackName != null)
				return callbackName;
		}

		return NameUtils.toSafeElixirFunctionName(field.name);
	}

	/**
	 * Finds an authored field that uses one reserved accessor name.
	 */
	public static function findAccessorCollision(classType:ClassType, field:ClassField):Null<String> {
		var plan = create(classType, field);
		var fields:Array<ClassField> = [];
		if (classType.fields != null)
			fields = fields.concat(classType.fields.get());
		if (classType.statics != null)
			fields = fields.concat(classType.statics.get());

		for (other in fields) {
			// Core API merging can expose another ClassField object for the same
			// logical declaration. Haxe does not permit two authored fields with the
			// same source name, so treat this as the field itself.
			if (other == field || other.name == field.name)
				continue;

			var targetName = resolveTargetFunctionName(other, classType);
			if (targetName == plan.getterName || targetName == plan.setterName)
				return targetName;

			switch (other.kind) {
				case FMethod(MethDynamic):
					var otherPlan = create(classType, other);
					if (otherPlan.getterName == plan.getterName || otherPlan.setterName == plan.setterName)
						return otherPlan.getterName == plan.getterName ? plan.getterName : plan.setterName;
				default:
			}
		}
		return null;
	}

	static function functionArity(field:ClassField):Int {
		return switch (haxe.macro.TypeTools.follow(field.type)) {
			case TFun(args, _): args.length;
			default: 0;
		};
	}

	static function normalizeLiveViewCallbackName(name:String):Null<String> {
		return switch (name) {
			case "mount": "mount";
			case "render": "render";
			case "handleEvent" | "handle_event": "handle_event";
			case "handleInfo" | "handle_info": "handle_info";
			case "handleParams" | "handle_params": "handle_params";
			case "handleAsync" | "handle_async": "handle_async";
			case "terminate": "terminate";
			default: null;
		};
	}
}
#end
