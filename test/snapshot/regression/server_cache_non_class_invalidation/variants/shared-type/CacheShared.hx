package;

/**
 * A shared types file, like `TodoTypes.hx` in the todo-app. The props of the
 * `shared_badge` component live here, so a template check reads this file
 * without a Haxe reference. The other types are read only through ordinary
 * Haxe references.
 */
typedef CacheSharedRow = {
	var id:Int;
	var label:String;
}

/** No class reads this typedef. **/
typedef CacheSharedUnread = {
	var note:String;
}

/** Reached by the component props below, so a template check reads it. **/
enum CacheSharedTone {
	Calm;
	Loud;
}

/** The props of `CacheSharedComponents.sharedBadge`. **/
typedef CacheSharedBadgeProps = {
	var label:String;
	@:optional var tone:CacheSharedTone;

	/** Makes the props reach `Int` from the start, so row 4 adds no new fact. **/
	@:optional var count:Int;
}

/** The props of `CacheSharedComponents.sharedPanel`: an extension of a typedef in another file. **/
typedef CacheSharedPanelProps = CacheSharedPanelBase & {
	var heading:String;
}

class CacheShared {
	public static inline function scale(n:Int):Int {
		return n * 2;
	}
}
