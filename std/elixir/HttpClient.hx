package elixir;

#if (elixir || reflaxe_runtime)

import elixir.types.Term;
import haxe.functional.Result;

/**
 * HttpClient
 *
 * WHAT
 * - Minimal HTTP helper for example apps and framework integrations that need to call
 *   external APIs (e.g. OAuth), without requiring app-level `__elixir__()` escape hatches.
 *
 * WHY
 * - Example apps enforce a “no __elixir__ in app code” boundary. HTTP requests are a common
 *   integration need, and Erlang's `:httpc` is available in OTP via `:inets`.
 *
 * HOW
 * - Uses `:httpc.request/4` with `body_format: :binary` and decodes JSON via `Jason`.
 * - Returns `Result` so callers can surface failures cleanly.
 *
 * NOTES
 * - Callers should ensure the runtime starts `:inets` + `:ssl` (recommended via `extra_applications`),
 *   but this module also attempts to start them opportunistically.
 */
class HttpClient {
    extern inline public static function getJson(url: String, ?headers: Array<{_0: String, _1: String}>): Result<Term, String> {
        return cast untyped __elixir__(
            '
            (fn ->
              :inets.start()
              :ssl.start()

              headers0 = {1} || []
              headers1 = Enum.map(headers0, fn {k, v} ->
                {String.to_charlist(k), String.to_charlist(v)}
              end)

              request = {String.to_charlist({0}), headers1}

              case :httpc.request(:get, request, [], [body_format: :binary]) do
                {:ok, {{_, status, _}, _resp_headers, body}} when status >= 200 and status < 300 ->
                  case Jason.decode(body) do
                    {:ok, decoded} -> {:ok, decoded}
                    {:error, err} -> {:error, "json_decode_failed: " <> inspect(err)}
                  end

                {:ok, {{_, status, _}, _resp_headers, body}} ->
                  {:error, "http_status_" <> Integer.to_string(status) <> ": " <> Kernel.to_string(body)}

                {:error, reason} ->
                  {:error, "http_error: " <> inspect(reason)}
              end
            end).()
            ',
            url,
            headers
        );
    }

    extern inline public static function postFormJson(url: String, body: String, ?headers: Array<{_0: String, _1: String}>): Result<Term, String> {
        return cast untyped __elixir__(
            '
            (fn ->
              :inets.start()
              :ssl.start()

              headers0 = {2} || []
              headers1 = Enum.map(headers0, fn {k, v} ->
                {String.to_charlist(k), String.to_charlist(v)}
              end)

              request = {String.to_charlist({0}), headers1, String.to_charlist("application/x-www-form-urlencoded"), String.to_charlist({1})}

              case :httpc.request(:post, request, [], [body_format: :binary]) do
                {:ok, {{_, status, _}, _resp_headers, body}} when status >= 200 and status < 300 ->
                  case Jason.decode(body) do
                    {:ok, decoded} -> {:ok, decoded}
                    {:error, err} -> {:error, "json_decode_failed: " <> inspect(err)}
                  end

                {:ok, {{_, status, _}, _resp_headers, body}} ->
                  {:error, "http_status_" <> Integer.to_string(status) <> ": " <> Kernel.to_string(body)}

                {:error, reason} ->
                  {:error, "http_error: " <> inspect(reason)}
              end
            end).()
            ',
            url,
            body,
            headers
        );
    }
}

#end
