defmodule Main do
  defp to_int(status) do
    (case status do
      {:ok} -> 200
      {:custom, code} -> code
      {:error, __reason} -> 500
      {:redirect, __url, __permanent} -> 301
    end)
  end
  defp get_message(status) do
    (case status do
      {:ok} -> "Success"
      {:custom, __code} -> "Custom status"
      {:error, reason} -> reason
      {:redirect, url, __permanent} -> "Redirecting to #{(fn -> url end).()}"
    end)
  end
  defp get_redirect_info(status) do
    (case status do
      {:redirect, _, _} -> "URL: #{(fn -> url end).()}, Permanent: #{(fn -> inspect(permanent) end).()}"
      _ -> "Not a redirect"
    end)
  end
end
