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
  @doc "Function draw"
  @spec draw(t()) :: String.t()
  def draw(%__MODULE__{} = struct) do
    "" <> struct.name <> " at " <> struct.position.to_string()
  end

  @doc "Function get_position"
  @spec get_position(t()) :: Point.t()
  def get_position(%__MODULE__{} = struct) do
    struct.position
  end

  @doc "Function move"
  @spec move(t(), float(), float()) :: nil
  def move(%__MODULE__{} = struct, dx, dy) do
    (
          fh = %{fh.position | x: dx}
          fh2 = %{fh2.position | y: dy}
        )
  end

end
