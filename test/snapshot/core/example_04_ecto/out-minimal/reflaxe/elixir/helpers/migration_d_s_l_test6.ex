defmodule MigrationDSLTest6 do
  @moduledoc """
    MigrationDSLTest6 module generated from Haxe

     * Ecto Migration DSL compilation support following the proven ChangesetCompiler pattern
     * Handles @:migration annotation, table/column operations, and index management
     * Integrates with Mix tasks and ElixirCompiler architecture
  """

  # Static functions
  @doc "Generated from Haxe sanitizeIdentifier"
  def sanitize_identifier(identifier) do
    temp_result = nil

    if (((identifier == nil) || (identifier == ""))) do
      "unnamed"
    else
      nil
    end

    identifier = Enum.join(identifier.split("';"), "")

    identifier = Enum.join(identifier.split("--"), "")

    identifier = Enum.join(identifier.split("DROP"), "")

    identifier = Enum.join(identifier.split(""), "")

    identifier = Enum.join(identifier.split("/*"), "")

    identifier = Enum.join(identifier.split("*/"), "")

    clean = ""

    g_counter = 0

    g_array = identifier.length

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
        fn -> ((g_counter < g_array)) end,
        fn ->
          i = g_counter + 1
          c = identifier.char_at(i)
          if ((((((c >= "a") && (c <= "z")) || ((c >= "A") && (c <= "Z"))) || ((c >= "0") && (c <= "9"))) || (c == "_"))), do: clean = clean <> c.to_lower_case(), else: nil
        end,
        loop_helper
      )
    )

    temp_result = nil

    if ((clean.length > 0)), do: temp_result = clean, else: temp_result = "sanitized"

    temp_result
  end

  @doc "Generated from Haxe isMigrationClass"
  def is_migration_class(class_name) do
    if (((class_name == nil) || (class_name == ""))) do
      false
    else
      nil
    end

    ((((class_name.index_of("Migration") != -1) || (class_name.index_of("Create") != -1)) || (class_name.index_of("Alter") != -1)) || (class_name.index_of("Drop") != -1))
  end

  @doc "Generated from Haxe isMigrationClassType"
  def is_migration_class_type(_class_type) do
    true
  end

  @doc "Generated from Haxe getMigrationConfig"
  def get_migration_config(class_type) do
    if (not class_type.meta.has(":migration")) do
      %{"table" => "default_table", "timestamp" => MigrationDSLTest6.generate_timestamp()}
    else
      nil
    end

    meta = Enum.at(class_type.meta.extract(":migration"), 0)

    table_name = "default_table"

    if (((meta.params != nil) && (meta.params.length > 0))) do
      g_array = Enum.at(meta.params, 0).expr
      case (case g_array do :e_const -> 0; :e_array -> 1; :e_binop -> 2; :e_field -> 3; :e_parenthesis -> 4; :e_object_decl -> 5; :e_array_decl -> 6; :e_call -> 7; :e_new -> 8; :e_unop -> 9; :e_vars -> 10; :e_function -> 11; :e_block -> 12; :e_for -> 13; :e_if -> 14; :e_while -> 15; :e_switch -> 16; :e_try -> 17; :e_return -> 18; :e_break -> 19; :e_continue -> 20; :e_untyped -> 21; :e_throw -> 22; :e_cast -> 23; :e_display -> 24; :e_ternary -> 25; :e_check_type -> 26; :e_meta -> 27; :e_is -> 28; _ -> -1 end) do
        0 -> if ((case g_array do :c_int -> 0; :c_float -> 1; :c_string -> 2; :c_ident -> 3; :c_regexp -> 4; _ -> -1 end == 2)) do
        table_name = s
      else
        table_name = MigrationDSLTest6.extract_table_name_from_class_name(class_type.name)
      end
        {5, fields} -> g_array = elem(g_array, 1)
      g_counter = 0
      Enum.filter(fields, fn item -> item.field == "table" end)
        _ -> table_name = MigrationDSLTest6.extract_table_name_from_class_name(class_type.name)
      end
    else
      table_name = MigrationDSLTest6.extract_table_name_from_class_name(class_type.name)
    end

    %{"table" => table_name, "timestamp" => MigrationDSLTest6.generate_timestamp()}
  end

  @doc "Generated from Haxe extractTableNameFromClassName"
  def extract_table_name_from_class_name(class_name) do
    class_name = StringTools.replace(class_name, "Create", "")

    class_name = StringTools.replace(class_name, "Alter", "")

    class_name = StringTools.replace(class_name, "Drop", "")

    class_name = StringTools.replace(class_name, "Add", "")

    class_name = StringTools.replace(class_name, "Remove", "")

    class_name = StringTools.replace(class_name, "Table", "")

    class_name = StringTools.replace(class_name, "Migration", "")

    MigrationDSLTest6.camel_case_to_snake_case(class_name)
  end

  @doc "Generated from Haxe compileTableCreation"
  def compile_table_creation(table_name, columns) do
    column_defs = Array.new()

    g_counter = 0

    Enum.filter(columns, fn item -> parts.length > 1 end)

    "create table(:" <> table_name <> ") do\n" <> Enum.join(column_defs, "\n") <> "\n" <> "      timestamps()\n" <> "    end"
  end

  @doc "Generated from Haxe generateTimestamp"
  def generate_timestamp() do
    "20250101000000"
  end

  @doc "Generated from Haxe camelCaseToSnakeCase"
  def camel_case_to_snake_case(s) do
    s.to_lower_case()
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
