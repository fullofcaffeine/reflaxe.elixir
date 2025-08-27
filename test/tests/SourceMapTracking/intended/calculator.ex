defmodule Calculator do
  @moduledoc """
    Calculator struct generated from Haxe

     * Test class for tracking class compilation positions
  """

  defstruct [value: 0]

  @type t() :: %__MODULE__{
    value: integer()
  }

  @doc "Creates a new struct instance"
  @spec new() :: t()
  def new() do
    %__MODULE__{
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe add"
  def add(%__MODULE__{} = struct, n) do
    struct.value = struct.value + n
  end

  @doc "Generated from Haxe multiply"
  def multiply(%__MODULE__{} = struct, factor) do
    struct.value = struct.value * factor
  end

  @doc "Generated from Haxe getValue"
  def get_value(%__MODULE__{} = struct) do
    struct.value
  end

end
