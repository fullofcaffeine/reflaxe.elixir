defmodule HttpRuntime do
  def reset_response_headers(ref) do

                state = Process.get({:reflaxe_sys_http, ref}, %{headers: %{}, same_key: %{}, file_transfer: false})
                Process.put({:reflaxe_sys_http, ref}, %{state | headers: %{}, same_key: %{}})
                :ok

  end
  def mark_file_transfer(ref) do

                state = Process.get({:reflaxe_sys_http, ref}, %{headers: %{}, same_key: %{}, file_transfer: false})
                Process.put({:reflaxe_sys_http, ref}, %{state | file_transfer: true})
                :ok

  end
  def has_file_transfer(ref) do
    Process.get({:reflaxe_sys_http, ref}, %{file_transfer: false}).file_transfer
  end
  def store_response_headers(ref, pairs) do

                state = Process.get({:reflaxe_sys_http, ref}, %{headers: %{}, same_key: %{}})

                next_state =
                  Enum.reduce(pairs || [], state, fn {name, value}, acc ->
                    previous = Map.get(acc.headers, name)
                    same_key =
                      if is_nil(previous) do
                        acc.same_key
                      else
                        values = Map.get(acc.same_key, name, [previous])
                        Map.put(acc.same_key, name, values ++ [value])
                      end

                    %{headers: Map.put(acc.headers, name, value), same_key: same_key}
                  end)

                Process.put({:reflaxe_sys_http, ref}, next_state)
                :ok

  end
  def response_headers(ref) do
    Process.get({:reflaxe_sys_http, ref}, %{headers: %{}}).headers
  end
  def response_header_values(ref, key) do

                state = Process.get({:reflaxe_sys_http, ref}, %{headers: %{}, same_key: %{}})
                case Map.get(state.same_key, key) do
                  nil ->
                    case Map.get(state.headers, key) do
                      nil -> nil
                      value -> [value]
                    end
                  values -> values
                end

  end
  def request(method, url, headers, body_data, content_type, timeout_ms) do

                (fn ->
                  try do
                    :inets.start()
                    :ssl.start()

                    method_atom =
                      case String.upcase(method) do
                        "GET" -> :get
                        "POST" -> :post
                        "HEAD" -> :head
                        "OPTIONS" -> :options
                        "PUT" -> :put
                        "DELETE" -> :delete
                        "TRACE" -> :trace
                        "PATCH" -> :patch
                        other -> raise "sys.Http.customRequest unsupported HTTP method #{inspect(other)}"
                      end

                    header_pairs =
                      Enum.map(headers || [], fn {name, value} ->
                        {String.to_charlist(name), String.to_charlist(value)}
                      end)

                    timeout =
                      case timeout_ms do
                        value when is_integer(value) and value > 0 -> value
                        _ -> 0
                      end

                    http_options = [timeout: timeout, connect_timeout: timeout]
                    options = [body_format: :binary]
                    url_chars = String.to_charlist(url)

                    request =
                      case body_data do
                        nil ->
                          {url_chars, header_pairs}
                        body_bytes ->
                          request_content_type = content_type || "application/octet-stream"
                          {url_chars, header_pairs, String.to_charlist(request_content_type), body_bytes}
                      end

                    case :httpc.request(method_atom, request, http_options, options) do
                      {:ok, {{_, status, _}, response_headers, response_body}} ->
                        normalized_headers =
                          Enum.map(response_headers, fn {name, value} ->
                            {to_string(name), to_string(value)}
                          end)

                        {:ok, status, normalized_headers, response_body}

                      {:error, reason} ->
                        {:error, "http_error: " <> inspect(reason)}
                    end
                  rescue
                    error -> {:error, Exception.message(error)}
                  catch
                    kind, reason -> {:error, "#{kind}: #{inspect(reason)}"}
                  end
                end).()

  end
  def is_ok(result) do
    case result do {:ok, _, _, _} -> true; _ -> false end
  end
  def status(result) do
    case result do {:ok, status, _, _} -> status; _ -> 0 end
  end
  def headers(result) do
    case result do {:ok, _, headers, _} -> headers; _ -> [] end
  end
  def body(result) do
    case result do {:ok, _, _, body} -> body; _ -> <<>> end
  end
  def error_message(result) do
    case result do {:error, message} -> message; other -> "sys.Http unexpected response: " <> inspect(other) end
  end
end
