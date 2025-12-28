defmodule Main do
  def main() do
    _ = test_function("TodoApp", 42, true)
    _ = test_optional("MyApp", nil)
    _ = test_optional("MyApp", 8080)
    _result = build_name("Phoenix", "App")
    _processed = process_config(%{:name => "test"})
    nil
  end
  defp test_function(app_name, port, enabled) do
    config = "#{(fn -> app_name end).()}.Config"
    url = "http://localhost:#{(fn -> Kernel.to_string(port) end).()}"
    status = if (enabled), do: "active", else: "inactive"
    "#{(fn -> config end).()} at #{(fn -> url end).()} is #{(fn -> status end).()}"
  end
  defp test_optional(app_name, port) do
    actual_port = if (not Kernel.is_nil(port)), do: port, else: 4000
    "#{(fn -> app_name end).()} on port #{(fn -> Kernel.to_string(actual_port) end).()}"
  end
  defp build_name(prefix, suffix) do
    "#{(fn -> prefix end).()}.#{(fn -> suffix end).()}"
  end
  defp process_config(config) do
    config.name
  end
end
