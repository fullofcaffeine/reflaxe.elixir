defmodule Main do
  defp process_string(s) do
    "Processed: #{(fn -> s end).()}"
  end
  defp process_two(a, b) do
    "#{(fn -> a end).()}, #{(fn -> b end).()}"
  end
  defp process_three(a, b, c) do
    "#{(fn -> a end).()}, #{(fn -> b end).()}, #{(fn -> c end).()}"
  end
  defp process_mixed(a, b, c, d) do
    "#{(fn -> a end).()}, #{(fn -> b end).()}, #{(fn -> c end).()}, #{(fn -> d end).()}"
  end
  defp wrap_string(s) do
    "[#{(fn -> s end).()}]"
  end
end
