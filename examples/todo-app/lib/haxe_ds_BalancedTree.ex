defmodule BalancedTree do
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

end


defmodule TreeNode do
  @moduledoc """
  TreeNode module generated from Haxe
  
  
	A tree node of `haxe.ds.BalancedTree`.

  """

end
