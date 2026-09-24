defmodule Main do
  def color_to_string(color) do
    (case color do
      {:red} -> "red"
      {:green} -> "green"
      {:blue} -> "blue"
      {:rgb, r, g, b} -> "rgb(#{Reflaxe.Elixir.HaxeFloat.to_string(r)}, #{Reflaxe.Elixir.HaxeFloat.to_string(g)}, #{Reflaxe.Elixir.HaxeFloat.to_string(b)})"
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
      {:rgb, r, g, b} ->
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
      {:leaf, value} ->
        (case t2 do
          {:leaf, v2} ->
            v1 = value
            v1 == v2
          _ -> false
        end)
      {:node, left, right} ->
        (case t2 do
          {:node, l2, r2} ->
            r1 = right
            l1 = left
            compare_trees(l1, l2) and compare_trees(r1, r2)
          _ -> false
        end)
    end)
  end
  def main() do
    if (describe_rgb({:rgb, 250, 10, 10}) != "mostly red" or describe_rgb({:rgb, 10, 250, 10}) != "mostly green" or describe_rgb({:rgb, 10, 10, 250}) != "mostly blue" or describe_rgb({:rgb, 80, 80, 80}) != "mixed color" or describe_rgb({:red}) != "not RGB") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "RGB guards must read their own channels."]
    end
    equal_tree = {:node, {:leaf, 1}, {:leaf, 2}}
    different_tree = {:node, {:leaf, 1}, {:leaf, 3}}
    if (not compare_trees(equal_tree, equal_tree) or compare_trees(equal_tree, different_tree) or compare_trees({:leaf, 1}, equal_tree) or compare_trees(equal_tree, {:leaf, 1})) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Tree comparisons must match both receivers and their payloads."]
    end
    nil
  end
end
