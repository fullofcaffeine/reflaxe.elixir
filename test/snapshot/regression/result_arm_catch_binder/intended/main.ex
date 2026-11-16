defmodule Main do
  def main() do
    r = {:ok, "o"}
    v = "value #{catch_value(r)}"
    IO.puts(v)
    v = "reason #{catch_reason(r)}"
    IO.puts(v)
    v = "shadow #{catch_shadow(r)}"
    IO.puts(v)
    v = "dynamic #{catch_dynamic(r)}"
    IO.puts(v)
    v = "unused #{catch_unused(r)}"
    IO.puts(v)
    v = "nested #{nested_try(r)}"
    IO.puts(v)
    v = "closure #{catch_in_closure(r)}"
    IO.puts(v)
    v = "exception #{catch_exception(r)}"
    IO.puts(v)
    r = {:error, "x"}
    v = "value #{catch_value(r)}"
    IO.puts(v)
    v = "reason #{catch_reason(r)}"
    IO.puts(v)
    v = "shadow #{catch_shadow(r)}"
    IO.puts(v)
    v = "dynamic #{catch_dynamic(r)}"
    IO.puts(v)
    v = "unused #{catch_unused(r)}"
    IO.puts(v)
    v = "nested #{nested_try(r)}"
    IO.puts(v)
    v = "closure #{catch_in_closure(r)}"
    IO.puts(v)
    v = "exception #{catch_exception(r)}"
    IO.puts(v)
  end
  def catch_value(r) do
    (case r do
      {:ok, v} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {value_2, _} when is_binary(value_2) -> value_2 <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:error, reason} ->
        v = reason
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {value_2, _} when is_binary(value_2) -> value_2 <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
    end)
  end
  def catch_reason(r) do
    (case r do
      {:ok, value} ->
        v = value
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason_2, _} when is_binary(reason_2) -> reason_2 <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:error, v} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason_2, _} when is_binary(reason_2) -> reason_2 <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
    end)
  end
  def catch_shadow(r) do
    (case r do
      {:ok, value} ->
        v = value
        kept = v
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {v_2, _} when is_binary(v_2) -> v_2 <> kept
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:error, reason} ->
        v = reason
        kept = v
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {v_2, _} when is_binary(v_2) -> v_2 <> kept
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
    end)
  end
  def catch_dynamic(r) do
    (case r do
      {:ok, v} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {value, _} -> value <> v
            end)
        end
      {:error, v} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason, _} -> reason <> v
            end)
        end
    end)
  end
  def catch_unused(r) do
    (case r do
      {:ok, value} ->
        v = value
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {value_2, _} when is_binary(value_2) -> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:error, reason} ->
        v = reason
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason_2, _} when is_binary(reason_2) -> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
    end)
  end
  def nested_try(r) do
    (case r do
      {:ok, v} ->
        try do
          try do
            raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {value_2, _} when is_integer(value_2) -> "int" <> v
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
          end
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {value_2, _} when is_binary(value_2) -> value_2 <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:error, v} ->
        try do
          try do
            raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {reason_2, _} when is_integer(reason_2) -> "int" <> v
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
          end
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason_2, _} when is_binary(reason_2) -> reason_2 <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
    end)
  end
  def catch_in_closure(r) do
    (case r do
      {:ok, v} ->
        f = fn ->
          try do
            raise Reflaxe.Elixir.HaxeThrow, [value: "T"]
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {value, _} when is_binary(value) -> value <> v
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
          end
        end
        f.()
      {:error, v} ->
        f = fn ->
          try do
            raise Reflaxe.Elixir.HaxeThrow, [value: "U"]
          rescue
            haxe_exception ->
              Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
              (case {(case haxe_exception do
                %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
                _ -> haxe_exception
              end), haxe_exception} do
                {reason, _} when is_binary(reason) -> reason <> v
                _ ->
                  reraise(haxe_exception, __STACKTRACE__)
              end)
          end
        end
        f.()
    end)
  end
  def catch_exception(r) do
    (case r do
      {:ok, v} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("T", nil, nil)]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {value, _} ->
                value = Reflaxe.Elixir.HaxeThrow.normalize_caught(value)
                Reflaxe.Exception.get_message(value) <> v
            end)
        end
      {:error, v} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("U", nil, nil)]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason, _} ->
                reason = Reflaxe.Elixir.HaxeThrow.normalize_caught(reason)
                Reflaxe.Exception.get_message(reason) <> v
            end)
        end
    end)
  end
end
