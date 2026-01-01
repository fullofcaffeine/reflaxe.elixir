defmodule Main do
  def color_to_string(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, r, _g, b} -> "rgb(#{Kernel.to_string(r)}, #{Kernel.to_string(_g)}, #{Kernel.to_string(b)})"
    end)
  end
  def get_value(opt, default_value) do
    (case opt do
      {:some, v} -> v
      {:none} -> default_value
    end)
  end
  def tree_sum(tree) do
    (case tree do
      {:leaf, value} -> value
      {:node, left, right} -> tree_sum(left) + tree_sum(right)
    end)
  end
  def describe_rgb(color) do
    (case color do
      {:rgb, r, _, b} ->
        if (r > 200 and r < 50 and b < 50) do
          "mostly red"
        else
          if (r > 200 and r < 50 and b < 50) do
            "mostly green"
          else
            if (b > 200 and r < 50 and r < 50), do: "mostly blue", else: "mixed color"
          end
        end
      _ -> "not RGB"
    end)
  end
  def compare_trees(t1, t2) do
    (case t1 do
      {:leaf, value} when t2 == 0 ->
        v2 = value
        v1 = value
        v1 == v2
      {:leaf, _value} -> false
      {:node, left, right} when t2 == 1 ->
        l2 = left
        r2 = right
        r1 = right
        l1 = left
        compare_trees(l1, l2) and compare_trees(r1, r2)
      {:node, _left, _right} -> false
    end)
  end
  def main() do
    nil
  end
end
