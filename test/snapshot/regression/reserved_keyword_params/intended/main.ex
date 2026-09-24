defmodule Main do
  def main() do
    if (KeywordMethods.or_fn(4, 7) != 11) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Reserved method direct call must reach its declaration"]
    end
    captured = &KeywordMethods.or_fn/2
    if (captured.(2, 3) != 5) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Reserved method capture must match direct calls"]
    end
    test_end("hello", "world")
    test_after(100)
    test_rescue("exception")
    test_def("definition")
    test_defp("private")
    test_defmodule("MyModule")
    test_alias("MyAlias")
    test_receive("message")
    test_quote("expression")
    test_unquote("value")
    test_require("library")
    test_use("framework")
    test_multiple("start", "middle", "result")
    local_keyword_arrays()
  end
  def local_keyword_arrays() do
    after_ = []
    end_ = []
    rescue_ = []
    after_ = after_ ++ [1]
    end_ = end_ ++ [2]
    rescue_ = rescue_ ++ [3]
    length(after_) + length(end_) + length(rescue_)
  end
  defp test_end(start, end_param) do
    "#{start} to #{end_param}"
  end
  defp test_after(after_param) do
    after_param + 1
  end
  defp test_rescue(rescue_param) do
    "rescued: #{rescue_param}"
  end
  defp test_def(def_param) do
    "def: #{def_param}"
  end
  defp test_defp(defp_param) do
    "defp: #{defp_param}"
  end
  defp test_defmodule(defmodule_param) do
    "module: #{defmodule_param}"
  end
  defp test_alias(alias_param) do
    "alias: #{alias_param}"
  end
  defp test_receive(receive_param) do
    "received: #{receive_param}"
  end
  defp test_quote(quote_param) do
    "quoted: #{quote_param}"
  end
  defp test_unquote(unquote_param) do
    "unquoted: #{unquote_param}"
  end
  defp test_require(require_param) do
    "required: #{require_param}"
  end
  defp test_use(use_param) do
    "using: #{use_param}"
  end
  defp test_multiple(start, end_param, after_param) do
    "#{start} -> #{end_param} (after: #{after_param})"
  end
end
