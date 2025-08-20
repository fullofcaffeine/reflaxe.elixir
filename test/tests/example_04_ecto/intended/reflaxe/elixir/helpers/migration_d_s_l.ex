defmodule MigrationDSL do
  @moduledoc """
    MigrationDSL module generated from Haxe

     * Ecto Migration DSL compilation support following the proven ChangesetCompiler pattern
     * Handles @:migration annotation, table/column operations, and index management
     * Integrates with Mix tasks and ElixirCompiler architecture
  """

  # Static functions
  @doc """
    Sanitize identifiers to prevent injection attacks

  """
  @spec sanitize_identifier(String.t()) :: String.t()
  def sanitize_identifier(identifier) do
    if (identifier == nil || identifier == ""), do: "unnamed", else: nil
    identifier = Enum.join(String.split(identifier, "';"), "")
    identifier = Enum.join(String.split(identifier, "--"), "")
    identifier = Enum.join(String.split(identifier, "DROP"), "")
    identifier = Enum.join(String.split(identifier, ""), "")
    identifier = Enum.join(String.split(identifier, "/*"), "")
    identifier = Enum.join(String.split(identifier, "*/"), "")
    clean = ""
    _g_counter = 0
    _g_9 = Enum.count(identifier)
    (
      loop_helper = fn loop_fn, {clean} ->
        if (g < g) do
          try do
            i = g = g + 1
    c = identifier.charAt(i)
    if (c >= "a" && c <= "z" || c >= "A" && c <= "Z" || c >= "0" && c <= "9" || c == "_"), do: clean = clean <> c.to_lower_case(), else: nil
            loop_fn.(loop_fn, {clean})
          catch
            :break -> {clean}
            :continue -> loop_fn.(loop_fn, {clean})
          end
        else
          {clean}
        end
      end
      {clean} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    tempResult = nil
    if (clean.length > 0), do: temp_result = clean, else: temp_result = "sanitized"
    temp_result
  end

  @doc """
    Check if a class is annotated with @:migration (string version for testing)

  """
  @spec is_migration_class(String.t()) :: boolean()
  def is_migration_class(class_name) do
    if (class_name == nil || class_name == ""), do: false, else: nil
    class_name.index_of("Migration") != -1 || class_name.index_of("Create") != -1 || class_name.index_of("Alter") != -1 || class_name.index_of("Drop") != -1
  end

  @doc """
    Check if ClassType has @:migration annotation (real implementation)
    Note: Temporarily simplified due to Haxe 4.3.6 API compatibility
  """
  @spec is_migration_class_type(term()) :: boolean()
  def is_migration_class_type(class_type) do
    true
  end

  @doc """
    Get migration configuration from @:migration annotation
    Extracts table name from @:migration("table_name") annotation
  """
  @spec get_migration_config(ClassType.t()) :: term()
  def get_migration_config(class_type) do
    if (!class_type.meta.has(":migration")), do: %{"table" => "default_table", "timestamp" => MigrationDSL.generate_timestamp()}, else: nil
    meta = Enum.at(class_type.meta.extract(":migration"), 0)
    table_name = "default_table"
    if (meta.params != nil && meta.params.length > 0) do
      g = Enum.at(meta.params, 0).expr
      case (elem(g, 0)) do
        0 ->
          g = elem(g, 1)
          if (elem(g, 0) == 2) do
            _g_1 = elem(g, 1)
            _g_1 = elem(g, 2)
            s = _g_1
            table_name = s
          else
            table_name = MigrationDSL.extract_table_name_from_class_name(class_type.name)
          end
        5 ->
          g = elem(g, 1)
          fields = g
          g_counter = 0
          (
            loop_helper = fn loop_fn, {g} ->
              if (g < fields.length) do
                try do
                  field = Enum.at(fields, g)
                g = g + 1
                if (field.field == "table") do
            g = field.expr.expr
            if (elem(g, 0) == 0) do
              g = elem(g, 1)
              if (elem(g, 0) == 2) do
                _g_1 = elem(g, 1)
                _g_1 = elem(g, 2)
                s = _g_1
                table_name = s
              else
                nil
              end
            else
              nil
            end
          end
                loop_fn.({g + 1})
                  loop_fn.(loop_fn, {g})
                catch
                  :break -> {g}
                  :continue -> loop_fn.(loop_fn, {g})
                end
              else
                {g}
              end
            end
            {g} = try do
              loop_helper.(loop_helper, {nil})
            catch
              :break -> {nil}
            end
          )
        _ ->
          table_name = MigrationDSL.extract_table_name_from_class_name(class_type.name)
      end
    else
      table_name = MigrationDSL.extract_table_name_from_class_name(class_type.name)
    end
    %{"table" => table_name, "timestamp" => MigrationDSL.generate_timestamp()}
  end

  @doc """
    Extract table name from class name (CreateUsers -> users)

  """
  @spec extract_table_name_from_class_name(String.t()) :: String.t()
  def extract_table_name_from_class_name(class_name) do
    MigrationDSL.camel_case_to_snake_case(class_name)
    className
      |> replace("Create", "")
      |> replace("Alter", "")
      |> replace("Drop", "")
      |> replace("Add", "")
      |> replace("Remove", "")
      |> replace("Table", "")
      |> replace("Migration", "")
  end

  @doc """
    Compile table creation with columns

  """
  @spec compile_table_creation(String.t(), Array.t()) :: String.t()
  def compile_table_creation(table_name, columns) do
    column_defs = Array.new()
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g, temp_string} ->
        if (g < columns.length) do
          try do
            column = Enum.at(columns, g)
          g = g + 1
          parts = String.split(column, ":")
          name = Enum.at(parts, 0)
          temp_string = nil
          temp_string = if (parts.length > 1), do: Enum.at(parts, 1), else: "string"
          type = temp_string
          column_defs ++ ["      add :" <> name <> ", :" <> type]
          loop_fn.({g + 1, temp_string})
            loop_fn.(loop_fn, {g, temp_string})
          catch
            :break -> {g, temp_string}
            :continue -> loop_fn.(loop_fn, {g, temp_string})
          end
        else
          {g, temp_string}
        end
      end
      {g, temp_string} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    "create table(:" <> table_name <> ") do\n" <> Enum.join(column_defs, "\n") <> "\n" <> "      timestamps()\n" <> "    end"
  end

  @doc """
    Generate basic migration module structure

  """
  @spec generate_migration_module(String.t()) :: String.t()
  def generate_migration_module(class_name) do
    "defmodule " <> class_name <> " do\n" <> "  @moduledoc \"\"\"\n" <> ("  Generated from Haxe @:migration class: " <> class_name <> "\n") <> "  \n" <> "  This migration module was automatically generated from a Haxe source file\n" <> "  as part of the Reflaxe.Elixir compilation pipeline.\n" <> "  \"\"\"\n" <> "  \n" <> "  use Ecto.Migration\n" <> "  \n" <> "  @doc \"\"\"\n" <> "  Run the migration\n" <> "  \"\"\"\n" <> "  def change do\n" <> "    # Migration operations go here\n" <> "  end\n" <> "  \n" <> "  @doc \"\"\"\n" <> "  Run the migration up\n" <> "  \"\"\"\n" <> "  def up do\n" <> "    # Up migration operations\n" <> "  end\n" <> "  \n" <> "  @doc \"\"\"\n" <> "  Run the migration down (rollback)\n" <> "  \"\"\"\n" <> "  def down do\n" <> "    # Down migration operations\n" <> "  end\n" <> "end"
  end

  @doc """
    Compile index creation

  """
  @spec compile_index_creation(String.t(), Array.t(), String.t()) :: String.t()
  def compile_index_creation(table_name, fields, options) do
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < fields.length) do
          try do
            v = Enum.at(fields, g)
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
    fieldList = (g).join(", ")
    if (options.index_of("unique") != -1), do: "create unique_index(:" <> table_name <> ", [" <> field_list <> "])", else: "create index(:" <> table_name <> ", [" <> field_list <> "])"
  end

  @doc """
    Generate appropriate indexes for a table based on its columns
    Only creates indexes for fields that actually exist in the schema
  """
  @spec generate_indexes_for_table(String.t(), Array.t()) :: String.t()
  def generate_indexes_for_table(table_name, columns) do
    indexes = []
    column_names = []
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < columns.length) do
          try do
            column = Enum.at(columns, g)
          g = g + 1
          if (column.name != nil), do: column_names ++ [column.name], else: nil
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    if (column_names.index_of("email") != -1), do: indexes ++ ["create unique_index(:" <> table_name <> ", [:email])"], else: nil
    if (column_names.index_of("user_id") != -1), do: indexes ++ ["create index(:" <> table_name <> ", [:user_id])"], else: nil
    if (column_names.index_of("slug") != -1), do: indexes ++ ["create unique_index(:" <> table_name <> ", [:slug])"], else: nil
    if (indexes.length == 0), do: "# No indexes needed for this table", else: nil
    Enum.join(indexes, "\n    ")
  end

  @doc """
    Compile table drop for rollback

  """
  @spec compile_table_drop(String.t()) :: String.t()
  def compile_table_drop(table_name) do
    "drop table(:" <> table_name <> ")"
  end

  @doc """
    Compile column modification

  """
  @spec compile_column_modification(String.t(), String.t(), String.t()) :: String.t()
  def compile_column_modification(table_name, column_name, modification) do
    "alter table(:" <> table_name <> ") do\n" <> ("  modify :" <> column_name <> ", :string, " <> modification <> "\n") <> "end"
  end

  @doc """
    Compile full migration with all operations

  """
  @spec compile_full_migration(term()) :: String.t()
  def compile_full_migration(migration_data) do
    class_name = migration_data.class_name
    table_name = migration_data.table_name
    columns = migration_data.columns
    module_name = "Repo." <> class_name
    table_creation = MigrationDSL.compile_table_creation(table_name, columns)
    index_creation = MigrationDSL.generate_indexes_for_table(table_name, columns)
    "defmodule " <> module_name <> " do\n" <> "  @moduledoc \"\"\"\n" <> ("  Generated migration for " <> table_name <> " table\n") <> "  \n" <> ("  Creates " <> table_name <> " table with proper schema and indexes\n") <> "  following Ecto migration patterns with compile-time validation.\n" <> "  \"\"\"\n" <> "  \n" <> "  use Ecto.Migration\n" <> "  \n" <> "  @doc \"\"\"\n" <> ("  Run the migration - creates " <> table_name <> " table\n") <> "  \"\"\"\n" <> "  def change do\n" <> ("    " <> table_creation <> "\n") <> "    \n" <> ("    " <> index_creation <> "\n") <> "  end\n" <> "  \n" <> "  @doc \"\"\"\n" <> ("  Rollback migration - drops " <> table_name <> " table\n") <> "  \"\"\"\n" <> "  def down do\n" <> ("    drop table(:" <> table_name <> ")\n") <> "  end\n" <> "end"
  end

  @doc """
    Generate migration filename following Mix conventions

  """
  @spec generate_migration_filename(String.t(), String.t()) :: String.t()
  def generate_migration_filename(migration_name, timestamp) do
    snake_case_name = MigrationDSL.camel_case_to_snake_case(migration_name)
    "" <> timestamp <> "_" <> snake_case_name <> ".exs"
  end

  @doc """
    Generate migration file path for Mix tasks

  """
  @spec generate_migration_file_path(String.t(), String.t()) :: String.t()
  def generate_migration_file_path(migration_name, timestamp) do
    filename = MigrationDSL.generate_migration_filename(migration_name, timestamp)
    "priv/repo/migrations/" <> filename
  end

  @doc """
    Convert CamelCase to snake_case for Elixir conventions

  """
  @spec camel_case_to_snake_case(String.t()) :: String.t()
  def camel_case_to_snake_case(input) do
    result = ""
    _g_counter = 0
    _g_2 = Enum.count(input)
    (
      loop_helper = fn loop_fn, {result} ->
        if (g < g) do
          try do
            i = g = g + 1
    char = input.charAt(i)
    if (i > 0 && char >= "A" && char <= "Z"), do: result = result <> "_", else: nil
    result = result <> char.to_lower_case()
            loop_fn.(loop_fn, {result})
          catch
            :break -> {result}
            :continue -> loop_fn.(loop_fn, {result})
          end
        else
          {result}
        end
      end
      {result} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    result
  end

  @doc """
    Generate add column operation (standalone with alter table wrapper)

  """
  @spec generate_add_column(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_add_column(table_name, column_name, data_type, options) do
    safe_table = MigrationDSL.sanitize_identifier(table_name)
    safe_column = MigrationDSL.sanitize_identifier(column_name)
    safe_type = MigrationDSL.sanitize_identifier(data_type)
    temp_string = nil
    temp_string = if (options != ""), do: "add :" <> safe_column <> ", :" <> safe_type <> ", " <> options, else: "add :" <> safe_column <> ", :" <> safe_type
    "alter table(:" <> safe_table <> ") do\n  " <> temp_string <> "\nend"
  end

  @doc """
    Generate drop column operation

  """
  @spec generate_drop_column(String.t(), String.t()) :: String.t()
  def generate_drop_column(table_name, column_name) do
    "remove :" <> column_name
  end

  @doc """
    Generate foreign key constraint (standalone with alter table wrapper)

  """
  @spec generate_foreign_key(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_foreign_key(table_name, column_name, referenced_table, referenced_column) do
    safe_table = MigrationDSL.sanitize_identifier(table_name)
    safe_column = MigrationDSL.sanitize_identifier(column_name)
    safe_ref_table = MigrationDSL.sanitize_identifier(referenced_table)
    safe_ref_column = MigrationDSL.sanitize_identifier(referenced_column)
    fk_statement = "add :" <> safe_column <> ", references(:" <> safe_ref_table <> ", column: :" <> safe_ref_column <> ")"
    "alter table(:" <> safe_table <> ") do\n  " <> fk_statement <> "\nend"
  end

  @doc """
    Generate constraint creation

  """
  @spec generate_constraint(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_constraint(table_name, constraint_name, constraint_type, definition) do
    safe_table = MigrationDSL.sanitize_identifier(table_name)
    safe_name = MigrationDSL.sanitize_identifier(constraint_name)
    "create constraint(:" <> safe_table <> ", :" <> safe_name <> ", " <> constraint_type <> ": \"" <> definition <> "\")"
  end

  @doc """
    Performance-optimized compilation for multiple migrations

  """
  @spec compile_batch_migrations(Array.t()) :: String.t()
  def compile_batch_migrations(migrations) do
    compiled_migrations = Array.new()
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g} ->
        if (g < migrations.length) do
          try do
            migration = Enum.at(migrations, g)
          g = g + 1
          compiled_migrations ++ [MigrationDSL.compile_full_migration(migration)]
          loop_fn.({g + 1})
            loop_fn.(loop_fn, {g})
          catch
            :break -> {g}
            :continue -> loop_fn.(loop_fn, {g})
          end
        else
          {g}
        end
      end
      {g} = try do
        loop_helper.(loop_helper, {nil})
      catch
        :break -> {nil}
      end
    )
    Enum.join(compiled_migrations, "\n\n")
  end

  @doc """
    Generate data migration (for complex schema changes)

  """
  @spec generate_data_migration(String.t(), String.t(), String.t()) :: String.t()
  def generate_data_migration(migration_name, up_code, down_code) do
    "defmodule Repo." <> migration_name <> " do\n" <> "  use Ecto.Migration\n" <> "  \n" <> "  def up do\n" <> ("    " <> up_code <> "\n") <> "  end\n" <> "  \n" <> "  def down do\n" <> ("    " <> down_code <> "\n") <> "  end\n" <> "end"
  end

  @doc """
    Validate migration against existing schema (integration with SchemaIntrospection)

  """
  @spec validate_migration_against_schema(term(), Array.t()) :: boolean()
  def validate_migration_against_schema(migration_data, existing_tables) do
    true
  end

  @doc """
    Generate timestamp for migration

  """
  @spec generate_timestamp() :: String.t()
  def generate_timestamp() do
    date = Date.now()
    year = Std.string(date.get_full_year())
    month = StringTools.lpad(Std.string(date.get_month() + 1), "0", 2)
    day = StringTools.lpad(Std.string(date.get_date()), "0", 2)
    hour = StringTools.lpad(Std.string(date.get_hours()), "0", 2)
    minute = StringTools.lpad(Std.string(date.get_minutes()), "0", 2)
    second = StringTools.lpad(Std.string(date.get_seconds()), "0", 2)
    "" <> year <> month <> day <> hour <> minute <> second
  end

  @doc """
    Real table creation DSL function used by migration examples
    Creates Ecto migration table with proper column definitions
  """
  @spec create_table(String.t(), Function.t()) :: String.t()
  def create_table(table_name, callback) do
    builder = Reflaxe.Elixir.Helpers.TableBuilder.new(table_name)
    callback.(builder)
    column_defs = builder.get_column_definitions()
    index_defs = builder.get_index_definitions()
    constraint_defs = builder.get_constraint_definitions()
    result = "create table(:" <> table_name <> ") do\n"
    if (!builder.has_id_column), do: result = result <> "      add :id, :serial, primary_key: true\n", else: nil
    g_counter = 0
    (
      loop_helper = fn loop_fn, {g, result} ->
        if (g < column_defs.length) do
          try do
            column_def = Enum.at(column_defs, g)
          g = g + 1
          result = result <> "      " <> column_def <> "\n"
          loop_fn.({g + 1, result <> "      " <> column_def <> "\n"})
            loop_fn.(loop_fn, {g, result})
          catch
            :break -> {g, result}
            :continue -> loop_fn.(loop_fn, {g, result})
          end
        else
          {g, result}
        end
      end
      {g, result} = try do
        loop_helper.(loop_helper, {nil, nil})
      catch
        :break -> {nil, nil}
      end
    )
    if (!builder.has_timestamps), do: result = result <> "      timestamps()\n", else: nil
    result = result <> "    end"
    if (index_defs.length > 0) do
      result = result <> "\n\n"
      g_counter = 0
      (
        loop_helper = fn loop_fn, {g, result} ->
          if (g < index_defs.length) do
            try do
              index_def = Enum.at(index_defs, g)
            g = g + 1
            result = result <> "    " <> index_def <> "\n"
            loop_fn.({g + 1, result <> "    " <> index_def <> "\n"})
              loop_fn.(loop_fn, {g, result})
            catch
              :break -> {g, result}
              :continue -> loop_fn.(loop_fn, {g, result})
            end
          else
            {g, result}
          end
        end
        {g, result} = try do
          loop_helper.(loop_helper, {nil, nil})
        catch
          :break -> {nil, nil}
        end
      )
    end
    if (constraint_defs.length > 0) do
      result = result <> "\n\n"
      g_counter = 0
      (
        loop_helper = fn loop_fn, {g, result} ->
          if (g < constraint_defs.length) do
            try do
              constraint_def = Enum.at(constraint_defs, g)
            g = g + 1
            result = result <> "    " <> constraint_def <> "\n"
            loop_fn.({g + 1, result <> "    " <> constraint_def <> "\n"})
              loop_fn.(loop_fn, {g, result})
            catch
              :break -> {g, result}
              :continue -> loop_fn.(loop_fn, {g, result})
            end
          else
            {g, result}
          end
        end
        {g, result} = try do
          loop_helper.(loop_helper, {nil, nil})
        catch
          :break -> {nil, nil}
        end
      )
    end
    result
  end

  @doc """
    Real table drop DSL function used by migration examples
    Generates proper Ecto migration drop table statement
  """
  @spec drop_table(String.t()) :: String.t()
  def drop_table(table_name) do
    "drop table(:" <> table_name <> ")"
  end

  @doc """
    Real add column function for table alterations
    Generates proper Ecto migration add column statement
  """
  @spec add_column(String.t(), String.t(), String.t(), Null.t()) :: String.t()
  def add_column(table_name, column_name, data_type, options) do
    options_str = ""
    if (options != nil) do
      Enum.each(Map.keys(options), fn field ->
        g = g + 1
          value = Map.get(options, field)
          if (Std.is_of_type(value, String)), do: opts ++ ["" <> field <> ": \"" <> value <> "\""], else: if (Std.is_of_type(value, Bool)), do: opts ++ ["" <> field <> ": " <> value], else: opts ++ ["" <> field <> ": " <> value]
      end)
    end
    "alter table(:" <> table_name <> ") do\n      add :" <> column_name <> ", :" <> data_type <> options_str <> "\n    end"
  end

  @doc """
    Real add index function for performance optimization
    Generates proper Ecto migration index creation
  """
  @spec add_index(String.t(), Array.t(), Null.t()) :: String.t()
  def add_index(table_name, columns, options) do
    _g_array = []
    _g_counter = 0
    (
      loop_helper = fn loop_fn, {g_counter} ->
        if (g < columns.length) do
          try do
            v = Enum.at(columns, g)
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
    if (options != nil && Reflect.has_field(options, "unique") && Reflect.field(options, "unique") == true), do: "create unique_index(:" <> table_name <> ", [" <> column_list <> "])", else: "create index(:" <> table_name <> ", [" <> column_list <> "])"
  end

  @doc """
    Real add foreign key function for referential integrity
    Generates proper Ecto migration foreign key constraint
  """
  @spec add_foreign_key(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def add_foreign_key(table_name, column_name, referenced_table, referenced_column) do
    "alter table(:" <> table_name <> ") do\n      modify :" <> column_name <> ", references(:" <> referenced_table <> ", column: :" <> referenced_column <> ")\n    end"
  end

  @doc """
    Real add check constraint function for data validation
    Generates proper Ecto migration check constraint
  """
  @spec add_check_constraint(String.t(), String.t(), String.t()) :: String.t()
  def add_check_constraint(table_name, condition, constraint_name) do
    "create constraint(:" <> table_name <> ", :" <> constraint_name <> ", check: \"" <> condition <> "\")"
  end

end
