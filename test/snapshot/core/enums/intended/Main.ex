defmodule Main do
  def color_to_string(color) do
    case (elem(color, 0)) do
      0 ->
        "red"
      1 ->
        "green"
      2 ->
        "blue"
      3 ->
        g = elem(color, 1)
        g1 = elem(color, 2)
        g2 = elem(color, 3)
        r = g
        g = g1
        b = g2
        "rgb(" <> r <> ", " <> g <> ", " <> b <> ")"
    end
  end
  def get_value(opt, default_value) do
    case (elem(opt, 0)) do
      0 ->
        g = elem(opt, 1)
        v = g
        v
      1 ->
        default_value
    end
  end
  def tree_sum(tree) do
    case (elem(tree, 0)) do
      0 ->
        g = elem(tree, 1)
        value = g
        value
      1 ->
        g = elem(tree, 1)
        g1 = elem(tree, 2)
        left = g
        right = g1
        tree_sum(left) + tree_sum(right)
    end
  end
  def describe_rgb(color) do
    if (elem(color, 0) == 3) do
      g = elem(color, 1)
      g1 = elem(color, 2)
      g2 = elem(color, 3)
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
            _r = g
            _g = g1
            _b = g2
            "mixed color"
          end
        end
      end
    else
      "not RGB"
    end
  end
  def compare_trees(t1, t2) do
    case (elem(t1, 0)) do
      0 ->
        g = elem(t1, 1)
        if (elem(t2, 0) == 0) do
          g1 = elem(t2, 1)
          v2 = g1
          v1 = g
          v1 == v2
        else
          false
        end
      1 ->
        g = elem(t1, 1)
        g1 = elem(t1, 2)
        if (elem(t2, 0) == 1) do
          g2 = elem(t2, 1)
          g3 = elem(t2, 2)
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
    color = {:RGB, 255, 128, 0}
    Log.trace(color_to_string(color), %{:fileName => "Main.hx", :lineNumber => 79, :className => "Main", :methodName => "main"})
    some = {:Some, "Hello"}
    none = :none
    Log.trace(get_value(some, "default"), %{:fileName => "Main.hx", :lineNumber => 84, :className => "Main", :methodName => "main"})
    Log.trace(get_value(none, "default"), %{:fileName => "Main.hx", :lineNumber => 85, :className => "Main", :methodName => "main"})
    tree = {:Node, {:Leaf, 1}, {:Node, {:Leaf, 2}, {:Leaf, 3}}}
    Log.trace(tree_sum(tree), %{:fileName => "Main.hx", :lineNumber => 92, :className => "Main", :methodName => "main"})
    Log.trace(describe_r_g_b({:RGB, 250, 10, 10}), %{:fileName => "Main.hx", :lineNumber => 95, :className => "Main", :methodName => "main"})
    tree2 = {:Node, {:Leaf, 1}, {:Node, {:Leaf, 2}, {:Leaf, 3}}}
    Log.trace(compare_trees(tree, tree2), %{:fileName => "Main.hx", :lineNumber => 99, :className => "Main", :methodName => "main"})
  end
end