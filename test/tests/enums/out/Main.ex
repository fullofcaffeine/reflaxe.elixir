defmodule Main do
  use Bitwise
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function color_to_string"
  @spec color_to_string(Color.t()) :: String.t()
  def color_to_string(arg0) do
    (
  temp_result = nil
  case (# TODO: Implement expression type: TEnumIndex) do
  0 ->
    temp_result = "red"
  1 ->
    temp_result = "green"
  2 ->
    temp_result = "blue"
  3 ->
    (
  _g = # TODO: Implement expression type: TEnumParameter
  _g1 = # TODO: Implement expression type: TEnumParameter
  _g2 = # TODO: Implement expression type: TEnumParameter
  (
  r = _g
  g = _g1
  b = _g2
  temp_result = "rgb(" <> r <> ", " <> g <> ", " <> b <> ")"
)
)
end
  temp_result
)
  end

  @doc "Function get_value"
  @spec get_value(Option.t(), T.t()) :: T.t()
  def get_value(arg0, arg1) do
    (
  temp_result = nil
  case (# TODO: Implement expression type: TEnumIndex) do
  0 ->
    (
  _g = # TODO: Implement expression type: TEnumParameter
  (
  v = _g
  temp_result = v
)
)
  1 ->
    temp_result = arg1
end
  temp_result
)
  end

  @doc "Function tree_sum"
  @spec tree_sum(Tree.t()) :: integer()
  def tree_sum(arg0) do
    (
  temp_result = nil
  case (# TODO: Implement expression type: TEnumIndex) do
  0 ->
    (
  _g = # TODO: Implement expression type: TEnumParameter
  (
  value = _g
  temp_result = value
)
)
  1 ->
    (
  _g = # TODO: Implement expression type: TEnumParameter
  _g1 = # TODO: Implement expression type: TEnumParameter
  (
  left = _g
  right = _g1
  temp_result = Main.treeSum(left) + Main.treeSum(right)
)
)
end
  temp_result
)
  end

  @doc "Function describe_r_g_b"
  @spec describe_r_g_b(Color.t()) :: String.t()
  def describe_r_g_b(arg0) do
    (
  temp_result = nil
  if (# TODO: Implement expression type: TEnumIndex == 3), do: (
  _g = # TODO: Implement expression type: TEnumParameter
  _g1 = # TODO: Implement expression type: TEnumParameter
  _g2 = # TODO: Implement expression type: TEnumParameter
  (
  r = _g
  g = _g1
  b = _g2
  if (r > 200 && g < 50 && b < 50), do: temp_result = "mostly red", else: (
  r2 = _g
  g2 = _g1
  b2 = _g2
  if (g2 > 200 && r2 < 50 && b2 < 50), do: temp_result = "mostly green", else: (
  r3 = _g
  g3 = _g1
  b3 = _g2
  if (b3 > 200 && r3 < 50 && g3 < 50), do: temp_result = "mostly blue", else: (
  r4 = _g
  g4 = _g1
  b4 = _g2
  temp_result = "mixed color"
)
)
)
)
), else: temp_result = "not RGB"
  temp_result
)
  end

  @doc "Function compare_trees"
  @spec compare_trees(Tree.t(), Tree.t()) :: boolean()
  def compare_trees(arg0, arg1) do
    (
  temp_result = nil
  case (# TODO: Implement expression type: TEnumIndex) do
  0 ->
    (
  _g = # TODO: Implement expression type: TEnumParameter
  if (# TODO: Implement expression type: TEnumIndex == 0), do: (
  _g1 = # TODO: Implement expression type: TEnumParameter
  (
  v2 = _g1
  v1 = _g
  temp_result = v1 == v2
)
), else: temp_result = false
)
  1 ->
    (
  _g = # TODO: Implement expression type: TEnumParameter
  _g1 = # TODO: Implement expression type: TEnumParameter
  if (# TODO: Implement expression type: TEnumIndex == 1), do: (
  _g2 = # TODO: Implement expression type: TEnumParameter
  _g3 = # TODO: Implement expression type: TEnumParameter
  (
  l2 = _g2
  r2 = _g3
  r1 = _g1
  l1 = _g
  temp_result = Main.compareTrees(l1, l2) && Main.compareTrees(r1, r2)
)
), else: temp_result = false
)
end
  temp_result
)
  end

  @doc "Function main"
  @spec main() :: nil
  def main() do
    (
  color = Color.RGB(255, 128, 0)
  Log.trace(Main.colorToString(color), %{fileName: "Main.hx", lineNumber: 79, className: "Main", methodName: "main"})
  some = Option.Some("Hello")
  none = Option.none()
  Log.trace(Main.getValue(some, "default"), %{fileName: "Main.hx", lineNumber: 84, className: "Main", methodName: "main"})
  Log.trace(Main.getValue(none, "default"), %{fileName: "Main.hx", lineNumber: 85, className: "Main", methodName: "main"})
  tree = Tree.Node(Tree.Leaf(1), Tree.Node(Tree.Leaf(2), Tree.Leaf(3)))
  Log.trace(Main.treeSum(tree), %{fileName: "Main.hx", lineNumber: 92, className: "Main", methodName: "main"})
  Log.trace(Main.describeRGB(Color.RGB(250, 10, 10)), %{fileName: "Main.hx", lineNumber: 95, className: "Main", methodName: "main"})
  tree2 = Tree.Node(Tree.Leaf(1), Tree.Node(Tree.Leaf(2), Tree.Leaf(3)))
  Log.trace(Main.compareTrees(tree, tree2), %{fileName: "Main.hx", lineNumber: 99, className: "Main", methodName: "main"})
)
  end

end


defmodule Color do
  @moduledoc """
  Color enum generated from Haxe
  
  
 * Enum test case
 * Tests enum compilation and pattern matching
 
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    :red |
    {:r_g_b, term(), term(), term()} |
    :green |
    :blue

  @doc "Creates red enum value"
  @spec red() :: :red
  def red(), do: :red

  @doc """
  Creates r_g_b enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
    - `arg2`: term()
  """
  @spec r_g_b(term(), term(), term()) :: {:r_g_b, term(), term(), term()}
  def r_g_b(arg0, arg1, arg2) do
    {:r_g_b, arg0, arg1, arg2}
  end

  @doc "Creates green enum value"
  @spec green() :: :green
  def green(), do: :green

  @doc "Creates blue enum value"
  @spec blue() :: :blue
  def blue(), do: :blue

  # Predicate functions for pattern matching
  @doc "Returns true if value is red variant"
  @spec is_red(t()) :: boolean()
  def is_red(:red), do: true
  def is_red(_), do: false

  @doc "Returns true if value is r_g_b variant"
  @spec is_r_g_b(t()) :: boolean()
  def is_r_g_b({:r_g_b, _}), do: true
  def is_r_g_b(_), do: false

  @doc "Returns true if value is green variant"
  @spec is_green(t()) :: boolean()
  def is_green(:green), do: true
  def is_green(_), do: false

  @doc "Returns true if value is blue variant"
  @spec is_blue(t()) :: boolean()
  def is_blue(:blue), do: true
  def is_blue(_), do: false

  @doc "Extracts value from r_g_b variant, returns {:ok, value} or :error"
  @spec get_r_g_b_value(t()) :: {:ok, {term(), term(), term()}} | :error
  def get_r_g_b_value({:r_g_b, arg0, arg1, arg2}), do: {:ok, {arg0, arg1, arg2}}
  def get_r_g_b_value(_), do: :error

end


defmodule Option do
  @moduledoc """
  Option enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:some, term()} |
    :none

  @doc """
  Creates some enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec some(term()) :: {:some, term()}
  def some(arg0) do
    {:some, arg0}
  end

  @doc "Creates none enum value"
  @spec none() :: :none
  def none(), do: :none

  # Predicate functions for pattern matching
  @doc "Returns true if value is some variant"
  @spec is_some(t()) :: boolean()
  def is_some({:some, _}), do: true
  def is_some(_), do: false

  @doc "Returns true if value is none variant"
  @spec is_none(t()) :: boolean()
  def is_none(:none), do: true
  def is_none(_), do: false

  @doc "Extracts value from some variant, returns {:ok, value} or :error"
  @spec get_some_value(t()) :: {:ok, term()} | :error
  def get_some_value({:some, value}), do: {:ok, value}
  def get_some_value(_), do: :error

end


defmodule Tree do
  @moduledoc """
  Tree enum generated from Haxe
  
  This module provides tagged tuple constructors and pattern matching helpers.
  """

  @type t() ::
    {:node, term(), term()} |
    {:leaf, term()}

  @doc """
  Creates node enum value with parameters
  
  ## Parameters
    - `arg0`: term()
    - `arg1`: term()
  """
  @spec node(term(), term()) :: {:node, term(), term()}
  def node(arg0, arg1) do
    {:node, arg0, arg1}
  end

  @doc """
  Creates leaf enum value with parameters
  
  ## Parameters
    - `arg0`: term()
  """
  @spec leaf(term()) :: {:leaf, term()}
  def leaf(arg0) do
    {:leaf, arg0}
  end

  # Predicate functions for pattern matching
  @doc "Returns true if value is node variant"
  @spec is_node(t()) :: boolean()
  def is_node({:node, _}), do: true
  def is_node(_), do: false

  @doc "Returns true if value is leaf variant"
  @spec is_leaf(t()) :: boolean()
  def is_leaf({:leaf, _}), do: true
  def is_leaf(_), do: false

  @doc "Extracts value from node variant, returns {:ok, value} or :error"
  @spec get_node_value(t()) :: {:ok, {term(), term()}} | :error
  def get_node_value({:node, arg0, arg1}), do: {:ok, {arg0, arg1}}
  def get_node_value(_), do: :error

  @doc "Extracts value from leaf variant, returns {:ok, value} or :error"
  @spec get_leaf_value(t()) :: {:ok, term()} | :error
  def get_leaf_value({:leaf, value}), do: {:ok, value}
  def get_leaf_value(_), do: :error

end
