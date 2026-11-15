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
