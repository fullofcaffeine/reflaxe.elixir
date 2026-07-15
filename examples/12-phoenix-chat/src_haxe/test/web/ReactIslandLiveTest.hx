package web;

import elixir.ElixirMap;
import elixir.types.Term;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewMountResult;
import phoenix.test.LiveViewTest;
import phoenix_chat_hx.frontend.PreferenceStudioContract;

/** Native LiveView proof for the closed React island and its fallback. */
@:exunit
class ReactIslandLiveTest extends TestCase {
	@:test
	public function rendersStaticComponentAndNativeFallback():Void {
		var view = mount();
		var html = LiveViewTest.render(view);
		assertTrue(html.indexOf('data-name="PreferenceStudio"') >= 0);
		assertTrue(html.indexOf("Native LiveView controls") >= 0);
		assertTrue(html.indexOf('phx-value-density="calm"') >= 0);
	}

	@:test
	public function acceptsOnlyTheExactPreferenceEventPayload():Void {
		var view = mount();
		var valid = ElixirMap.new_();
		valid = ElixirMap.put(valid, "density", "dense");
		var accepted = LiveViewTest.render_hook(view, PreferenceStudioContract.EventName, valid);
		assertTrue(accepted.indexOf("Density synchronized: Dense.") >= 0);

		var invalid = ElixirMap.put(valid, "extra", true);
		var rejected = LiveViewTest.render_hook(view, PreferenceStudioContract.EventName, invalid);
		assertTrue(rejected.indexOf("Preference payload rejected.") >= 0);
	}

	@:test
	public function normalizesOnlyTheExactNativeButtonCarriage():Void {
		var view = mount();
		var native = ElixirMap.new_();
		native = ElixirMap.put(native, "density", "calm");
		native = ElixirMap.put(native, "value", "");
		var accepted = LiveViewTest.render_hook(view, PreferenceStudioContract.NativeEventName, native);
		assertTrue(accepted.indexOf("Density synchronized: Calm.") >= 0);

		var invalid = ElixirMap.put(native, "extra", true);
		var rejected = LiveViewTest.render_hook(view, PreferenceStudioContract.NativeEventName, invalid);
		assertTrue(rejected.indexOf("Preference payload rejected.") >= 0);
	}

	static function mount():LiveView {
		var result:LiveViewMountResult = LiveViewTest.live(ConnTest.build_conn(), "/");
		return result.view();
	}
}
