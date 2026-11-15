defmodule Main do
  def main() do
    v = arm_assign("x")
    IO.puts(v)
    v = arm_assign("")
    IO.puts(v)
    v = arm_assign_two("ab")
    IO.puts(v)
    v = arm_assign_two("")
    IO.puts(v)
  end
  defp find(s) do
    if (s == ""), do: {:none}, else: {:some, s}
  end
  def arm_assign(k) do
    out = nil
    g = find(k)
    out = (case g do
      {:some, v} ->
        out = v
        out
      {:none} -> out
    end)
    out || "null"
  end
  def arm_assign_two(k) do
    g = find(k)
    out = (case g do
      {:some, v} ->
        out = "#{v}!"
        out
      {:none} ->
        out = "none"
        out
    end)
    out
  end
end
