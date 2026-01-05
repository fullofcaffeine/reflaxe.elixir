defmodule Main do
  def main() do
    status1 = {:custom, 404}
    _ = to_int(status1)
    status2 = {:ok}
    _ = to_int(status2)
    status3 = {:error, "Not Found"}
    _msg = get_message(status3)
    status4 = {:redirect, "/home", true}
    _info = get_redirect_info(status4)
    nil
  end
  defp to_int(status) do
    (case status do
      {:ok} -> 200
      {:custom, code} -> code
      {:error, _msg} -> 500
      {:redirect, _url, _permanent} -> 301
    end)
  end
  defp get_message(status) do
    (case status do
      {:ok} -> "Success"
      {:custom, _code} -> "Custom status"
      {:error, msg} -> msg
      {:redirect, url, _permanent} -> "Redirecting to #{url}"
    end)
  end
  defp get_redirect_info(status) do
    (case status do
      {:redirect, url, permanent} -> "URL: #{url}, Permanent: #{inspect(permanent)}"
      _ -> "Not a redirect"
    end)
  end
end
