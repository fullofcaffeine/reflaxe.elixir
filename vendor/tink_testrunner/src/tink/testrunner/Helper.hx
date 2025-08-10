package tink.testrunner;

class Helper {
	public static inline function exit(code:Int) {
		#if travix travix.Logger.exit
		#elseif (air || air3) untyped __global__["flash.desktop.NativeApplication"].nativeApplication.exit
		#elseif flash flash.system.System.exit
		#elseif (sys || nodejs) Sys.exit
		#elseif phantomjs untyped __js__('phantom').exit
		#else throw "not supported";
		#end (code);
	}
}