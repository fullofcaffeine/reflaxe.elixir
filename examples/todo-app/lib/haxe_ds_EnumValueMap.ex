defmodule EnumValueMap do
  @behaviour IMap

  @moduledoc """
    EnumValueMap allows mapping of enum value keys to arbitrary values.

    Keys are compared by value and recursively over their parameters. If any
    parameter is not an enum value, `Reflect.compare` is used to compare them.
  """

end
