defmodule Circle do
  @behaviour Updatable

  @moduledoc """
    Circle struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:radius, :velocity]

  @type t() :: %__MODULE__{
    radius: float() | nil,
    velocity: Point.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(float(), float(), float()) :: t()
  def new(arg0, arg1, arg2) do
    %__MODULE__{
      radius: arg0,
      velocity: arg1
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Function create_unit"
  @spec create_unit() :: Circle.t()
  def create_unit() do
    Circle.new(0, 0, 1)
  end

  # Instance functions
  @doc "Function draw"
  @spec draw(t()) :: String.t()
  def draw(%__MODULE__{} = struct) do
    "" <> "Exception".draw() <> " with radius " <> Float.to_string(struct.radius)
  end

  @doc "Function update"
  @spec update(t(), float()) :: nil
  def update(%__MODULE__{} = struct, dt) do
    struct.move(struct.velocity.x * dt, struct.velocity.y * dt)
  end

  @doc "Function set_velocity"
  @spec set_velocity(t(), float(), float()) :: nil
  def set_velocity(%__MODULE__{} = struct, vx, vy) do
    struct.velocity.struct.velocity.x = vx
    struct.velocity.struct.velocity.y = vy
  end

end
