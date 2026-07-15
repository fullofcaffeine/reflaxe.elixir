package web;

import elixir.ElixirMap;
import exunit.Assert.*;
import exunit.TestCase;
import phoenix.test.ConnTest;
import phoenix.test.LiveView;
import phoenix.test.LiveViewMountResult;
import phoenix.test.LiveViewTest;
import phoenix_chat_hx.frontend.PreferenceStudioContract;

/** Native conformance for the project-local Crema LiveView surface. */
@:exunit
class CremaInviteLiveTest extends TestCase {
	@:test
	public function rendersEditorialFlowReactIslandAndNativeFallback():Void {
		var view = mount();
		var html = LiveViewTest.render(view);
		assertTrue(html.indexOf("Build in") >= 0);
		assertTrue(html.indexOf('data-name="PreferenceStudio"') >= 0);
		assertTrue(html.indexOf("Use native LiveView controls") >= 0);
		assertTrue(html.indexOf('data-testid="crema-invite-form"') >= 0);
	}

	@:test
	public function inviteRequestFailsClosedAndNeverClaimsAnExternalEffect():Void {
		var view = mount();
		LiveViewTest.render_submit(LiveViewTest.element(view, "form[phx-submit='submit_invite']"), {name: "A", email: "wrong", project: "short"});
		var invalid = LiveViewTest.render(view);
		assertTrue(invalid.indexOf("Add a name, a valid email") >= 0);

		LiveViewTest.render_submit(LiveViewTest.element(view, "form[phx-submit='submit_invite']"), {
			name: "Ada Lovelace",
			email: "ada@example.test",
			project: "I am building a calmer way for research teams to compare consequential ideas."
		});
		var valid = LiveViewTest.render(view);
		assertTrue(valid.indexOf("ready for review") >= 0);
		assertTrue(valid.indexOf("stopped before storage") >= 0);
	}

	@:test
	public function acceptsOnlyTheExistingClosedReactEvent():Void {
		var view = mount();
		var valid = ElixirMap.new_();
		valid = ElixirMap.put(valid, "density", "dense");
		var accepted = LiveViewTest.render_hook(view, PreferenceStudioContract.EventName, valid);
		assertTrue(accepted.indexOf("Working density set to Dense.") >= 0);

		var invalid = ElixirMap.put(valid, "extra", true);
		var rejected = LiveViewTest.render_hook(view, PreferenceStudioContract.EventName, invalid);
		assertTrue(rejected.indexOf("Working-density payload rejected.") >= 0);
	}

	@:test
	public function nativeFallbackPreservesTheSameChoice():Void {
		var view = mount();
		var native = ElixirMap.new_();
		native = ElixirMap.put(native, "density", "calm");
		native = ElixirMap.put(native, "value", "");
		var accepted = LiveViewTest.render_hook(view, PreferenceStudioContract.NativeEventName, native);
		assertTrue(accepted.indexOf("Working density set to Calm.") >= 0);
	}

	static function mount():LiveView {
		var result:LiveViewMountResult = LiveViewTest.live(ConnTest.build_conn(), "/crema");
		return result.view();
	}
}
