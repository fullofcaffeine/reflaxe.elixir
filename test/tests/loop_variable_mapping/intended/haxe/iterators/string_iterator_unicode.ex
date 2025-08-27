defmodule StringIteratorUnicode do
  @moduledoc """
    StringIteratorUnicode struct generated from Haxe

      This iterator can be used to iterate across strings in a cross-platform
      way. It handles surrogate pairs on platforms that require it. On each
      iteration, it returns the next character code.

      Note that this has different semantics than a standard for-loop over the
      String's length due to the fact that it deals with surrogate pairs.
  """

  defstruct [:s, offset: 0]

  @type t() :: %__MODULE__{
    offset: integer(),
    s: String.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t()) :: t()
  def new(arg0) do
    %__MODULE__{
      offset: arg0,
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe unicodeIterator"
  def unicode_iterator(s) do
    StringIteratorUnicode.new(s)
  end

  # Instance functions
  @doc "Generated from Haxe hasNext"
  def has_next(%__MODULE__{} = struct) do
    (struct.offset < struct.s.length)
  end

  @doc "Generated from Haxe next"
  def next(%__MODULE__{} = struct) do
    temp_number = nil

    s = struct.s
    index = struct.offset + 1
    _c = s.cca(index)
    if (((_c >= 55296) && (_c <= 56319))), do: _c = (Bitwise.bsl((_c - 55232), 10) or (s.cca((index + 1)) and 1023)), else: nil
    temp_number = _c

    _c = temp_number

    if ((_c >= 65536)), do: struct.offset + 1, else: nil

    _c
  end

end
