defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function color_to_string"
  @spec color_to_string(Color.t()) :: String.t()
  def color_to_string(color) do
    (
          temp_result = nil
          case (elem(color, 0)) do
      0 -> temp_result = "red"
      1 -> temp_result = "green"
      2 -> temp_result = "blue"
      3 -> g = elem(color, 1)
    g = elem(color, 2)
    g = elem(color, 3)
    r = g
    g = g
    b = g
    temp_result = "rgb(" <> to_string(r) <> ", " <> to_string(nil) <> ", " <> to_string(b) <> ")"
    end
          temp_result
        )
  end

  @doc "Function get_value"
  @spec get_value(Option.t(), T.t()) :: T.t()
  def get_value(opt, default_value) do
    (
          temp_result = nil
          case (elem(opt, 0)) do
      0 -> (
          g = elem(opt, 1)
          v = g
          temp_result = v
        )
      1 -> temp_result = default_value
    end
          temp_result
        )
  end

  @doc "Function tree_sum"
  @spec tree_sum(Tree.t()) :: integer()
  def tree_sum(tree) do
    (
          temp_result = nil
          case (elem(tree, 0)) do
      0 -> (
          g = elem(tree, 1)
          value = g
          temp_result = value
        )
      1 -> (
          g = elem(tree, 1)
          g = elem(tree, 2)
          left = g
          right = g
          temp_result = (Main.tree_sum(left) + Main.tree_sum(right))
        )
    end
          temp_result
        )
  end

  @doc "Function describe_r_g_b"
  @spec describe_r_g_b(Color.t()) :: String.t()
  def describe_r_g_b(color) do
    (
          temp_result = nil
          if ((elem(color, 0) == 3)) do
          g = elem(color, 1)
    g = elem(color, 2)
    g = elem(color, 3)
    r = g
    g = g
    b = g
    if ((((r > 200) && (nil < 50)) && (b < 50))) do
          temp_result = "mostly red"
        else
          (
          r = g
          g = g
          b = g
          if ((((nil > 200) && (r < 50)) && (b < 50))) do
          temp_result = "mostly green"
        else
          (
          r = g
          g = g
          b = g
          if ((((b > 200) && (r < 50)) && (nil < 50))) do
          temp_result = "mostly blue"
        else
          (
          g
          g
          g
          temp_result = "mixed color"
        )
        end
        )
        end
        )
        end
        else
          temp_result = "not RGB"
        end
          temp_result
        )
  end

  @doc "Function compare_trees"
  @spec compare_trees(Tree.t(), Tree.t()) :: boolean()
  def compare_trees(t1, t2) do
    (
          temp_result = nil
          case (elem(t1, 0)) do
      0 -> (
          g = elem(t1, 1)
          if ((elem(t2, 0) == 0)) do
          (
          g = elem(t2, 1)
          v2 = g
          v1 = g
          temp_result = (v1 == v2)
        )
        else
          temp_result = false
        end
        )
      1 -> (
          g = elem(t1, 1)
          g = elem(t1, 2)
          if ((elem(t2, 0) == 1)) do
          g = elem(t2, 1)
    g = elem(t2, 2)
    l2 = g
    r2 = g
    r1 = g
    l1 = g
    temp_result = (Main.compare_trees(l1, l2) && Main.compare_trees(r1, r2))
        else
          temp_result = false
        end
        )
    end
          temp_result
        )
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    color = Color.r_g_b(255, 128, 0)
    Log.trace(Main.color_to_string(color), %{"fileName" => "Main.hx", "lineNumber" => 79, "className" => "Main", "methodName" => "main"})
    some = Option.some("Hello")
    none = :none
    Log.trace(Main.get_value(some, "default"), %{"fileName" => "Main.hx", "lineNumber" => 84, "className" => "Main", "methodName" => "main"})
    Log.trace(Main.get_value(none, "default"), %{"fileName" => "Main.hx", "lineNumber" => 85, "className" => "Main", "methodName" => "main"})
    tree = Tree.node_(Tree.leaf(1), Tree.node_(Tree.leaf(2), Tree.leaf(3)))
    Log.trace(Main.tree_sum(tree), %{"fileName" => "Main.hx", "lineNumber" => 92, "className" => "Main", "methodName" => "main"})
    Log.trace(Main.describe_r_g_b(Color.r_g_b(250, 10, 10)), %{"fileName" => "Main.hx", "lineNumber" => 95, "className" => "Main", "methodName" => "main"})
    tree2 = Tree.node_(Tree.leaf(1), Tree.node_(Tree.leaf(2), Tree.leaf(3)))
    Log.trace(Main.compare_trees(tree, tree2), %{"fileName" => "Main.hx", "lineNumber" => 99, "className" => "Main", "methodName" => "main"})
  end

end
