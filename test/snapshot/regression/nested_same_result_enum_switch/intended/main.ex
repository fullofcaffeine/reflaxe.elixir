defmodule Main do
  def main() do
    values = [{:ok, "p"}, {:error, "why"}]
    others = [{:ok, "o"}, {:error, "x"}]
    Enum.each(values, fn a ->
      Enum.each(others, fn b ->
        v = "okInError " <> Reflaxe.Elixir.HaxeFloat.to_string(ok_in_error(a, b))
        IO.puts(v)
        v = "okInErrorNamed " <> Reflaxe.Elixir.HaxeFloat.to_string(ok_in_error_named(a, b))
        IO.puts(v)
        v = "bothRead " <> both_read(a, b)
        IO.puts(v)
        v = "errorInOk " <> error_in_ok(a, b)
        IO.puts(v)
        v = "statement " <> statement(a, b)
        IO.puts(v)
        v = "inClosure " <> in_closure(a, b)
        IO.puts(v)
        c = {:ok, "3"}
        v = "threeLevels " <> three_levels(a, b, c)
        IO.puts(v)
        c = {:error, "z"}
        v = "threeLevels " <> three_levels(a, b, c)
        IO.puts(v)
      end)
    end)
    r = {:ok, "o"}
    code = 0
    report_throw("rethrowInErrorArm", fn -> rethrow_in_error_arm(r, code) end)
    report_throw("rethrowInErrorArmStatement", fn -> rethrow_in_error_arm_statement(r, code) end)
    report_throw("rethrowThenReadPayload", fn -> rethrow_then_read_payload(r, code) end)
    report_throw("rethrowInOkArm", fn -> rethrow_in_ok_arm(r, code) end)
    code = 5
    report_throw("rethrowInErrorArm", fn -> rethrow_in_error_arm(r, code) end)
    report_throw("rethrowInErrorArmStatement", fn -> rethrow_in_error_arm_statement(r, code) end)
    report_throw("rethrowThenReadPayload", fn -> rethrow_then_read_payload(r, code) end)
    report_throw("rethrowInOkArm", fn -> rethrow_in_ok_arm(r, code) end)
    r = {:error, "x"}
    code = 0
    report_throw("rethrowInErrorArm", fn -> rethrow_in_error_arm(r, code) end)
    report_throw("rethrowInErrorArmStatement", fn -> rethrow_in_error_arm_statement(r, code) end)
    report_throw("rethrowThenReadPayload", fn -> rethrow_then_read_payload(r, code) end)
    report_throw("rethrowInOkArm", fn -> rethrow_in_ok_arm(r, code) end)
    code = 5
    report_throw("rethrowInErrorArm", fn -> rethrow_in_error_arm(r, code) end)
    report_throw("rethrowInErrorArmStatement", fn -> rethrow_in_error_arm_statement(r, code) end)
    report_throw("rethrowThenReadPayload", fn -> rethrow_then_read_payload(r, code) end)
    report_throw("rethrowInOkArm", fn -> rethrow_in_ok_arm(r, code) end)
  end
  defp report_throw(label, run) do
    try do
      v = label <> " returned " <> run.()
      IO.puts(v)
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {n, _} when is_integer(n) -> IO.puts(label <> " rethrown " <> Reflaxe.Elixir.HaxeFloat.to_string(n))
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def rethrow_in_error_arm(r, code) do
    (case r do
      {:ok, value} ->
        v = value
        "ok #{v}"
      {:error, e} ->
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: code]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {reason, _} when is_binary(reason) -> reason <> e
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
    end)
  end
  def rethrow_in_error_arm_statement(r, code) do
    out = "start"
    out = (case r do
      {:ok, value} ->
        v = value
        out = "ok #{v}"
        out
      {:error, reason} ->
        e = reason
        out = try do
          if (code > 0) do
            raise Reflaxe.Elixir.HaxeThrow, [value: code]
          end
          out = "no throw " <> e
          out
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            out = (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {s, _} when is_binary(s) ->
                out = "caught " <> s <> e
                out
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
                out
            end)
            out
        end
        out
    end)
    out
  end
  def rethrow_then_read_payload(r, code) do
    (case r do
      {:ok, value} ->
        v = value
        "ok #{v}"
      {:error, reason} ->
        e = reason
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: code]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {s, _} when is_binary(s) -> IO.puts(s)
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
        "after #{e}"
    end)
  end
  def rethrow_in_ok_arm(r, code) do
    (case r do
      {:ok, value} ->
        v = value
        try do
          raise Reflaxe.Elixir.HaxeThrow, [value: code]
        rescue
          haxe_exception ->
            Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
            (case {(case haxe_exception do
              %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
              _ -> haxe_exception
            end), haxe_exception} do
              {s, _} when is_binary(s) -> s <> v
              _ ->
                reraise(haxe_exception, __STACKTRACE__)
            end)
        end
      {:error, reason} ->
        e = reason
        "error #{e}"
    end)
  end
  def ok_in_error(a, b) do
    (case a do
      {:ok, _} -> -1
      {:error, reason} ->
        m = reason
        (case b do
          {:ok, value} ->
            v = value
            StringTools.haxe_length(v)
          {:error, _reason} -> StringTools.haxe_length(m) * 10
        end)
    end)
  end
  def ok_in_error_named(a, b) do
    (case a do
      {:ok, _} -> -1
      {:error, reason} ->
        (case b do
          {:ok, value} ->
            v = value
            StringTools.haxe_length(v)
          {:error, _v} -> StringTools.haxe_length(reason) * 10
        end)
    end)
  end
  def both_read(a, b) do
    (case a do
      {:ok, value} ->
        w = value
        (case b do
          {:ok, value} ->
            v = value
            "ok #{v}/#{w}"
          {:error, reason} ->
            x = reason
            "err #{x}/#{w}"
        end)
      {:error, reason} ->
        m = reason
        (case b do
          {:ok, value} ->
            v = value
            "ok #{v}/#{m}"
          {:error, reason} ->
            x = reason
            "err #{x}/#{m}"
        end)
    end)
  end
  def error_in_ok(a, b) do
    (case a do
      {:ok, value} ->
        w = value
        (case b do
          {:ok, _} -> "ok #{w}"
          {:error, reason} ->
            e = reason
            "inner error #{e}"
        end)
      {:error, _} -> "outer error"
    end)
  end
  def statement(a, b) do
    log = ""
    log = (case a do
      {:ok, value} ->
        w = value
        log = "#{log}plain #{w}"
        log
      {:error, reason} ->
        m = reason
        log = (case b do
          {:ok, value} ->
            v = value
            log = "#{log}ok #{v}"
            log
          {:error, reason} ->
            x = reason
            log = "#{log}err #{x}"
            log
        end)
        log = "#{log} after #{m}"
        log
    end)
    log
  end
  def in_closure(a, b) do
    (case a do
      {:ok, value} ->
        w = value
        "plain #{w}"
      {:error, reason} ->
        m = reason
        describe = fn inner ->
          (case inner do
            {:ok, value} ->
              v = value
              "ok " <> v
            {:error, reason} ->
              x = reason
              "err " <> x <> "/" <> m
          end)
        end
        describe.(b)
    end)
  end
  def three_levels(a, b, c) do
    (case a do
      {:ok, value} ->
        u = value
        (case b do
          {:ok, _} -> "ok #{u}"
          {:error, reason} ->
            n = reason
            (case c do
              {:ok, value} ->
                v = value
                "ok #{v}/#{n}/#{u}"
              {:error, reason} ->
                x = reason
                "err #{x}/#{n}/#{u}"
            end)
        end)
      {:error, reason} ->
        m = reason
        (case b do
          {:ok, value} ->
            w = value
            (case c do
              {:ok, value} ->
                v = value
                "ok #{v}/#{w}/#{m}"
              {:error, reason} ->
                x = reason
                "err #{x}/#{w}/#{m}"
            end)
          {:error, reason} ->
            n = reason
            (case c do
              {:ok, value} ->
                v = value
                "ok #{v}/#{n}/#{m}"
              {:error, reason} ->
                x = reason
                "err #{x}/#{n}/#{m}"
            end)
        end)
    end)
  end
end
