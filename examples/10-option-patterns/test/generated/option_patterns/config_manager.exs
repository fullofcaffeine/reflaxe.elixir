defmodule OptionPatterns.ConfigManager do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, OptionPatterns.ConfigManager, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, OptionPatterns.ConfigManager, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def config() do
    __haxe_static_get__(:config, %{"app_name" => "OptionPatterns", "timeout" => "30", "max_connections" => "100", "debug" => "true", "database_url" => "postgres://localhost/option_patterns", "empty_value" => "", "invalid_number" => "not_a_number"})
  end
  def config(value) do
    __haxe_static_put__(:config, value)
  end
  def get(key) do
    if (Kernel.is_nil(key) or key == "") do
      {:none}
    else
      this1 = OptionPatterns.ConfigManager.config()
      value = _ = Map.get(this1, key)
      if (Kernel.is_nil(value) or value == ""), do: {:none}, else: {:some, value}
    end
  end
  def get_with_default(key, default_value) do
    OptionTools.unwrap(get(key), default_value)
  end
  def get_required(key) do
    OptionTools.to_result(get(key), "Required configuration \"#{key}\" is missing or empty")
  end
  def get_int(key) do
    option = get(key)
    _ = OptionTools.then(option, (fn -> fn value ->
  parsed = (case Integer.parse(value) do
    {num, _} -> num
    :error -> nil
  end)
  if (not Kernel.is_nil(parsed)), do: {:some, parsed}, else: {:none}
end end).())
  end
  def get_bool(key) do
    option = get(key)
    _ = OptionTools.then(option, (fn -> fn value ->
  (case String.downcase(value) do
    "0" -> {:some, false}
    "false" -> {:some, false}
    "no" -> {:some, false}
    "1" -> {:some, true}
    "true" -> {:some, true}
    "yes" -> {:some, true}
    _ -> {:none}
  end)
end end).())
  end
  def get_int_with_range(key, min, max) do
    ResultTools.flat_map(OptionTools.to_result(get_int(key), "Configuration \"#{key}\" is missing or not a valid number"), (fn -> fn value ->
      if (value < min) do
        {:error, "Configuration \"" <> key <> "\" value " <> Reflaxe.Elixir.HaxeFloat.to_string(value) <> " is below minimum " <> Reflaxe.Elixir.HaxeFloat.to_string(min)}
      else
        if (value > max), do: {:error, "Configuration \"" <> key <> "\" value " <> Reflaxe.Elixir.HaxeFloat.to_string(value) <> " is above maximum " <> Reflaxe.Elixir.HaxeFloat.to_string(max)}, else: {:ok, value}
      end
    end end).())
  end
  def get_database_url() do
    ResultTools.flat_map(get_required("database_url"), (fn -> fn url ->
      cond_value = (case :binary.match(url, "://") do
        {pos, _} -> pos
        :nomatch -> -1
      end)
      if (cond_value <= 0) do
        {:error, "Database URL must contain protocol (e.g., postgres://)"}
      else
        if (String.length(url) < 10), do: {:error, "Database URL appears to be too short"}, else: {:ok, url}
      end
    end end).())
  end
  def get_timeout() do
    ResultTools.unwrap_or(get_int_with_range("timeout", 1, 300), 30)
  end
  def is_debug_enabled() do
    OptionTools.unwrap(get_bool("debug"), false)
  end
  def get_all_set_values() do
    result = %{}
    this1 = OptionPatterns.ConfigManager.config()
    {result} = Enum.reduce_while(Map.keys(this1), {result}, fn key, {acc_result} ->
      try do
        acc_result = (case get(key) do
  {:some, value} ->
    Map.put(acc_result, key, value)
  {:none} -> acc_result
end)
        {:cont, {acc_result}}
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_result}}
        :throw, :continue ->
          {:cont, {acc_result}}
      end
    end)
    result
  end
  def validate_required(required_keys) do
    missing = Enum.filter(required_keys, (fn -> fn key ->
      (case get(key) do
        {:some, _v} -> false
        {:none} -> true
      end)
    end end).())
    if (length(missing) > 0), do: {:error, "Missing required configuration: " <> Enum.join(missing, ", ")}, else: {:ok, true}
  end
end
