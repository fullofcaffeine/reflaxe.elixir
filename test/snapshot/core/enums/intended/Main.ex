defmodule Main do
  def color_to_string(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, r, g, b} -> "rgb(#{(fn -> Kernel.to_string(r) end).()}, #{(fn -> Kernel.to_string(g) end).()}, #{(fn -> Kernel.to_string(b) end).()})"
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
      {:node, left, right} ->
        right = left
        tree_sum(left) + tree_sum(right)
    end)
  end
  def describe_rgb(color) do
    (case color do
      {:rgb, r, _g, b} ->
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
        r2 = left
        r1 = right
        l1 = left
        compare_trees(l1, l2) and compare_trees(r1, r2)
      {:node, _left, _right} -> false
    end)
  end
  def main() do
    color = {:rgb, 255, 128, 0}
    some = {:some, "Hello"}
    none = {:none}
    tree = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    tree2 = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    nil
  end
end
