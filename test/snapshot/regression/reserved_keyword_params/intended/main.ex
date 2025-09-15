defmodule Main do
  defp main() do
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