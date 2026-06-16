package reflaxe.elixir.ast;

#if (macro || reflaxe_runtime)
import haxe.macro.Type.ClassType;

enum ReceiverReturnConvention {
	PureValue;
	UpdatedReceiver;
	UpdatedReceiverAndValue;
}

/**
 * Central contract for Haxe instance methods that mutate persistent receiver state.
 *
 * Elixir values are immutable, so mutating Haxe instance methods must explicitly
 * return receiver state that the caller can rebind in the same scope.
 */
class ReceiverReturnConventions {
	public static inline var META_PURE_VALUE:String = "pureValue";
	public static inline var META_UPDATED_RECEIVER:String = "updatedReceiver";
	public static inline var META_UPDATED_RECEIVER_AND_VALUE:String = "updatedReceiverAndValue";

	public static function forMethod(classPack:String, className:String, methodName:String):ReceiverReturnConvention {
		return switch [classPack, className, methodName] {
			case ["", "StringBuf", "add" | "addChar" | "addSub" | "clear"]:
				UpdatedReceiver;
			case [
				"haxe.io",
				"BytesBuffer",
				"add" | "addByte" | "addString" | "addInt32" | "addInt64" | "addFloat" | "addDouble" | "addBytes"
			]:
				UpdatedReceiver;
			case ["", "IntIterator", "next"]:
				UpdatedReceiverAndValue;
			default:
				PureValue;
		}
	}

	public static function forClassMethod(classType:ClassType, methodName:String):ReceiverReturnConvention {
		var classPack = classType.pack != null ? classType.pack.join(".") : "";
		return forMethod(classPack, classType.name, methodName);
	}

	public static function toMetadataValue(convention:ReceiverReturnConvention):String {
		return switch (convention) {
			case PureValue: META_PURE_VALUE;
			case UpdatedReceiver: META_UPDATED_RECEIVER;
			case UpdatedReceiverAndValue: META_UPDATED_RECEIVER_AND_VALUE;
		}
	}
}
#end
