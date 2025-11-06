defmodule Main do
  def color_to_string(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, r, g, b} -> "rgb(#{(fn -> r end).()}, #{(fn -> g end).()}, #{(fn -> b end).()})"
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
          if (g2 > 200 and r2 < 50 and b2 < 50) do
            "mostly green"
          else
            if (b3 > 200 and r3 < 50 and g3 < 50), do: "mostly blue", else: "mixed color"
          end
        end
      _ -> "not RGB"
    end)
  end
  def compare_trees(t1, t2) do
    (case t1 do
      {:leaf, v2} when t2 == 0 -> v2 == v2
      {:leaf, v1} -> false
      {:node, l1, l2} when t2 == 1 -> compare_trees(l1, l2) and compare_trees(r1, r2)
      {:node, l1, l2} -> false
    end)
  end
  def main() do
    color = {:rgb, 255, 128, 0}
    _ = Log.trace(color_to_string(color), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})
    some = {:some, "Hello"}
    none = {:none}
    _ = Log.trace(get_value(some, "default"), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(get_value(none, "default"), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    tree = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    _ = Log.trace(tree_sum(tree), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "main"})
    _ = Log.trace(describe_rgb({:rgb, 250, 10, 10}), %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "main"})
    tree = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    _ = Log.trace(compare_trees(tree, tree2), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "main"})
  end
end
