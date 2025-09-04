defmodule Main do
  defp main() do
    test_function("TodoApp", 42, true)
    test_optional("MyApp")
    test_optional("MyApp", 8080)
    result = build_name("Phoenix", "App")
    Log.trace(result, %{:fileName => "Main.hx", :lineNumber => 21, :className => "Main", :methodName => "main"})
    processed = process_config(%{:name => "test"})
    Log.trace(processed, %{:fileName => "Main.hx", :lineNumber => 25, :className => "Main", :methodName => "main"})
  end
  defp test_function(app_name, port, enabled) do
    config = app_name <> ".Config"
    url = "http://localhost:" <> port
    status = if enabled, do: "active", else: "inactive"
    config <> " at " <> url <> " is " <> status
  end
  defp test_optional(app_name, port) do
    actual_port = if (port != nil), do: port, else: 4000
    app_name <> " on port " <> actual_port
  end
  defp build_name(prefix, suffix) do
    prefix <> "." <> suffix
  end
  defp process_config(config) do
    Std.string(config.name)
  end
end