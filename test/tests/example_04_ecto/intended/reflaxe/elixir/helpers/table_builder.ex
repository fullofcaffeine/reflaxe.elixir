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
    if (name == "id"), do: struct = %{struct | has_id_column: true}, else: nil
    if (name == "inserted_at" || name == "updated_at"), do: struct = %{struct | has_timestamps: true}, else: nil
    options_str = ""
    if (options != nil) do
      Enum.each(Map.keys(options), fn field ->
        g = g + 1
          value = Map.get(options, field)
          case (field) do
        "default" ->
          temp_string = "default"
        "null" ->
          temp_string = "null"
        "primaryKey" ->
          temp_string = "primary_key"
        _ ->
          temp_string = field
      end
          opt_name = temp_string
          if (Std.is_of_type(value, String)), do: opts ++ ["" <> opt_name <> ": \"" <> value <> "\""], else: if (Std.is_of_type(value, Bool)), do: opts ++ ["" <> opt_name <> ": " <> value], else: opts ++ ["" <> opt_name <> ": " <> value]
      end)
    end
    struct.columns ++ ["add :" <> name <> ", :" <> data_type <> options_str]
    struct
  end

  @doc """
    Add an index to the table

  """
  @spec add_index(t(), Array.t(), Null.t()) :: TableBuilder.t()
  def add_index(%__MODULE__{} = struct, column_names, options) do
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < column_names.length) do
          try do
            v = Enum.at(column_names, g)
    g = g + 1
    _g_counter.push(":" ++ v)
            loop_fn.(loop_fn, {g_counter})
          catch
            :break -> {g_counter}
            :continue -> loop_fn.(loop_fn, {g_counter})
          end
        else
          {g_counter}
        end
      end
      {g_counter} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    columnList = (g).join(", ")
    if (options != nil && Reflect.has_field(options, "unique") && Reflect.field(options, "unique") == true), do: struct.indexes.push("create unique_index(:" ++ struct.tableName ++ ", [" ++ column_list ++ "])"), else: struct.indexes.push("create index(:" ++ struct.tableName ++ ", [" ++ column_list ++ "])")
    struct
  end

  @doc """
    Add a foreign key constraint

  """
  @spec add_foreign_key(t(), String.t(), String.t(), String.t()) :: TableBuilder.t()
  def add_foreign_key(%__MODULE__{} = struct, column_name, referenced_table, referenced_column) do
    new_columns = []
    found = false
    _g_counter = 0
    _g_3 = struct.columns
    (
      loop_helper = fn loop_fn, {g_3, found} ->
        if (g < g.length) do
          try do
            column = Enum.at(g, g)
    g = g + 1
    if (column.index_of(":" <> column_name <> ",") != -1), do: new_columns.push("add :" ++ column_name ++ ", references(:" ++ referenced_table ++ ", column: :" ++ referenced_column ++ ")")
    found = true, else: new_columns.push(column)
            loop_fn.(loop_fn, {g_3, found})
          catch
            :break -> {g_3, found}
            :continue -> loop_fn.(loop_fn, {g_3, found})
          end
        else
          {g_3, found}
        end
      end
      {g_3, found} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    if (!found), do: new_columns.push("add :" ++ column_name ++ ", references(:" ++ referenced_table ++ ", column: :" ++ referenced_column ++ ")"), else: nil
    struct.columns = new_columns
    struct
  end

  @doc """
    Add a check constraint

  """
  @spec add_check_constraint(t(), String.t(), String.t()) :: TableBuilder.t()
  def add_check_constraint(%__MODULE__{} = struct, condition, constraint_name) do
    struct.constraints ++ ["create constraint(:" <> struct.table_name <> ", :" <> constraint_name <> ", check: \"" <> condition <> "\")"]
    struct
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
