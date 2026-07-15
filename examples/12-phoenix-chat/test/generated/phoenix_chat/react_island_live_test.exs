defmodule PhoenixChat.ReactIslandLiveTest do
  use ExUnit.Case
  @endpoint PhoenixChatWeb.Endpoint
  require Phoenix.ConnTest
  import Phoenix.ConnTest
  require Phoenix.LiveViewTest
  defp mount() do
    result = Phoenix.LiveViewTest.live(Phoenix.ConnTest.build_conn(), "/")
    elem(result, 1)
  end
  test "renders static component and native fallback" do
    view = mount()
    html = Phoenix.LiveViewTest.render(view)
    condition = StringTools.haxe_index_of(html, "data-name=\"PreferenceStudio\"", 0) >= 0
    assert condition
    condition = StringTools.haxe_index_of(html, "Native LiveView controls", 0) >= 0
    assert condition
    condition = StringTools.haxe_index_of(html, "phx-value-density=\"calm\"", 0) >= 0
    assert condition
  end
  test "accepts only the exact preference event payload" do
    view = mount()
    valid = Map.new()
    valid = Map.put(valid, "density", "dense")
    accepted = Phoenix.LiveViewTest.render_hook(view, "preference_changed", valid)
    condition = StringTools.haxe_index_of(accepted, "Density synchronized: Dense.", 0) >= 0
    assert condition
    invalid = Map.put(valid, "extra", true)
    rejected = Phoenix.LiveViewTest.render_hook(view, "preference_changed", invalid)
    condition = StringTools.haxe_index_of(rejected, "Preference payload rejected.", 0) >= 0
    assert condition
  end
  test "normalizes only the exact native button carriage" do
    view = mount()
    native = Map.new()
    native = native |> Map.put("density", "calm") |> Map.put("value", "")
    accepted = Phoenix.LiveViewTest.render_hook(view, "preference_changed_native", native)
    condition = StringTools.haxe_index_of(accepted, "Density synchronized: Calm.", 0) >= 0
    assert condition
    invalid = Map.put(native, "extra", true)
    rejected = Phoenix.LiveViewTest.render_hook(view, "preference_changed_native", invalid)
    condition = StringTools.haxe_index_of(rejected, "Preference payload rejected.", 0) >= 0
    assert condition
  end
end
