defmodule Main do
  def main() do
    test_simple_injection()
    test_injection_with_parameters()
    test_injection_with_return()
    test_inline_injection()
  end
  defp test_simple_injection() do
    IO.puts("Simple injection test")
  end
  defp test_injection_with_parameters() do
    name = "World"
    count = 42
    IO.puts("Hello name, count: count")
  end
  defp test_injection_with_return() do
    now = DateTime.utc_now()
    IO.inspect(now)
  end
  defp inject_code(msg) do
    IO.puts(msg)
  end
  defp test_inline_injection() do
    IO.puts("Inline injection test")
  end
end