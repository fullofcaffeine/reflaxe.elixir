defmodule Main do
  def color_to_string(color) do
    case color do
      :red ->
        "red"
      :green ->
        "green"
      :blue ->
        "blue"
      {:rgb, r, g, b} ->
        "rgb(#{r}, #{g}, #{b})"
    end
  end

  def get_value(opt, default_value) do
    case opt do
      {:some, value} ->
        value
      :none ->
        default_value
    end
  end

  def tree_sum(tree) do
    case tree do
      {:leaf, value} ->
        value
      {:node, left, right} ->
        tree_sum(left) + tree_sum(right)
    end
  end

  def describe_rgb(color) do
    case color do
      {:rgb, r, g, b} ->
        cond do
          r > 200 && g < 50 && b < 50 ->
            "mostly red"
          g > 200 && r < 50 && b < 50 ->
            "mostly green"
          b > 200 && r < 50 && g < 50 ->
            "mostly blue"
          true ->
            "mixed color"
        end
      _ ->
        "not RGB"
    end
  end

  def compare_trees(t1, t2) do
    case {t1, t2} do
      {{:leaf, v1}, {:leaf, v2}} ->
        v1 == v2
      {{:node, l1, r1}, {:node, l2, r2}} ->
        compare_trees(l1, l2) && compare_trees(r1, r2)
      _ ->
        false
    end
  end

  def main() do
    color = {:rgb, 255, 128, 0}
    Log.trace(color_to_string(color), %{:file_name => "Main.hx", :line_number => 79, :class_name => "Main", :method_name => "main"})

    some = {:some, "Hello"}
    none = :none
    Log.trace(get_value(some, "default"), %{:file_name => "Main.hx", :line_number => 84, :class_name => "Main", :method_name => "main"})
    Log.trace(get_value(none, "default"), %{:file_name => "Main.hx", :line_number => 85, :class_name => "Main", :method_name => "main"})

    tree = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(tree_sum(tree), %{:file_name => "Main.hx", :line_number => 92, :class_name => "Main", :method_name => "main"})

    Log.trace(describe_rgb({:rgb, 250, 10, 10}), %{:file_name => "Main.hx", :line_number => 95, :class_name => "Main", :method_name => "main"})

    tree2 = {:node, {:leaf, 1}, {:node, {:leaf, 2}, {:leaf, 3}}}
    Log.trace(compare_trees(tree, tree2), %{:file_name => "Main.hx", :line_number => 99, :class_name => "Main", :method_name => "main"})
  end
end