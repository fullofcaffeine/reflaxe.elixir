defmodule Main do
  def main() do
    pair = {"ready", 3}
    triple = {"three", 3, true}
    quadruple = {"four", 4, true, 4.5}
    quintuple = {"five", 5, true, 5.5, "last"}
    legacy = {"legacy", 2}
    raw = {"raw", 1}
    matched = if (elem(raw, 0) == "raw") do
      value = elem(raw, 1)
      value
    else
      -1
    end
    parsed = OptionParser.parse([], parser_options())
    parsed = put_elem(parsed, 0, [])
    consume_tuples(pair, triple, quadruple, quintuple, legacy, raw, matched)
    consume_parsed(elem(parsed, 0), elem(parsed, 1), elem(parsed, 2), elem(parsed, 0))
    consume_options(complex_options("demo"))
    consume_options(complex_options(nil))
    consume_length(nullable_argv(parsed))
    consume_length(nullable_argv(nil))
  end
  defp parser_options() do
    switches = [{:yes, :boolean}, {:package_root, :string}]
    [{:strict, switches}, {:env, [{"MIX_ENV", "prod"}]}]
  end
  defp nullable_argv(parsed) do
    if (Kernel.is_nil(parsed)), do: -1, else: length(elem(parsed, 1))
  end
  defp complex_options(app_name) do
    [{:app_name, if (Kernel.is_nil(app_name)) do
      nil
    else
      Kernel.to_string(app_name)
    end}]
  end
  defp consume_tuples(_pair, _triple, _quadruple, _quintuple, _legacy, _raw, _matched) do

  end
  defp consume_parsed(_options, _argv, _invalid, _raw) do

  end
  defp consume_options(_options) do

  end
  defp consume_length(_length) do

  end
end
