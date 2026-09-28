ExUnit.start()

defmodule NativeExitContractTest do
  use ExUnit.Case, async: false
  import ExUnit.CaptureLog

  test "normal values pass through and exits become a safe result" do
    assert Main.safely(fn -> "ready" end) == "ready"
    assert Main.safely(fn -> exit(:normal) end) == "unavailable"
    assert Main.safely(fn -> exit({:synthetic, "private-request"}) end) == "unavailable"
  end

  test "an unavailable server cannot leak its request through the result or logs" do
    # No process is registered under this fresh reference. The exit contains
    # the request, so this observes a real GenServer.call failure boundary.
    absent = {:global, make_ref()}
    message = {:push, %{body: "synthetic-confirmation-secret"}}
    log = capture_log(fn ->
      assert Main.safely(fn -> GenServer.call(absent, message) end) == "unavailable"
    end)
    assert log == ""
  end

  test "exceptions and native throws remain outside the exit domain" do
    assert_raise ArgumentError, "ordinary failure", fn ->
      Main.safely(fn -> raise ArgumentError, "ordinary failure" end)
    end
    assert catch_throw(Main.safely(fn -> throw(:ordinary_throw) end)) == :ordinary_throw
  end

  test "a used binder preserves the exact native reason" do
    reason = {:synthetic, make_ref()}
    assert Main.recover(fn -> exit(reason) end, fn received ->
      assert received == reason
      "recovered"
    end) == "recovered"
  end

  test "handler failures propagate instead of re-entering the same handler" do
    assert catch_exit(Main.recover(fn -> exit(:first) end, fn _ -> exit(:second) end)) == :second
    assert_raise RuntimeError, "handler failure", fn ->
      Main.recover(fn -> exit(:first) end, fn _ -> raise "handler failure" end)
    end
  end

  test "nested typed boundaries handle each native failure domain" do
    assert Main.both(fn -> "ready" end) == "ready"
    assert Main.both(fn -> exit(:failure) end) == "unavailable"
    assert Main.both(fn -> raise "failure" end) == "exception"
    assert catch_throw(Main.both(fn -> throw(:untouched) end)) == :untouched
  end

  test "assignments inside an exit handler survive the try boundary" do
    assert Main.state(fn -> "ready" end) == 2
    assert Main.state(fn -> exit(:failure) end) == 3
  end

  test "ordinary Haxe catches still let native exits and throws propagate" do
    assert catch_exit(Main.ordinary(fn -> exit(:not_an_exception) end)) == :not_an_exception
    assert catch_throw(Main.ordinary(fn -> throw(:not_an_exception) end)) == :not_an_exception
    assert Main.ordinary(fn -> raise "ordinary exception" end) == "rescued"
  end

  test "typedef aliases preserve the native exit domain" do
    assert Main.aliased(fn -> "ready" end) == "ready"
    assert Main.aliased(fn -> exit(:failure) end) == "unavailable"
    assert_raise RuntimeError, "ordinary failure", fn ->
      Main.aliased(fn -> raise "ordinary failure" end)
    end
  end
end
