defmodule Main do
  def color_to_string(_color) do
    case (_color) do
      {:red} ->
        "red"
      {:green} ->
        "green"
      {:blue} ->
        "blue"
      {:rgb, r, g, b} ->
        g = elem(_color, 1)
        g1 = elem(_color, 2)
        g2 = elem(_color, 3)
        r = g
        g = g1
        b = g2
        "rgb(" <> Kernel.to_string(r) <> ", " <> Kernel.to_string(g) <> ", " <> Kernel.to_string(b) <> ")"
    end
  end
  def get_value(_opt, default_value) do
    case (_opt) do
      {:some, value} ->
        g = elem(_opt, 1)
        v = g
        v
      {:none} ->
        default_value
    end
  end
  def tree_sum(_tree) do
    case (_tree) do
      {:leaf, value} ->
        g = elem(_tree, 1)
        value = g
        value
      {:node, left, right} ->
        g = elem(_tree, 1)
        g1 = elem(_tree, 2)
        left = g
        right = g1
        tree_sum(left) + tree_sum(right)
    end
  end
  def describe_rgb(_color) do
    if (_color == 3) do
      g = elem(_color, 1)
      g1 = elem(_color, 2)
      g2 = elem(_color, 3)
      r = g
      g = g1
      b = g2
      if (r > 200 && g < 50 && b < 50) do
        "mostly red"
      else
        r = g
        g = g1
        b = g2
        if (g > 200 && r < 50 && b < 50) do
          "mostly green"
        else
          r = g
          g = g1
          b = g2
          if (b > 200 && r < 50 && g < 50) do
            "mostly blue"
          else
            r = g
            g = g1
            b = g2
            "mixed color"
          end
        end
      end
    else
      "not RGB"
    end
  end
  def compare_trees(_t1, _t2) do
    case (_t1) do
      {:leaf, value} ->
        g = elem(_t1, 1)
        if (_t2 == 0) do
          g1 = elem(_t2, 1)
          v2 = g1
          v1 = g
          v1 == v2
        else
          false
        end
      {:node, left, right} ->
        g = elem(_t1, 1)
        g1 = elem(_t1, 2)
        if (_t2 == 1) do
          g2 = elem(_t2, 1)
          g3 = elem(_t2, 2)
          l2 = g2
          r2 = g3
          r1 = g1
          l1 = g
          compare_trees(l1, l2) && compare_trees(r1, r2)
        else
          false
        end
    end
  end
  def main() do
    color = {:rgb, 255, 128, 0}
    Log.trace(color_to_string(color), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})
    some = {:some, "Hello"}
    none = {:none}
    Log.trace(get_value(some, "default"), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    Log.trace(get_value(none, "default"), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})
    tree = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(tree_sum(tree), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "main"})
    Log.trace(describe_r_g_b({:rgb, 250, 10, 10}), %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "main"})
    tree2 = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(compare_trees(tree, tree2), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "main"})
  end
end