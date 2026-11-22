import CacheMixed.CacheMixedCode;
import CacheMixed.CacheMixedKind;

/**
 * Callers that make every declaration of the two mixed files visible in the
 * generated Elixir: the class, the enum, the typedef and the abstract of
 * `CacheMixed`, and the module-level function of `CacheMixedFunctions`.
 * `payloadUser` keeps the class that reads the payload typedef of
 * `CacheMixedFunctions` live.
 */
class Main {
	static function main():Void {
		final code:CacheMixedCode = 4;
		Sys.println(CacheMixed.describe(Plain));
		Sys.println(CacheMixed.describe(Marked("marked")));
		Sys.println(CacheMixed.record().label);
		Sys.println(Std.string(code.doubled()));
		Sys.println(CacheMixedFunctions.render(2));
		Sys.println(CacheMixedBystander.label());
	}

	public static function payloadUser() {
		return CacheMixedPayloadUser.combine;
	}
}
