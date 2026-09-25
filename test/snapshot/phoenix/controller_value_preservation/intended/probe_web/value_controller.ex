defmodule ProbeWeb.ValueController do
  use ProbeWeb, :controller
  def cross_receiver(ignored, inner) do
    value = 70
    switch_result_1 = (case ignored do
      {:ok, _} ->
        _g = elem(ignored, 1)
        (case inner do
          {:ok, number} -> value + number
          {:error, _} -> -2
        end)
      {:error, _} -> -1
    end)
    switch_result_1
  end
  def aliases(conn, data, original) do
    initial = conn + data
    conn = original
    data = original
    conn + data + initial
  end
  def nested_ok(input, outcome) do
    (case input do
      {:ok, value} ->
        (case outcome do
          {:ok, _} -> value
          {:error, _} -> -2
        end)
      {:error, _} -> -1
    end)
  end
  def nested_error(input, outcome) do
    (case input do
      {:ok, _} -> -1
      {:error, reason} ->
        (case outcome do
          {:ok, _} -> -2
          {:error, _} -> reason
        end)
    end)
  end
  def rebind(conn) do
    conn = prepare(conn)
    conn
  end
  def nested(credential, input) do
    (case input do
      {:accepted, value} ->
        try do
          (case transform(credential, value) do
            {:accepted, result} -> result
            {:denied} -> -2
          end)
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {error, _} when is_binary(error) ->
                cond do
                  error == "expected" -> -3
                  true -> -4
                end
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:denied} -> -1
    end)
  end
  def ignored(input, request) do
    (case input do
      {:accepted, _} -> request
      {:denied} -> -1
    end)
  end
  def nested_ignored(input, outcome) do
    (case input do
      {:accepted, request} ->
        (case outcome do
          {:accepted, _} -> request
          {:denied} -> -2
        end)
      {:denied} -> -1
    end)
  end
  defp transform(credential, value) do
    if (value < 0) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "expected"]
    end
    if (credential < 0), do: {:denied}, else: {:accepted, credential + value + 7}
  end
  defp prepare(value) do
    IO.puts("prepared")
    _ = value + 7
  end
end
