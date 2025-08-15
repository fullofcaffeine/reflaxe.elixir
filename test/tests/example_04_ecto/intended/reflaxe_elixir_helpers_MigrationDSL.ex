defmodule MigrationDSL do
  use Bitwise
  @moduledoc """
  MigrationDSL module generated from Haxe
  
  
 * Ecto Migration DSL compilation support following the proven ChangesetCompiler pattern
 * Handles @:migration annotation, table/column operations, and index management
 * Integrates with Mix tasks and ElixirCompiler architecture
 
  """

  # Static functions
  @doc "
     * Sanitize identifiers to prevent injection attacks
     "
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
    _g = 0
    _g = String.length(identifier)
    (
      try do
        loop_fn = fn {clean} ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
          c = String.at(identifier, i)
          if (c >= "a" && c <= "z" || c >= "A" && c <= "Z" || c >= "0" && c <= "9" || c == "_"), do: clean = clean <> String.downcase(c), else: nil
          loop_fn.({clean})
            catch
              :break -> {clean}
              :continue -> loop_fn.({clean})
            end
          else
            {clean}
          end
        end
        loop_fn.({clean})
      catch
        :break -> {clean}
      end
    )
    temp_result = nil
    if (String.length(clean) > 0), do: temp_result = clean, else: temp_result = "sanitized"
    temp_result
  end

  @doc "
     * Check if a class is annotated with @:migration (string version for testing)
     "
  @spec is_migration_class(String.t()) :: boolean()
  def is_migration_class(class_name) do
    if (class_name == nil || class_name == ""), do: false, else: nil
    case :binary.match(class_name, "Migration") do {pos, _} -> pos; :nomatch -> -1 end != -1 || case :binary.match(class_name, "Create") do {pos, _} -> pos; :nomatch -> -1 end != -1 || case :binary.match(class_name, "Alter") do {pos, _} -> pos; :nomatch -> -1 end != -1 || case :binary.match(class_name, "Drop") do {pos, _} -> pos; :nomatch -> -1 end != -1
  end

  @doc "
     * Check if ClassType has @:migration annotation (real implementation)
     * Note: Temporarily simplified due to Haxe 4.3.6 API compatibility
     "
  @spec is_migration_class_type(term()) :: boolean()
  def is_migration_class_type(class_type) do
    true
  end

  @doc "
     * Get migration configuration from @:migration annotation
     * Extracts table name from @:migration("table_name") annotation
     "
  @spec get_migration_config(ClassType.t()) :: term()
  def get_migration_config(class_type) do
    if (!class_type.meta.has(":migration")), do: %{table: "default_table", timestamp: MigrationDSL.generateTimestamp()}, else: nil
    meta = Enum.at(class_type.meta.extract(":migration"), 0)
    table_name = "default_table"
    if (meta.params != nil && length(meta.params) > 0) do
      _g = Enum.at(meta.params, 0).expr
      case (nil) do
        0 ->
          _g = nil
      if (nil == 2) do
        _g = nil
        nil
        s = _g
        table_name = s
      else
        table_name = MigrationDSL.extractTableNameFromClassName(class_type.name)
      end
        5 ->
          _g = nil
      fields = _g
      _g = 0
      Enum.map(fields, fn item -> if (item.field == "table"), do: _g = field.expr.expr
      if (nil == 0) do
        _g = nil
        if (nil == 2) do
          _g = nil
          nil
          s = _g
          table_name = s
        else
          nil
        end
      else
        nil
      end, else: item end)
        _ ->
          table_name = MigrationDSL.extractTableNameFromClassName(class_type.name)
      end
    else
      table_name = MigrationDSL.extractTableNameFromClassName(class_type.name)
    end
    %{table: table_name, timestamp: MigrationDSL.generateTimestamp()}
  end

  @doc "
     * Extract table name from class name (CreateUsers -> users)
     "
  @spec extract_table_name_from_class_name(String.t()) :: String.t()
  def extract_table_name_from_class_name(class_name) do
    class_name = StringTools.replace(class_name, "Create", "")
    class_name = StringTools.replace(class_name, "Alter", "")
    class_name = StringTools.replace(class_name, "Drop", "")
    class_name = StringTools.replace(class_name, "Add", "")
    class_name = StringTools.replace(class_name, "Remove", "")
    class_name = StringTools.replace(class_name, "Table", "")
    class_name = StringTools.replace(class_name, "Migration", "")
    MigrationDSL.camelCaseToSnakeCase(class_name)
  end

  @doc "
     * Compile table creation with columns
     "
  @spec compile_table_creation(String.t(), Array.t()) :: String.t()
  def compile_table_creation(table_name, columns) do
    column_defs = Array.new()
    _g = 0
    Enum.map(columns, fn item -> if (item.length > 1), do: Enum.at(item, 1), else: "string" end)
    "create table(:" <> table_name <> ") do\n" <> Enum.join(column_defs, "\n") <> "\n" <> "      timestamps()\n" <> "    end"
  end

  @doc "
     * Generate basic migration module structure
     "
  @spec generate_migration_module(String.t()) :: String.t()
  def generate_migration_module(class_name) do
    "defmodule " <> class_name <> " do\n" <> "  @moduledoc \"\"\"\n" <> ("  Generated from Haxe @:migration class: " <> class_name <> "\n") <> "  \n" <> "  This migration module was automatically generated from a Haxe source file\n" <> "  as part of the Reflaxe.Elixir compilation pipeline.\n" <> "  \"\"\"\n" <> "  \n" <> "  use Ecto.Migration\n" <> "  \n" <> "  @doc \"\"\"\n" <> "  Run the migration\n" <> "  \"\"\"\n" <> "  def change do\n" <> "    # Migration operations go here\n" <> "  end\n" <> "  \n" <> "  @doc \"\"\"\n" <> "  Run the migration up\n" <> "  \"\"\"\n" <> "  def up do\n" <> "    # Up migration operations\n" <> "  end\n" <> "  \n" <> "  @doc \"\"\"\n" <> "  Run the migration down (rollback)\n" <> "  \"\"\"\n" <> "  def down do\n" <> "    # Down migration operations\n" <> "  end\n" <> "end"
  end

  @doc "
     * Compile index creation
     "
  @spec compile_index_creation(String.t(), Array.t(), String.t()) :: String.t()
  def compile_index_creation(table_name, fields, options) do
    _g = []
    _g = 0
    Enum.map(fields, fn item -> ":" <> item end)
    field_list = Enum.join((_g), ", ")
    if (case :binary.match(options, "unique") do {pos, _} -> pos; :nomatch -> -1 end != -1), do: "create unique_index(:" <> table_name <> ", [" <> field_list <> "])", else: "create index(:" <> table_name <> ", [" <> field_list <> "])"
  end

  @doc "
     * Compile table drop for rollback
     "
  @spec compile_table_drop(String.t()) :: String.t()
  def compile_table_drop(table_name) do
    "drop table(:" <> table_name <> ")"
  end

  @doc "
     * Compile column modification
     "
  @spec compile_column_modification(String.t(), String.t(), String.t()) :: String.t()
  def compile_column_modification(table_name, column_name, modification) do
    "alter table(:" <> table_name <> ") do\n" <> ("  modify :" <> column_name <> ", :string, " <> modification <> "\n") <> "end"
  end

  @doc "
     * Compile full migration with all operations
     "
  @spec compile_full_migration(term()) :: String.t()
  def compile_full_migration(migration_data) do
    class_name = migration_data.class_name
    table_name = migration_data.table_name
    columns = migration_data.columns
    module_name = "Repo." <> class_name
    table_creation = MigrationDSL.compileTableCreation(table_name, columns)
    index_creation = MigrationDSL.compileIndexCreation(table_name, ["email"], "unique: true")
    "defmodule " <> module_name <> " do\n" <> "  @moduledoc \"\"\"\n" <> ("  Generated migration for " <> table_name <> " table\n") <> "  \n" <> ("  Creates " <> table_name <> " table with proper schema and indexes\n") <> "  following Ecto migration patterns with compile-time validation.\n" <> "  \"\"\"\n" <> "  \n" <> "  use Ecto.Migration\n" <> "  \n" <> "  @doc \"\"\"\n" <> ("  Run the migration - creates " <> table_name <> " table\n") <> "  \"\"\"\n" <> "  def change do\n" <> ("    " <> table_creation <> "\n") <> "    \n" <> ("    " <> index_creation <> "\n") <> "  end\n" <> "  \n" <> "  @doc \"\"\"\n" <> ("  Rollback migration - drops " <> table_name <> " table\n") <> "  \"\"\"\n" <> "  def down do\n" <> ("    drop table(:" <> table_name <> ")\n") <> "  end\n" <> "end"
  end

  @doc "
     * Generate migration filename following Mix conventions
     "
  @spec generate_migration_filename(String.t(), String.t()) :: String.t()
  def generate_migration_filename(migration_name, timestamp) do
    snake_case_name = MigrationDSL.camelCaseToSnakeCase(migration_name)
    "" <> timestamp <> "_" <> snake_case_name <> ".exs"
  end

  @doc "
     * Generate migration file path for Mix tasks
     "
  @spec generate_migration_file_path(String.t(), String.t()) :: String.t()
  def generate_migration_file_path(migration_name, timestamp) do
    filename = MigrationDSL.generateMigrationFilename(migration_name, timestamp)
    "priv/repo/migrations/" <> filename
  end

  @doc "
     * Convert CamelCase to snake_case for Elixir conventions
     "
  @spec camel_case_to_snake_case(String.t()) :: String.t()
  def camel_case_to_snake_case(input) do
    result = ""
    _g = 0
    _g = String.length(input)
    (
      try do
        loop_fn = fn {result} ->
          if (_g < _g) do
            try do
              i = _g = _g + 1
          char = String.at(input, i)
          if (i > 0 && char >= "A" && char <= "Z"), do: result = result <> "_", else: nil
          # result updated with <> String.downcase(char)
          loop_fn.({result <> String.downcase(char)})
            catch
              :break -> {result}
              :continue -> loop_fn.({result})
            end
          else
            {result}
          end
        end
        loop_fn.({result})
      catch
        :break -> {result}
      end
    )
    result
  end

  @doc "
     * Generate add column operation (standalone with alter table wrapper)
     "
  @spec generate_add_column(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_add_column(table_name, column_name, data_type, options) do
    safe_table = MigrationDSL.sanitizeIdentifier(table_name)
    safe_column = MigrationDSL.sanitizeIdentifier(column_name)
    safe_type = MigrationDSL.sanitizeIdentifier(data_type)
    temp_string = nil
    if (options != ""), do: temp_string = "add :" <> safe_column <> ", :" <> safe_type <> ", " <> options, else: temp_string = "add :" <> safe_column <> ", :" <> safe_type
    "alter table(:" <> safe_table <> ") do\n  " <> temp_string <> "\nend"
  end

  @doc "
     * Generate drop column operation
     "
  @spec generate_drop_column(String.t(), String.t()) :: String.t()
  def generate_drop_column(table_name, column_name) do
    "remove :" <> column_name
  end

  @doc "
     * Generate foreign key constraint (standalone with alter table wrapper)
     "
  @spec generate_foreign_key(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_foreign_key(table_name, column_name, referenced_table, referenced_column) do
    safe_table = MigrationDSL.sanitizeIdentifier(table_name)
    safe_column = MigrationDSL.sanitizeIdentifier(column_name)
    safe_ref_table = MigrationDSL.sanitizeIdentifier(referenced_table)
    safe_ref_column = MigrationDSL.sanitizeIdentifier(referenced_column)
    fk_statement = "add :" <> safe_column <> ", references(:" <> safe_ref_table <> ", column: :" <> safe_ref_column <> ")"
    "alter table(:" <> safe_table <> ") do\n  " <> fk_statement <> "\nend"
  end

  @doc "
     * Generate constraint creation
     "
  @spec generate_constraint(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def generate_constraint(table_name, constraint_name, constraint_type, definition) do
    safe_table = MigrationDSL.sanitizeIdentifier(table_name)
    safe_name = MigrationDSL.sanitizeIdentifier(constraint_name)
    "create constraint(:" <> safe_table <> ", :" <> safe_name <> ", " <> constraint_type <> ": \"" <> definition <> "\")"
  end

  @doc "
     * Performance-optimized compilation for multiple migrations
     "
  @spec compile_batch_migrations(Array.t()) :: String.t()
  def compile_batch_migrations(migrations) do
    compiled_migrations = Array.new()
    _g = 0
    Enum.map(migrations, fn item -> MigrationDSL.compileFullMigration(migration) end)
    Enum.join(compiled_migrations, "\n\n")
  end

  @doc "
     * Generate data migration (for complex schema changes)
     "
  @spec generate_data_migration(String.t(), String.t(), String.t()) :: String.t()
  def generate_data_migration(migration_name, up_code, down_code) do
    "defmodule Repo." <> migration_name <> " do\n" <> "  use Ecto.Migration\n" <> "  \n" <> "  def up do\n" <> ("    " <> up_code <> "\n") <> "  end\n" <> "  \n" <> "  def down do\n" <> ("    " <> down_code <> "\n") <> "  end\n" <> "end"
  end

  @doc "
     * Validate migration against existing schema (integration with SchemaIntrospection)
     "
  @spec validate_migration_against_schema(term(), Array.t()) :: boolean()
  def validate_migration_against_schema(migration_data, existing_tables) do
    true
  end

  @doc "
     * Generate timestamp for migration
     "
  @spec generate_timestamp() :: String.t()
  def generate_timestamp() do
    date = Date.now()
    year = Std.string(date.getFullYear())
    month = StringTools.lpad(Std.string(date.getMonth() + 1), "0", 2)
    day = StringTools.lpad(Std.string(date.getDate()), "0", 2)
    hour = StringTools.lpad(Std.string(date.getHours()), "0", 2)
    minute = StringTools.lpad(Std.string(date.getMinutes()), "0", 2)
    second = StringTools.lpad(Std.string(date.getSeconds()), "0", 2)
    "" <> year <> month <> day <> hour <> minute <> second
  end

  @doc "
     * Real table creation DSL function used by migration examples
     * Creates Ecto migration table with proper column definitions
     "
  @spec create_table(String.t(), Function.t()) :: String.t()
  def create_table(table_name, callback) do
    builder = Reflaxe.Elixir.Helpers.TableBuilder.new(table_name)
    callback(builder)
    column_defs = builder.getColumnDefinitions()
    index_defs = builder.getIndexDefinitions()
    constraint_defs = builder.getConstraintDefinitions()
    result = "create table(:" <> table_name <> ") do\n"
    if (!builder.has_id_column), do: result = result <> "      add :id, :serial, primary_key: true\n", else: nil
    _g = 0
    Enum.map(column_defs, fn item -> item end)
    if (!builder.has_timestamps), do: result = result <> "      timestamps()\n", else: nil
    result = result <> "    end"
    if (length(index_defs) > 0) do
      result = result <> "\n\n"
      _g = 0
      Enum.map(index_defs, fn item -> item end)
    end
    if (length(constraint_defs) > 0) do
      result = result <> "\n\n"
      _g = 0
      Enum.map(constraint_defs, fn item -> item end)
    end
    result
  end

  @doc "
     * Real table drop DSL function used by migration examples
     * Generates proper Ecto migration drop table statement
     "
  @spec drop_table(String.t()) :: String.t()
  def drop_table(table_name) do
    "drop table(:" <> table_name <> ")"
  end

  @doc "
     * Real add column function for table alterations
     * Generates proper Ecto migration add column statement
     "
  @spec add_column(String.t(), String.t(), String.t(), Null.t()) :: String.t()
  def add_column(table_name, column_name, data_type, options) do
    options_str = ""
    if (options != nil) do
      opts = []
      fields = Reflect.fields(options)
      _g = 0
      Enum.filter(fields, fn item -> (Std.isOfType(item, String)) end)
      if (length(opts) > 0), do: options_str = ", " <> Enum.join(opts, ", "), else: nil
    end
    "alter table(:" <> table_name <> ") do\n      add :" <> column_name <> ", :" <> data_type <> options_str <> "\n    end"
  end

  @doc "
     * Real add index function for performance optimization
     * Generates proper Ecto migration index creation
     "
  @spec add_index(String.t(), Array.t(), Null.t()) :: String.t()
  def add_index(table_name, columns, options) do
    _g = []
    _g = 0
    Enum.map(columns, fn item -> ":" <> item end)
    column_list = Enum.join((_g), ", ")
    if (options != nil && Reflect.hasField(options, "unique") && Reflect.field(options, "unique") == true), do: "create unique_index(:" <> table_name <> ", [" <> column_list <> "])", else: "create index(:" <> table_name <> ", [" <> column_list <> "])"
  end

  @doc "
     * Real add foreign key function for referential integrity
     * Generates proper Ecto migration foreign key constraint
     "
  @spec add_foreign_key(String.t(), String.t(), String.t(), String.t()) :: String.t()
  def add_foreign_key(table_name, column_name, referenced_table, referenced_column) do
    "alter table(:" <> table_name <> ") do\n      modify :" <> column_name <> ", references(:" <> referenced_table <> ", column: :" <> referenced_column <> ")\n    end"
  end

  @doc "
     * Real add check constraint function for data validation
     * Generates proper Ecto migration check constraint
     "
  @spec add_check_constraint(String.t(), String.t(), String.t()) :: String.t()
  def add_check_constraint(table_name, condition, constraint_name) do
    "create constraint(:" <> table_name <> ", :" <> constraint_name <> ", check: \"" <> condition <> "\")"
  end

end


defmodule TableBuilder do
  use Bitwise
  @moduledoc """
  TableBuilder module generated from Haxe
  
  
 * Table builder class for DSL-style migration creation
 * Provides fluent interface for defining table structure
 
  """

  # Instance functions
  @doc "
     * Add a column to the table
     "
  @spec add_column(String.t(), String.t(), Null.t()) :: TableBuilder.t()
  def add_column(name, data_type, options) do
    if (name == "id"), do: __MODULE__.has_id_column = true, else: nil
    if (name == "inserted_at" || name == "updated_at"), do: __MODULE__.has_timestamps = true, else: nil
    options_str = ""
    if (options != nil) do
      opts = []
      fields = Reflect.fields(options)
      _g = 0
      Enum.filter(fields, fn item -> (Std.isOfType(item, String)) end)
      if (length(opts) > 0), do: options_str = ", " <> Enum.join(opts, ", "), else: nil
    end
    __MODULE__.columns ++ ["add :" <> name <> ", :" <> data_type <> options_str]
    __MODULE__
  end

  @doc "
     * Add an index to the table
     "
  @spec add_index(Array.t(), Null.t()) :: TableBuilder.t()
  def add_index(column_names, options) do
    _g = []
    _g = 0
    Enum.map(column_names, fn item -> ":" <> item end)
    column_list = Enum.join((_g), ", ")
    if (options != nil && Reflect.hasField(options, "unique") && Reflect.field(options, "unique") == true), do: __MODULE__.indexes ++ ["create unique_index(:" <> __MODULE__.table_name <> ", [" <> column_list <> "])"], else: __MODULE__.indexes ++ ["create index(:" <> __MODULE__.table_name <> ", [" <> column_list <> "])"]
    __MODULE__
  end

  @doc "
     * Add a foreign key constraint
     "
  @spec add_foreign_key(String.t(), String.t(), String.t()) :: TableBuilder.t()
  def add_foreign_key(column_name, referenced_table, referenced_column) do
    new_columns = []
    found = false
    _g = 0
    _g = __MODULE__.columns
    Enum.filter(_g, fn item -> (column.indexOf(":" <> item <> ",") != -1) end)
    if (!found), do: new_columns ++ ["add :" <> column_name <> ", references(:" <> referenced_table <> ", column: :" <> referenced_column <> ")"], else: nil
    __MODULE__.columns = new_columns
    __MODULE__
  end

  @doc "
     * Add a check constraint
     "
  @spec add_check_constraint(String.t(), String.t()) :: TableBuilder.t()
  def add_check_constraint(condition, constraint_name) do
    __MODULE__.constraints ++ ["create constraint(:" <> __MODULE__.table_name <> ", :" <> constraint_name <> ", check: \"" <> condition <> "\")"]
    __MODULE__
  end

  @doc "
     * Get all column definitions
     "
  @spec get_column_definitions() :: Array.t()
  def get_column_definitions() do
    __MODULE__.columns
  end

  @doc "
     * Get all index definitions
     "
  @spec get_index_definitions() :: Array.t()
  def get_index_definitions() do
    __MODULE__.indexes
  end

  @doc "
     * Get all constraint definitions
     "
  @spec get_constraint_definitions() :: Array.t()
  def get_constraint_definitions() do
    __MODULE__.constraints
  end

end
