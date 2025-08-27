defmodule TableBuilder do
  @moduledoc """
    TableBuilder struct generated from Haxe

     * Table builder class for DSL-style migration creation
     * Provides fluent interface for defining table structure
  """

  defstruct [:table_name, has_id_column: true, has_timestamps: true, columns: nil, indexes: nil, constraints: nil]

  @type t() :: %__MODULE__{
    table_name: String.t() | nil,
    has_id_column: boolean(),
    has_timestamps: boolean(),
    columns: Array.t(),
    indexes: Array.t(),
    constraints: Array.t()
  }

  @doc "Creates a new struct instance"
  @spec new(String.t()) :: t()
  def new(arg0) do
    %__MODULE__{
      table_name: arg0,
    }
  end

  @doc "Updates struct fields using a map of changes"
  @spec update(t(), map()) :: t()
  def update(struct, changes) when is_map(changes) do
    Map.merge(struct, changes) |> then(&struct(__MODULE__, &1))
  end

  # Instance functions
  @doc """
    Add a column to the table

  """
  @spec add_column(t(), String.t(), String.t(), Null.t()) :: TableBuilder.t()
  def add_column(%__MODULE__{} = struct, name, data_type, options) do
    nil
  end

  @doc """
    Add an index to the table

  """
  @spec add_index(t(), Array.t(), Null.t()) :: TableBuilder.t()
  def add_index(%__MODULE__{} = struct, column_names, options) do
    nil
  end

  @doc """
    Add a foreign key constraint

  """
  @spec add_foreign_key(t(), String.t(), String.t(), String.t()) :: TableBuilder.t()
  def add_foreign_key(%__MODULE__{} = struct, column_name, referenced_table, referenced_column) do
    nil
  end

  @doc """
    Add a check constraint

  """
  @spec add_check_constraint(t(), String.t(), String.t()) :: TableBuilder.t()
  def add_check_constraint(%__MODULE__{} = struct, condition, constraint_name) do
    nil
  end

  @doc """
    Get all column definitions

  """
  @spec get_column_definitions(t()) :: Array.t()
  def get_column_definitions(%__MODULE__{} = struct) do
    struct.columns
  end

  @doc """
    Get all index definitions

  """
  @spec get_index_definitions(t()) :: Array.t()
  def get_index_definitions(%__MODULE__{} = struct) do
    struct.indexes
  end

  @doc """
    Get all constraint definitions

  """
  @spec get_constraint_definitions(t()) :: Array.t()
  def get_constraint_definitions(%__MODULE__{} = struct) do
    struct.constraints
  end

end
