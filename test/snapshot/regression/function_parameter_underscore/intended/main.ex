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
    config = "#{app_name}.Config"
    url = "http://localhost:#{Kernel.to_string(port)}"
    status = if (enabled), do: "active", else: "inactive"
    "#{config} at #{url} is #{status}"
  end
  defp test_optional(app_name, port) do
    actual_port = if (not Kernel.is_nil(port)), do: port, else: 4000
    "#{app_name} on port #{Kernel.to_string(actual_port)}"
  end
  defp build_name(prefix, suffix) do
    "#{prefix}.#{suffix}"
  end
  defp process_config(config) do
    config.name
  end
end
