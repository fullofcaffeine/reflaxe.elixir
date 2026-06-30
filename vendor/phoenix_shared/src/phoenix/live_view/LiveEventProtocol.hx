package phoenix.live_view;

#if macro
import haxe.macro.Expr;
import phoenix.live_view.macros.LiveEventProtocolModel;
#end

/**
 * Compile-time helpers for shared Phoenix LiveView event protocols.
 *
 * WHAT
 * - Reads an enum marked with `@:liveEventProtocol` and produces deterministic
 *   protocol metadata that both JS and Elixir builds can compare.
 *
 * WHY
 * - LiveView hook events cross the frontend/backend boundary. The framework
 *   needs one typed Haxe declaration that can later generate browser push
 *   helpers, server dispatch helpers, and drift-detection manifests.
 *
 * HOW
 * - `manifest(ProfileHookEvent)` validates the protocol enum and returns a
 *   stable text manifest.
 * - `hash(ProfileHookEvent)` returns the deterministic hash of that manifest.
 *
 * EXAMPLES
 *   @:liveEventProtocol
 *   enum ProfileHookEvent {
 *     @:event
 *     ClipboardCopied(message:String);
 *   }
 *
 *   static final hash = LiveEventProtocol.hash(ProfileHookEvent);
 */
class LiveEventProtocol {
	/**
	 * Validates `protocolRef` and returns its deterministic text manifest.
	 */
	public static macro function manifest(protocolRef:Expr):ExprOf<String> {
		var protocol = LiveEventProtocolModel.fromTypeRef(protocolRef);
		return macro $v{protocol.manifest};
	}

	/**
	 * Validates `protocolRef` and returns the SHA-1 hash of its manifest.
	 */
	public static macro function hash(protocolRef:Expr):ExprOf<String> {
		var protocol = LiveEventProtocolModel.fromTypeRef(protocolRef);
		return macro $v{protocol.manifestHash};
	}
}
