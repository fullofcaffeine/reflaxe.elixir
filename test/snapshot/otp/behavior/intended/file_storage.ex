defmodule FileStorage do
  @moduledoc """
    FileStorage struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:base_path]

  @type t() :: %__MODULE__{
    base_path: String.t() | nil
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
  @doc "Generated from Haxe init"
  def init(%__MODULE__{} = struct, config) do
    if ((config.path != nil)), do: %{struct | base_path: config.path}, else: nil

    %{"ok" => struct}
  end

  @doc "Generated from Haxe get"
  def get(%__MODULE__{} = struct, _key) do
    nil
  end

  @doc "Generated from Haxe put"
  def put(%__MODULE__{} = struct, _key, _value) do
    true
  end

  @doc "Generated from Haxe delete"
  def delete(%__MODULE__{} = struct, _key) do
    true
  end

  @doc "Generated from Haxe list"
  def list(%__MODULE__{} = struct) do
    []
  end

end
