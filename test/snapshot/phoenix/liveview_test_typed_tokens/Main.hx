import elixir.types.Term;
import phoenix.AssignKeys;
import phoenix.test.LiveView;
import phoenix.test.LiveViewEventName;
import phoenix.test.LiveViewTest;

typedef CounterAssigns = {
	var count:Int;
	var query:String;
}

@:phxEventNames
enum abstract CounterEvent(String) to String {
	var Increment = "increment";
	var Search = "search";
}

class Main {
	static function main() {
		var view:LiveView = cast "live-view";
		var keys = AssignKeys.of(CounterAssigns);

		var hasCount = LiveViewTest.has_assign_key(view, keys.count);
		var count:Int = LiveViewTest.get_assign_key(view, keys.count);

		view = LiveViewTest.render_click_event(view, LiveViewEventName.of(CounterEvent.Increment));
		view = LiveViewTest.render_submit_event_with(view, LiveViewEventName.of(CounterEvent.Search), cast {query: "typed"});
		var unsafeSearch:LiveViewEventName<CounterEvent> = LiveViewEventName.unsafe("search");
		view = LiveViewTest.render_change_event_with(view, unsafeSearch, cast {query: "unsafe"});

		useResults(view, hasCount, count);
	}

	static function useResults(view:LiveView, hasCount:Bool, count:Int):Term {
		return cast {view: view, hasCount: hasCount, count: count};
	}
}
