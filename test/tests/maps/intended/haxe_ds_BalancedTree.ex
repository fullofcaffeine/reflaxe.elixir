defmodule BalancedTree do
  use Bitwise
  @behaviour IMap

  @moduledoc """
  BalancedTree module generated from Haxe
  
  
	BalancedTree allows key-value mapping with arbitrary keys, as long as they
	can be ordered. By default, `Reflect.compare` is used in the `compare`
	method, which can be overridden in subclasses.

	Operations have a logarithmic average and worst-case cost.

	Iteration over keys and values, using `keys` and `iterator` respectively,
	are in-order.

  """

  # Instance functions
  @doc "
		Binds `key` to `value`.

		If `key` is already bound to a value, that binding disappears.

		If `key` is null, the result is unspecified.
	"
  @spec set(K.t(), V.t()) :: nil
  def set(arg0, arg1) do
    __MODULE__.root = __MODULE__.setLoop(arg0, arg1, __MODULE__.root)
  end

  @doc "
		Returns the value `key` is bound to.

		If `key` is not bound to any value, `null` is returned.

		If `key` is null, the result is unspecified.
	"
  @spec get(K.t()) :: Null.t()
  def get(arg0) do
    node = __MODULE__.root
(fn loop_fn ->
  if (node != nil) do
    c = __MODULE__.compare(arg0, node.key)
if (c == 0), do: node.value, else: nil
if (c < 0), do: node = node.left, else: node = node.right
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
nil
  end

  @doc "
		Tells if `key` is bound to a value.

		This method returns true even if `key` is bound to null.

		If `key` is null, the result is unspecified.
	"
  @spec exists(K.t()) :: boolean()
  def exists(arg0) do
    node = __MODULE__.root
(fn loop_fn ->
  if (node != nil) do
    c = __MODULE__.compare(arg0, node.key)
if (c == 0), do: true, else: if (c < 0), do: node = node.left, else: node = node.right
    loop_fn.(loop_fn)
  end
end).(fn f -> f.(f) end)
false
  end

  @doc "
		Iterates over the keys of `this` BalancedTree.

		This operation is performed in-order.
	"
  @spec keys() :: Iterator.t()
  def keys() do
    ret = []
__MODULE__.keysLoop(__MODULE__.root, ret)
Haxe.Iterators.ArrayIterator.new(ret)
  end

  @doc "Function set_loop"
  @spec set_loop(K.t(), V.t(), TreeNode.t()) :: TreeNode.t()
  def set_loop(arg0, arg1, arg2) do
    if (arg2 == nil), do: Haxe.Ds.TreeNode.new(nil, arg0, arg1, nil), else: nil
c = __MODULE__.compare(arg0, arg2.key)
temp_result = nil
if (c == 0) do
  temp_number = nil
  if (arg2 == nil), do: temp_number = 0, else: temp_number = arg2._height
  temp_result = Haxe.Ds.TreeNode.new(arg2.left, arg0, arg1, arg2.right, temp_number)
else
  if (c < 0) do
    nl = __MODULE__.setLoop(arg0, arg1, arg2.left)
    temp_result = __MODULE__.balance(nl, arg2.key, arg2.value, arg2.right)
  else
    nr = __MODULE__.setLoop(arg0, arg1, arg2.right)
    temp_result = __MODULE__.balance(arg2.left, arg2.key, arg2.value, nr)
  end
end
temp_result
  end

  @doc "Function keys_loop"
  @spec keys_loop(TreeNode.t(), Array.t()) :: nil
  def keys_loop(arg0, arg1) do
    if (arg0 != nil) do
  __MODULE__.keysLoop(arg0.left, arg1)
  arg1 ++ [arg0.key]
  __MODULE__.keysLoop(arg0.right, arg1)
end
  end

  @doc "Function balance"
  @spec balance(TreeNode.t(), K.t(), V.t(), TreeNode.t()) :: TreeNode.t()
  def balance(arg0, arg1, arg2, arg3) do
    temp_number = nil
if (arg0 == nil), do: temp_number = 0, else: temp_number = arg0._height
hl = temp_number
temp_number1 = nil
if (arg3 == nil), do: temp_number1 = 0, else: temp_number1 = arg3._height
hr = temp_number1
temp_result = nil
if (hl > hr + 2) do
  temp_left = nil
  _this = arg0.left
  if (_this == nil), do: temp_left = 0, else: temp_left = _this._height
  temp_right = nil
  _this = arg0.right
  if (_this == nil), do: temp_right = 0, else: temp_right = _this._height
  if (temp_left >= temp_right), do: temp_result = Haxe.Ds.TreeNode.new(arg0.left, arg0.key, arg0.value, Haxe.Ds.TreeNode.new(arg0.right, arg1, arg2, arg3)), else: temp_result = Haxe.Ds.TreeNode.new(Haxe.Ds.TreeNode.new(arg0.left, arg0.key, arg0.value, arg0.right.left), arg0.right.key, arg0.right.value, Haxe.Ds.TreeNode.new(arg0.right.right, arg1, arg2, arg3))
else
  if (hr > hl + 2) do
    temp_left1 = nil
    _this = arg3.right
    if (_this == nil), do: temp_left1 = 0, else: temp_left1 = _this._height
    temp_right1 = nil
    _this = arg3.left
    if (_this == nil), do: temp_right1 = 0, else: temp_right1 = _this._height
    if (temp_left1 > temp_right1), do: temp_result = Haxe.Ds.TreeNode.new(Haxe.Ds.TreeNode.new(arg0, arg1, arg2, arg3.left), arg3.key, arg3.value, arg3.right), else: temp_result = Haxe.Ds.TreeNode.new(Haxe.Ds.TreeNode.new(arg0, arg1, arg2, arg3.left.left), arg3.left.key, arg3.left.value, Haxe.Ds.TreeNode.new(arg3.left.right, arg3.key, arg3.value, arg3.right))
  else
    temp_left2 = nil
    (if (hl > hr), do: temp_left2 = hl, else: temp_left2 = hr)
    temp_result = Haxe.Ds.TreeNode.new(arg0, arg1, arg2, arg3, temp_left2 + 1)
  end
end
temp_result
  end

  @doc "Function compare"
  @spec compare(K.t(), K.t()) :: integer()
  def compare(arg0, arg1) do
    Reflect.compare(arg0, arg1)
  end

end


defmodule TreeNode do
  use Bitwise
  @moduledoc """
  TreeNode module generated from Haxe
  
  
	A tree node of `haxe.ds.BalancedTree`.

  """

end
