defmodule Main do
  defp test_end(start, end_param) do
    "#{(fn -> start end).()} to #{(fn -> end_param end).()}"
  end
  defp test_after(after_param) do
    after_param + 1
  end
  defp test_rescue(rescue_param) do
    "rescued: #{(fn -> rescue_param end).()}"
  end
  defp test_def(def_param) do
    "def: #{(fn -> def_param end).()}"
  end
  defp test_defp(defp_param) do
    "defp: #{(fn -> defp_param end).()}"
  end
  defp test_defmodule(defmodule_param) do
    "module: #{(fn -> defmodule_param end).()}"
  end
  defp test_alias(alias_param) do
    "alias: #{(fn -> alias_param end).()}"
  end
  defp test_receive(receive_param) do
    "received: #{(fn -> receive_param end).()}"
  end
  defp test_quote(quote_param) do
    "quoted: #{(fn -> quote_param end).()}"
  end
  defp test_unquote(unquote_param) do
    "unquoted: #{(fn -> unquote_param end).()}"
  end
  defp test_require(require_param) do
    "required: #{(fn -> require_param end).()}"
  end
  defp test_use(use_param) do
    "using: #{(fn -> use_param end).()}"
  end
  defp test_multiple(start, end_param, after_param) do
    "#{(fn -> start end).()} -> #{(fn -> end_param end).()} (after: #{(fn -> after_param end).()})"
  end
end
