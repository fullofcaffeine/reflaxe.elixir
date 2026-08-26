defmodule Log do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, Log, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, Log, key}
    Process.put(static_key, {:set, value})
    value
  end
  def __get_trace() do
    __haxe_static_get__(:trace, &trace/2)
  end
  def __set_trace(value) do
    __haxe_static_put__(:trace, value)
  end
  def format_output(v, infos) do
    str = Reflaxe.Elixir.HaxeFloat.to_string(v)
    if (Kernel.is_nil(infos)) do
      str
    else
      position = "#{infos.file_name}:#{Reflaxe.Elixir.HaxeFloat.to_string(infos.line_number)}"
      str = if (not Kernel.is_nil(Map.get(infos, :custom_params))) do
        _g = 0
        infos_custom_params = Map.get(infos, :custom_params)
        Enum.reduce(infos_custom_params, str, fn parameter, str_acc -> str_acc <> ", " <> Reflaxe.Elixir.HaxeFloat.to_string(parameter) end)
      else
        str
      end
      "#{position}: #{str}"
    end
  end
  def trace(v, infos \\ nil) do
    v = format_output(v, infos)
    IO.puts(v)
  end
end
