defmodule Mix.Tasks.Haxe.Gen.LiveTest do
  use ExUnit.Case, async: true

  test "generated liveview template is strict TSX and raw-HEEx free" do
    source =
      Mix.Tasks.Haxe.Gen.Live.generate_haxe_liveview_for_test(
        "DashboardLive",
        [{"count", "Int"}],
        ["refresh"]
      )

    assert source =~ ~S|@:hxx_mode("tsx")|
    assert source =~ "return <div"
    assert source =~ ~S(${assigns.count})
    refute source =~ "<%"
    refute source =~ "hxx("
    refute source =~ "HXX.hxx"
    refute source =~ "@:allow_heex"
  end
end
