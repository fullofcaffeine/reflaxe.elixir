defmodule Main do
  def main() do
    status1 = {:custom, 404}
    code1 = to_int(status1)
    Log.trace("Custom(404) -> #{code1}", %{:file_name => "Main.hx", :line_number => 15, :class_name => "Main", :method_name => "main"})
    status2 = :ok
    code2 = to_int(status2)
    Log.trace("Ok -> #{code2}", %{:file_name => "Main.hx", :line_number => 19, :class_name => "Main", :method_name => "main"})
    status3 = {:error, "Not Found"}
    msg = get_message(status3)
    Log.trace("Error message: #{msg}", %{:file_name => "Main.hx", :line_number => 24, :class_name => "Main", :method_name => "main"})
    status4 = {:redirect, "/home", true}
    info = get_redirect_info(status4)
    Log.trace("Redirect: #{info}", %{:file_name => "Main.hx", :line_number => 29, :class_name => "Main", :method_name => "main"})
  end
  defp to_int(status) do
    __elixir_switch_result_1 = case (status) do
      :ok ->
        200
      {:custom, code} ->
        code
      {:error, _msg} ->
        500
      {:redirect, _url, _permanent} ->
        301
    end
    __elixir_switch_result_1
  end
  defp get_message(status) do
    __elixir_switch_result_2 = case (status) do
      :ok ->
        "Success"
      {:custom, _code} ->
        "Custom status"
      {:error, msg} ->
        msg
      {:redirect, url, _permanent} ->
        "Redirecting to #{url}"
    end
    __elixir_switch_result_2
  end
  defp get_redirect_info(status) do
    case (status) do
      {:redirect, _, _} ->
        "URL: #{url}, Permanent: #{inspect(permanent)}"
      _ ->
        "Not a redirect"
    end
  end
end