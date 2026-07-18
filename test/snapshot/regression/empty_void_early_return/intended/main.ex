defmodule Main do
  defp report(cancelled) do
    if (cancelled) do
      IO.puts("cancelled")
      nil
    else
      IO.puts("continued")
    end
  end
  def main() do
    report(true)
    report(false)
  end
end
