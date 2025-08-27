defmodule MyWorker do
  @moduledoc """
    MyWorker struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:config]

  @type t() :: %__MODULE__{
    config: String.t() | nil
  }

  @doc "Creates a new struct instance"
  @spec new(String.t()) :: t()
  def new(arg0) do
    %__MODULE__{
      config: arg0
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Static functions
  @doc "Generated from Haxe start_link"
  def start_link(_args) do
    %{"_0" => "ok", "_1" => "worker_pid"}
  end

end
