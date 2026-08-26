defmodule Main do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Main, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Main, key}
    Process.put(static_key, {:set, value})
    value
  end
  def seen() do
    __haxe_static_get__(:seen, "")
  end
  def seen(value) do
    __haxe_static_put__(:seen, value)
  end
  def position() do
    __haxe_static_get__(:position, nil)
  end
  def position(value) do
    __haxe_static_put__(:position, value)
  end
  def null_failed() do
    __haxe_static_get__(:null_failed, false)
  end
  def null_failed(value) do
    __haxe_static_put__(:null_failed, value)
  end
  def ordinary_hook() do
    __haxe_static_get__(:ordinary_hook, fn value -> "ordinary:" <> value end)
  end
  def ordinary_hook(value) do
    __haxe_static_put__(:ordinary_hook, value)
  end
  def __get_hook() do
    __haxe_static_get__(:hook, &hook/1)
  end
  def __set_hook(value) do
    __haxe_static_put__(:hook, value)
  end
  def __get_renamed_zero() do
    __haxe_static_get__(:renamed_zero, &renamed_zero/0)
  end
  def __set_renamed_zero(value) do
    __haxe_static_put__(:renamed_zero, value)
  end
  def hook(value) do
    "default:#{value}"
  end
  def renamed_zero() do
    "native-default"
  end
  defp capture_trace(value, infos) do
    Main.seen(value)
    Main.position(infos)
  end
  defp null_hook_fails() do
    original = Main.__get_hook()
    Main.null_failed(false)
    Main.__set_hook(nil)
    try do
      Main.__get_hook().("unused")
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {_haxe_catch_value, _} ->
            Main.null_failed(true)
        end)
    end
    Main.__set_hook(original)
    Main.null_failed()
  end
  def main() do
    original = Main.__get_hook()
    Main.__set_hook(fn value -> "custom:" <> value end)
    v = Main.__get_hook().("value")
    IO.puts(v)
    Main.__set_hook(original)
    v = Main.__get_hook().("value")
    IO.puts(v)
    if (not null_hook_fails()) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "a null dynamic hook remained callable"]
    end
    original_native = Main.__get_renamed_zero()
    Main.__set_renamed_zero(fn -> "native-custom" end)
    if (Main.__get_renamed_zero().() != "native-custom") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "the native dynamic hook did not use its replacement"]
    end
    Main.__set_renamed_zero(original_native)
    if (Main.__get_renamed_zero().() != "native-default") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "the native dynamic hook did not restore its default"]
    end
    if (Main.ordinary_hook().("value") != "ordinary:value") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "the ordinary static function value selected its setter"]
    end
    old_trace = Log.__get_trace()
    Log.__set_trace(&capture_trace/2)
    active_trace = Log.__get_trace()
    trace_position = %{file_name: "Main.hx", line_number: 1, class_name: "Main", method_name: "main"}
    active_trace.("trace-value", trace_position)
    Log.__set_trace(old_trace)
    if (Main.seen() != "trace-value") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "dynamic callback did not update its captured value"]
    end
    if (Main.position().file_name != "Main.hx") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "dynamic callback did not preserve source position"]
    end
    IO.puts("dynamic-static-ok")
  end
end
