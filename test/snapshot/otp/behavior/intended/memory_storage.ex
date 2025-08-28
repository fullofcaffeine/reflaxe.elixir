defmodule MemoryStorage do
  @moduledoc """
    MemoryStorage struct generated from Haxe

    This module defines a struct with typed fields and constructor functions.
  """

  defstruct [:data]

  @type t() :: %__MODULE__{
    data: Map.t() | nil
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
  def init(%__MODULE__{} = struct, _config) do
    %{"ok" => struct}
  end

  @doc "Generated from Haxe get"
  def get(%__MODULE__{} = struct, key) do
    temp_result = nil

    struct = struct.data

    temp_result = Map.get(struct, key)

    temp_result
  end

  @doc "Generated from Haxe put"
  def put(%__MODULE__{} = struct, key, value) do
    struct = struct.data

    struct = Map.put(struct, key, value)

    true
  end

  @doc "Generated from Haxe delete"
  def delete(%__MODULE__{} = struct, key) do
    temp_result = nil

    struct = struct.data

    temp_result = Map.delete(struct, key)

    temp_result
  end

  @doc "Generated from Haxe list"
  def list(%__MODULE__{} = struct) do
    temp_iterator = nil

    g_array = []

    struct = struct.data

    temp_iterator = Map.keys(struct)

    k = temp_iterator

    (
      # Simple module-level pattern (inline for now)
      loop_helper = fn condition_fn, body_fn, loop_fn ->
        if condition_fn.() do
          body_fn.()
          loop_fn.(condition_fn, body_fn, loop_fn)
        else
          nil
        end
      end

      loop_helper.(
        fn -> k.has_next() end,
        fn ->
          k = k.next()
          g_array ++ [k]
        end,
        loop_helper
      )
    )

    g_array
  end


  # While loop helper functions
  # Generated automatically for tail-recursive loop patterns

  @doc false
  defp while_loop(condition_fn, body_fn) do
    if condition_fn.() do
      body_fn.()
      while_loop(condition_fn, body_fn)
    else
      nil
    end
  end

  @doc false
  defp do_while_loop(body_fn, condition_fn) do
    body_fn.()
    if condition_fn.() do
      do_while_loop(body_fn, condition_fn)
    else
      nil
    end
  end

end
