defmodule Shape do
  @behaviour Drawable

  @moduledoc """
    Shape struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:position, :name]

  @type t() :: %__MODULE__{
    position: Point.t() | nil,
    name: String.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(float(), float(), String.t()) :: t()
  def new(arg0, arg1, arg2) do
    %__MODULE__{
      position: arg0,
      name: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Generated from Haxe draw"
  def draw(%__MODULE__{} = struct) do
    "" <> struct.name <> " at " <> struct.position.to_string()
  end

  @doc "Generated from Haxe getPosition"
  def get_position(%__MODULE__{} = struct) do
    struct.position
  end

  @doc "Generated from Haxe move"
  def move(%__MODULE__{} = struct, dx, dy) do
    fh = struct.position

    fh.x = fh.x + dx

    fh = struct.position

    fh.y = fh.y + dy
  end

end
