defmodule VisibleNames do
  def run() do
    _g = 0
    g_value = [{:ok, "o"}, {:error, "x"}]
    Enum.each(g_value, fn r ->
      v = "argument " <> argument(r, "P")
      IO.puts(v)
      v = "local " <> local(r)
      IO.puts(v)
      v = "reasonArgument " <> reason_argument(r, "why")
      IO.puts(v)
      v = "twoSwitches " <> two_switches(r, {:ok, "q"}, "P")
      IO.puts(v)
      v = "nested " <> nested(r, {:error, "z"}, "P", "W")
      IO.puts(v)
      v = "guarded " <> guarded(r, "P")
      IO.puts(v)
      v = "inLoop " <> in_loop([r, {:ok, "m"}], "P")
      IO.puts(v)
      v = "closureArgument " <> closure_argument(r)
      IO.puts(v)
      v = "loopVariable " <> loop_variable(r, ["a", "b"])
      IO.puts(v)
      v = "catchVariable " <> catch_variable(r)
      IO.puts(v)
      v = "outerBlock " <> outer_block(r, true)
      IO.puts(v)
      v = "closureValueUnread " <> closure_value_unread(r)
      IO.puts(v)
      v = "closureReasonUnread " <> Reflaxe.Elixir.HaxeFloat.to_string(closure_reason_unread(r))
      IO.puts(v)
      v = "loopReason " <> Reflaxe.Elixir.HaxeFloat.to_string(loop_reason(r, ["ab", "cde"]))
      IO.puts(v)
      v = "pushed " <> pushed(r)
      IO.puts(v)
      v = "indexSet " <> index_set(r)
      IO.puts(v)
      v = "mapSet " <> map_set(r)
      IO.puts(v)
      v = "fieldSet " <> field_set(r)
      IO.puts(v)
    end)
  end
  defp note(s) do
    IO.puts("  note " <> s)
  end
  def argument(r, value) do
    (case r do
      {:ok, v} ->
        note(v)
        "r=#{value}"
      {:error, reason} ->
        e = reason
        "err #{e}"
    end)
  end
  def local(r) do
    value = "d"
    (case r do
      {:ok, v} ->
        note(v)
        "r=#{value}"
      {:error, reason} ->
        e = reason
        "err #{e}"
    end)
  end
  def reason_argument(r, reason) do
    (case r do
      {:ok, value} ->
        v = value
        "ok #{v}"
      {:error, e} ->
        note(e)
        "r=#{reason}"
    end)
  end
  def two_switches(r, s, value) do
    (case r do
      {:ok, v} ->
        note(v)
        (case s do
          {:ok, v} ->
            note(v)
            "r=#{value}"
          {:error, reason} ->
            e = reason
            "err2 #{e}"
        end)
      {:error, reason} ->
        e = reason
        "err #{e}"
    end)
  end
  def nested(r, s, value, reason) do
    (case r do
      {:ok, v} ->
        (case s do
          {:ok, w} -> "inner #{w}"
          {:error, e} ->
            note("#{e}#{v}")
            note(value)
            "r=#{value}#{reason}"
        end)
      {:error, e} -> "err #{e}"
    end)
  end
  def guarded(r, value) do
    (case r do
      {:ok, v} ->
        cond do
          v == "o" ->
            note(v)
            "r=" <> value
          true -> "other " <> v
        end
      {:error, reason} ->
        e = reason
        "err #{e}"
    end)
  end
  def in_loop(rs, value) do
    acc = ""
    (case Enum.reduce_while(rs, {:__reflaxe_continue__, acc}, fn r, {:__reflaxe_continue__, acc_acc} ->
      (case r do
        {:ok, v} ->
          note(v)
          acc_acc = acc_acc <> value
          {:cont, {:__reflaxe_continue__, acc_acc}}
        {:error, reason} ->
          e = reason
          {:halt, {:__reflaxe_return__, "err " <> e}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, reflaxe_continue_acc} ->
        acc = reflaxe_continue_acc
        "r=#{acc}"
    end)
  end
  def closure_argument(r) do
    describe = fn value ->
      (case r do
        {:ok, v} ->
          note(v)
          "r=" <> value
        {:error, reason} ->
          e = reason
          "err " <> e
      end)
    end
    describe.("C")
  end
  def loop_variable(r, items) do
    (case Enum.reduce_while(items, {:__reflaxe_continue__, {}}, fn value, {:__reflaxe_continue__, {}} ->
      (case r do
        {:ok, v} ->
          note(v)
          {:halt, {:__reflaxe_return__, "r=" <> value}}
        {:error, reason} ->
          e = reason
          {:halt, {:__reflaxe_return__, "err " <> e}}
      end)
    end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      {:__reflaxe_continue__, {}} ->
        {} = {}
        "empty"
    end)
  end
  def catch_variable(r) do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: "boom"]
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {reason, _} when is_binary(reason) ->
            (case r do
              {:ok, value} ->
                v = value
                "ok " <> v
              {:error, e} ->
                note(e)
                "caught " <> reason
            end)
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def outer_block(r, deep) do
    value = "d"
    if (deep) do
      (case r do
        {:ok, v} ->
          note(v)
          "deep #{value}"
        {:error, reason} ->
          e = reason
          "err #{e}"
      end)
    else
      "r=#{value}"
    end
  end
  def closure_value_unread(r) do
    describe = fn value ->
      (case r do
        {:ok, _v} -> "ok /" <> value
        {:error, reason} ->
          e = reason
          "err " <> e
      end)
    end
    describe.("C")
  end
  def closure_reason_unread(r) do
    measure = fn reason ->
      (case r do
        {:ok, value} ->
          v = value
          StringTools.haxe_length(v)
        {:error, _v} -> StringTools.haxe_length(reason) * 10
      end)
    end
    measure.("why")
  end
  def loop_reason(r, reasons) do
    total = 0
    total = Enum.reduce(reasons, total, fn reason, total_acc ->
      total_acc + (case r do
        {:ok, value} ->
          v = value
          StringTools.haxe_length(v)
        {:error, _v} -> StringTools.haxe_length(reason) * 10
      end)
    end)
    total
  end
  def pushed(r) do
    value = ["d"]
    value = (case r do
      {:ok, v} ->
        note(v)
        value
      {:error, reason} ->
        e = reason
        value = value ++ [e]
        value
    end)
    "r=#{Enum.join(value, ",")}"
  end
  def index_set(r) do
    value_0 = "d"
    value_0 = (case r do
      {:ok, value} ->
        v = value
        note(v)
        value_0
      {:error, reason} ->
        e = reason
        value_0 = e
        value_0
    end)
    "r=#{value_0}"
  end
  def map_set(r) do
    value = %{}
    value = Map.put(value, "k", "d")
    value = (case r do
      {:ok, v} ->
        note(v)
        value
      {:error, reason} ->
        e = reason
        value = Map.put(value, "k", e)
        value
    end)
    "r=#{Reflaxe.Elixir.HaxeFloat.to_string(Map.get(value, "k"))}"
  end
  def field_set(r) do
    value_x = "d"
    value_x = (case r do
      {:ok, value} ->
        v = value
        note(v)
        value_x
      {:error, reason} ->
        e = reason
        value_x = e
        value_x
    end)
    "r=#{value_x}"
  end
end
