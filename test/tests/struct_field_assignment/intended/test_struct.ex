defmodule TestStruct do
  @moduledoc """
    TestStruct struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:field]

  @type t() :: %__MODULE__{
    field: String.t() | nil
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
    struct |> Map.merge(changes) |> struct(__MODULE__, _1)
  end

  # Instance functions
  @doc "Function write"
  @spec write(t(), term()) :: nil
  def write(%__MODULE__{} = struct, value) do
    _g = Type.typeof(value)
    case (elem(_g, 0)) do
      0 ->
        %{struct | field: struct.field <> "null"}
      1 ->
        %{struct | field: struct.field <> Std.string(value)}
      _ ->
        %{struct | field: struct.field <> "other"}
    end
  end

end
