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

  test "compiler diagnostics are visible only in timing mode" do
    compiler_output = "REFLAXE_ELIXIR_TIMINGS {\"total_wall_ms\":25.0}\ntotal | 0.010 | 100"

    System.delete_env("HAXE_TIMINGS")
    assert HaxeTimings.diagnostic_compiler_args() == []
    assert capture_io(fn -> HaxeTimings.report_compiler_output(compiler_output) end) == ""

    System.put_env("HAXE_TIMINGS", "1")
    assert HaxeTimings.diagnostic_compiler_args() == ["--times"]

    output = capture_io(fn -> HaxeTimings.report_compiler_output(compiler_output) end)
    assert output =~ "REFLAXE_ELIXIR_TIMINGS"
    assert output =~ "total | 0.010"
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
