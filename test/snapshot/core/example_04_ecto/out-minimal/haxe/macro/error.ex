defmodule Error do
  @moduledoc """
    Error struct generated from Haxe

      This error can be used to handle or produce compilation errors in macros.
  """

  defstruct [:pos]

  @type t() :: %__MODULE__{
    pos: Position.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t(), Position.t(), Null.t()) :: t()
  def new(arg0, arg1, arg2) do
    %__MODULE__{
      pos: arg0
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

end
