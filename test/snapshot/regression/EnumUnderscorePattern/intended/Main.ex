defmodule Main do
  defp main() do
    status1 = {:custom, 404}
    code1 = Main.to_int(status1)
    Log.trace("Custom(404) -> " <> Kernel.to_string(code1), %{:file_name => "test/snapshot/regression/EnumUnderscorePattern/Main.hx", :line_number => 15, :class_name => "Main", :method_name => "main"})
    status2 = {:ok}
    code2 = Main.to_int(status2)
    Log.trace("Ok -> " <> Kernel.to_string(code2), %{:file_name => "test/snapshot/regression/EnumUnderscorePattern/Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    status3 = {:error, "Not Found"}
    msg = Main.get_message(status3)
    Log.trace("Error message: " <> msg, %{:file_name => "test/snapshot/regression/EnumUnderscorePattern/Main.hx", :line_number => 24, :class_name => "Main", :method_name => "main"})
    status4 = {:redirect, "/home", true}
    info = Main.get_redirect_info(status4)
    Log.trace("Redirect: " <> info, %{:file_name => "test/snapshot/regression/EnumUnderscorePattern/Main.hx", :line_number => 29, :class_name => "Main", :method_name => "main"})
  end
  defp to_int(status) do
    temp_result = nil
    case (status) do
      {:ok} ->
        temp_result = 200
      {:custom, code} ->
        temp_result = code
      {:error, _msg} ->
        temp_result = 500
      {:redirect, _url, _permanent} ->
        temp_result = 301
    end
    temp_result
  end
  defp get_message(status) do
    temp_result = nil
    case (status) do
      {:ok} ->
        temp_result = "Success"
      {:custom, _code} ->
        temp_result = "Custom status"
      {:error, msg} ->
        temp_result = msg
      {:redirect, url, _permanent} ->
        temp_result = "Redirecting to " <> url
    end
    temp_result
  end
  defp get_redirect_info(status) do
    temp_result = nil
    case (status) do
      {:redirect, url, permanent} ->
        temp_result = "URL: " <> url <> ", Permanent: " <> Std.string(permanent)
      _ ->
        temp_result = "Not a redirect"
    end
    temp_result
  end
end