defmodule Point do
  @moduledoc """
    Point struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:x, :y]

  @type t() :: %__MODULE__{
    x: float() | nil,
    y: float() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(float(), float()) :: t()
  def new(arg0, arg1) do
    %__MODULE__{
      x: arg0,
      y: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc "Function distance"
  @spec distance(t(), Point.t()) :: float()
  def distance(%__MODULE__{} = struct, other) do
    dx = struct.x - other.x
    dy = struct.y - other.y
    Math.sqrt(dx * dx + dy * dy)
  end

  @doc "Function to_string"
  @spec to_string(t()) :: String.t()
  def to_string(%__MODULE__{} = struct) do
    "Point(" <> Float.to_string(struct.x) <> ", " <> Float.to_string(struct.y) <> ")"
  end

end
