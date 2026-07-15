defmodule PhoenixChat.CremaInviteLiveTest do
  use ExUnit.Case
  @endpoint PhoenixChatWeb.Endpoint
  require Phoenix.ConnTest
  import Phoenix.ConnTest
  require Phoenix.LiveViewTest
  defp mount() do
    result = Phoenix.LiveViewTest.live(Phoenix.ConnTest.build_conn(), "/crema")
    elem(result, 1)
  end
  test "renders editorial flow react island and native fallback" do
    view = mount()
    html = Phoenix.LiveViewTest.render(view)
    condition = StringTools.haxe_index_of(html, "Build in", 0) >= 0
    assert condition
    condition = StringTools.haxe_index_of(html, "data-name=\"PreferenceStudio\"", 0) >= 0
    assert condition
    condition = StringTools.haxe_index_of(html, "Use native LiveView controls", 0) >= 0
    assert condition
    condition = StringTools.haxe_index_of(html, "data-testid=\"crema-invite-form\"", 0) >= 0
    assert condition
  end
  test "invite request fails closed and never claims an external effect" do
    view = mount()
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(view, "form[phx-submit='submit_invite']"), %{name: "A", email: "wrong", project: "short"})
    invalid = Phoenix.LiveViewTest.render(view)
    condition = StringTools.haxe_index_of(invalid, "Add a name, a valid email", 0) >= 0
    assert condition
    Phoenix.LiveViewTest.render_submit(Phoenix.LiveViewTest.element(view, "form[phx-submit='submit_invite']"), %{name: "Ada Lovelace", email: "ada@example.test", project: "I am building a calmer way for research teams to compare consequential ideas."})
    valid = Phoenix.LiveViewTest.render(view)
    condition = StringTools.haxe_index_of(valid, "ready for review", 0) >= 0
    assert condition
    condition = StringTools.haxe_index_of(valid, "stopped before storage", 0) >= 0
    assert condition
  end
  test "accepts only the existing closed react event" do
    view = mount()
    valid = Map.new()
    valid = Map.put(valid, "density", "dense")
    accepted = Phoenix.LiveViewTest.render_hook(view, "preference_changed", valid)
    condition = StringTools.haxe_index_of(accepted, "Working density set to Dense.", 0) >= 0
    assert condition
    invalid = Map.put(valid, "extra", true)
    rejected = Phoenix.LiveViewTest.render_hook(view, "preference_changed", invalid)
    condition = StringTools.haxe_index_of(rejected, "Working-density payload rejected.", 0) >= 0
    assert condition
  end
  test "native fallback preserves the same choice" do
    view = mount()
    native = Map.new()
    native = native |> Map.put("density", "calm") |> Map.put("value", "")
    accepted = Phoenix.LiveViewTest.render_hook(view, "preference_changed_native", native)
    condition = StringTools.haxe_index_of(accepted, "Working density set to Calm.", 0) >= 0
    assert condition
  end
end
