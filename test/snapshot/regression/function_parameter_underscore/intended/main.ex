defmodule Main do
  def main() do
    test_function("TodoApp", 42, true)
    test_optional("MyApp")
    test_optional("MyApp", 8080)
    result = build_name("Phoenix", "App")
    Log.trace(result, %{:file_name => "Main.hx", :line_number => 21, :class_name => "Main", :method_name => "main"})
    processed = process_config(%{:name => "test"})
    Log.trace(processed, %{:file_name => "Main.hx", :line_number => 25, :class_name => "Main", :method_name => "main"})
  end
  defp test_function(app_name, port, enabled) do
    config = app_name <> ".Config"
    url = "http://localhost:" <> Kernel.to_string(port)
    status = if enabled, do: "active", else: "inactive"
    config <> " at " <> url <> " is " <> status
  end
  defp test_optional(app_name, port) do
    actual_port = if (port != nil), do: port, else: 4000
    app_name <> " on port " <> Kernel.to_string(actual_port)
  end
  defp build_name(prefix, suffix) do
    prefix <> "." <> suffix
  end
  defp process_config(config) do
    Std.string(config.name)
  end
end

Code.require_file("std.ex", __DIR__)
Code.require_file("haxe/log.ex", __DIR__)
Code.require_file("main.ex", __DIR__)
Main.main()