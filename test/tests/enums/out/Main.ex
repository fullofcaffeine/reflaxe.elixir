defmodule Main do
  @moduledoc "Main module generated from Haxe"

  # Static functions
  @doc "Function color_to_string"
  @spec color_to_string(Color.t()) :: String.t()
  def color_to_string(color) do
    case (elem((case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end), 0)) do
      0 ->
        "red"
      1 ->
        "green"
      2 ->
        "blue"
      3 ->
        g_array = elem(color, 1)
    g_array = elem(color, 2)
    g_array = elem(color, 3)
    r = g_array
    g_array = g_array
    b = g_array
    "rgb(" <> to_string(r) <> ", " <> to_string(g) <> ", " <> to_string(b) <> ")"
    end
  end

  @doc "Function get_value"
  @spec get_value(Option.t(), T.t()) :: T.t()
  def get_value(opt, default_value) do
    case (elem((case opt do :some -> 0; :none -> 1; _ -> -1 end), 0)) do
      0 ->
        (
          g_array = elem(opt, 1)
          v = g_array
          v
        )
      1 ->
        default_value
    end
  end

  @doc "Function tree_sum"
  @spec tree_sum(Tree.t()) :: integer()
  def tree_sum(tree) do
    case (elem((case tree do :leaf -> 0; :node_ -> 1; _ -> -1 end), 0)) do
      0 ->
        (
          g_array = elem(tree, 1)
          value = g_array
          value
        )
      1 ->
        (
          g_array = elem(tree, 1)
          g_array = elem(tree, 2)
          left = g_array
          right = g_array
          (Main.tree_sum(left) + Main.tree_sum(right))
        )
    end
  end

  @doc "Function describe_r_g_b"
  @spec describe_r_g_b(Color.t()) :: String.t()
  def describe_r_g_b(color) do
    temp_result = nil
    if ((case color do :red -> 0; :green -> 1; :blue -> 2; :r_g_b -> 3; _ -> -1 end == 3)) do
          temp_result = nil
    g_array = elem(color, 1)
    g_array = elem(color, 2)
    g_array = elem(color, 3)
    r = g_array
    g_array = g_array
    b = g_array
    if ((((r > 200) && (g < 50)) && (b < 50))) do
          temp_result = "mostly red"
        else
          temp_result = nil
    r = g_array
    g_array = g_array
    b = g_array
    if ((((g > 200) && (r < 50)) && (b < 50))) do
          temp_result = "mostly green"
        else
          temp_result = nil
    r = g_array
    g_array = g_array
    b = g_array
    if ((((b > 200) && (r < 50)) && (g < 50))) do
          temp_result = "mostly blue"
        else
          temp_result = "mixed color"
        end
        end
        end
        else
          temp_result = "not RGB"
        end
  end

  @doc "Function compare_trees"
  @spec compare_trees(Tree.t(), Tree.t()) :: boolean()
  def compare_trees(t1, t2) do
    case (elem((case t1 do :leaf -> 0; :node_ -> 1; _ -> -1 end), 0)) do
      0 ->
        temp_result = nil
    g_array = elem(t1, 1)
    if ((case t2 do :leaf -> 0; :node_ -> 1; _ -> -1 end == 0)) do
          (
          g_array = elem(t2, 1)
          v2 = g_array
          v1 = g_array
          temp_result = (v1 == v2)
        )
        else
          temp_result = false
        end
      1 ->
        temp_result = nil
    g_array = elem(t1, 1)
    g_array = elem(t1, 2)
    if ((case t2 do :leaf -> 0; :node_ -> 1; _ -> -1 end == 1)) do
          g_array = elem(t2, 1)
    g_array = elem(t2, 2)
    l2 = g_array
    r2 = g_array
    r1 = g_array
    l1 = g_array
    temp_result = (Main.compare_trees(l1, l2) && Main.compare_trees(r1, r2))
        else
          temp_result = false
        end
    end
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
