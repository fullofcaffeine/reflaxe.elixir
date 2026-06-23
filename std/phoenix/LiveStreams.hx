package phoenix;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.Tools;
#end

/**
 * On-demand typed LiveView stream names.
 *
 * WHAT
 * - `LiveStreams.of(MyAssigns)` generates typed stream-name tokens from list-shaped
 *   fields on an assigns type.
 *
 * WHY
 * - Phoenix streams are named atom collections under `assigns.streams`.
 * - The Haxe layer can preserve Phoenix's API shape while adding compile-time pairing
 *   between a stream name and the item type that belongs in that stream.
 *
 * HOW
 * - Each `Array<TItem>` field becomes `LiveStreamName<MyAssigns, TItem>`.
 * - Field names are normalized with the same `camelCase -> snake_case` behavior used
 *   by assign keys.
 * - Non-list fields are ignored because they are not stream collections.
 *
 * EXAMPLES
 * Haxe:
 *   typedef TodoAssigns = {
 *     var todos:Array<Todo>;
 *   }
 *   var streams = LiveStreams.of(TodoAssigns);
 *   socket = socket.stream(streams.todos, todos);
 *
 * Elixir:
 *   Phoenix.LiveView.stream(socket, :todos, todos)
 */
class LiveStreams {
	public static macro function of(assignsTypeRef:Expr):Expr {
		var assignsType = phoenix.macros.AssignKeysSupport.resolveAssignsType(assignsTypeRef);
		var assignFields = phoenix.macros.AssignKeysSupport.extractAssignFields(assignsType, assignsTypeRef.pos);

		var streamObjectFields:Array<ObjectField> = [];
		for (assignField in assignFields) {
			var itemType = extractStreamItemType(assignField.type);
			if (itemType == null) {
				continue;
			}

			var streamNameType = buildLiveStreamNameType(assignsType, itemType, assignField.pos);
			var snakeCaseName = phoenix.macros.AssignMacro.camelToSnake(assignField.name);
			var atomExpr:Expr = macro cast(($v{snakeCaseName} : elixir.types.Atom));
			var typedStreamExpr:Expr = {
				expr: ECheckType(atomExpr, streamNameType),
				pos: assignField.pos
			};
			streamObjectFields.push({
				field: assignField.name,
				expr: typedStreamExpr
			});
		}

		if (streamObjectFields.length == 0) {
			Context.error("LiveStreams.of(...) requires an assigns type with at least one Array<T> stream field.", assignsTypeRef.pos);
		}

		return {
			expr: EObjectDecl(streamObjectFields),
			pos: assignsTypeRef.pos
		};
	}

	#if macro
	private static function extractStreamItemType(fieldType:Type):Null<Type> {
		return switch (fieldType.follow()) {
			case TInst(ref, params) if (ref.get().pack.length == 0 && ref.get().name == "Array" && params.length == 1):
				params[0];
			case TType(ref, params):
				extractStreamItemType(ref.get().type.applyTypeParameters(ref.get().params, params));
			case _:
				null;
		};
	}

	private static function buildLiveStreamNameType(assignsType:Type, itemType:Type, fieldPos:Position):ComplexType {
		var assignsComplexType = phoenix.macros.AssignKeysSupport.requireComplexType(assignsType, fieldPos, "stream assigns type");
		var itemComplexType = phoenix.macros.AssignKeysSupport.requireComplexType(itemType, fieldPos, "stream item");
		return TPath({
			pack: ["phoenix", "types"],
			name: "LiveStreamName",
			params: [TPType(assignsComplexType), TPType(itemComplexType)]
		});
	}
	#end
}
