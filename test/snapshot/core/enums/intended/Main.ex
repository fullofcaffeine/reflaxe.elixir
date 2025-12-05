defmodule Main do
  def color_to_string(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, _r, _g, _b} -> "rgb(#{(fn -> Kernel.to_string(r) end).()}, #{(fn -> Kernel.to_string(g) end).()}, #{(fn -> Kernel.to_string(b) end).()})"
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
      {:rgb, _, _, _} ->
        if (r > 200 and g < 50 and b < 50) do
          "mostly red"
        else
          if (g > 200 and r < 50 and b < 50) do
            "mostly green"
          else
            if (b > 200 and r < 50 and g < 50), do: "mostly blue", else: "mixed color"
          end
        end
      _ -> "not RGB"
    end)
  end
  def compare_trees(t1, t2) do
    (case t1 do
      {:leaf, v2} when t2 == 0 -> v2 == v2
      {:leaf, _v1} -> false
      {:node, l1, l2} when t2 == 1 ->
        l2 = l1
        r2 = l1
        r1 = l1
        compare_trees(l1, l2) and compare_trees(r1, r2)
      {:node, l1, l2} -> false
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
