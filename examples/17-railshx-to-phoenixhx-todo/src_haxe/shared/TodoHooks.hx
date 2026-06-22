package shared;

class TodoHooks {
	public static inline var shellId:DomId = "phoenixhx-todo-list";
	public static inline var openWorkId:DomId = "open-work";
	public static inline var sessionPanelId:DomId = "phoenixhx-session-panel";
	public static inline var autofocusAttr:DataAttr = "data-phoenixhx-autofocus";
	public static inline var continueGuestTestId:TestId = "continue-guest";
	public static inline var todoItemTestId:TestId = "todo-item";

	public static inline function idSelector(value:DomId):Selector {
		return "#" + value;
	}

	public static inline function testIdSelector(value:TestId):Selector {
		return "[data-testid=\"" + value + "\"]";
	}
}

abstract DomId(String) from String to String {}
abstract DataAttr(String) from String to String {}
abstract Selector(String) from String to String {}
abstract TestId(String) from String to String {}
