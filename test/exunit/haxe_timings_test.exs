defmodule HaxeTimingsTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  setup do
    previous = System.get_env("HAXE_TIMINGS")

    on_exit(fn ->
      restore_env("HAXE_TIMINGS", previous)
      HaxeTimings.reset()
    end)

    :ok
  end

  test "measure passes through return values when disabled" do
    System.delete_env("HAXE_TIMINGS")

    assert HaxeTimings.enabled?() == false
    assert HaxeTimings.measure("phase.disabled", fn -> {:ok, 42} end) == {:ok, 42}

    output =
      capture_io(fn ->
        HaxeTimings.report("disabled")
      end)

    assert output == ""
  end

  test "enabled timings report measured phases" do
    System.put_env("HAXE_TIMINGS", "1")
    HaxeTimings.reset()

    assert HaxeTimings.enabled?() == true
    assert HaxeTimings.measure("phase.enabled", fn -> :done end) == :done

    output =
      capture_io(fn ->
        HaxeTimings.report("test context")
      end)

    assert output =~ "== Haxe timings: test context =="
    assert output =~ "phase.enabled:"
    assert output =~ "total wall:"
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
