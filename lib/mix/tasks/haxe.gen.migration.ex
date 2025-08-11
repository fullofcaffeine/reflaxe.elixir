defmodule Mix.Tasks.Haxe.Gen.Migration do
  @moduledoc """
  Mix task for generating Haxe-based Ecto migrations.
  
  Generates a migration file based on a Haxe @:migration annotated class.
  This integrates Reflaxe.Elixir migrations with the standard Mix workflow.

  ## Examples

      mix haxe.gen.migration CreateUsersTable
      mix haxe.gen.migration AlterPostsTable --table posts
      mix haxe.gen.migration AddIndexToUsers --index email

  ## Options

    * `--table` - Specify the table name (defaults to inferred from migration name)
    * `--columns` - Comma-separated list of columns (e.g., "name:string,email:string,age:integer")
    * `--index` - Add an index on the specified field(s)
    * `--unique` - Make the index unique
    * `--haxe-dir` - Directory for Haxe migration files (default: "src_haxe/migrations")
    * `--elixir-dir` - Directory for generated Elixir migrations (default: "priv/repo/migrations")

  """
  use Mix.Task

  @shortdoc "Generates a new Haxe-based migration"

  @doc """
  Entry point for the Mix task
  """
  def run(args) do
    {opts, [migration_name | _], _} = OptionParser.parse(args, 
      switches: [
        table: :string,
        columns: :string, 
        index: :string,
        unique: :boolean,
        haxe_dir: :string,
        elixir_dir: :string
      ]
    )

    if migration_name == nil do
      Mix.shell().error("Migration name is required. Usage: mix haxe.gen.migration MigrationName")
      System.halt(1)
    end

    generate_migration(migration_name, opts)
  end

  # Generate both Haxe source file and compiled Elixir migration
  defp generate_migration(migration_name, opts) do
    # Configuration
    haxe_dir = Keyword.get(opts, :haxe_dir, "src_haxe/migrations")
    elixir_dir = Keyword.get(opts, :elixir_dir, "priv/repo/migrations")
    table_name = Keyword.get(opts, :table, infer_table_name(migration_name))
    columns = parse_columns(Keyword.get(opts, :columns, ""))
    
    # Generate timestamp
    timestamp = generate_timestamp()
    
    # Create directories
    File.mkdir_p!(haxe_dir)
    File.mkdir_p!(elixir_dir)
    
    # Generate Haxe migration file
    haxe_content = generate_haxe_migration_content(migration_name, table_name, columns, opts)
    haxe_filename = "#{haxe_dir}/#{migration_name}.hx"
    
    File.write!(haxe_filename, haxe_content)
    Mix.shell().info("Generated Haxe migration: #{haxe_filename}")
    
    # Generate Elixir migration file using Reflaxe.Elixir
    elixir_content = generate_elixir_migration_content(migration_name, table_name, columns, opts, timestamp)
    elixir_filename = "#{elixir_dir}/#{timestamp}_#{Macro.underscore(migration_name)}.exs"
    
    File.write!(elixir_filename, elixir_content)
    Mix.shell().info("Generated Elixir migration: #{elixir_filename}")
    
    # Display next steps
    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("  1. Edit #{haxe_filename} to customize your migration")
    Mix.shell().info("  2. Run: mix compile to compile Haxe to Elixir") 
    Mix.shell().info("  3. Run: mix ecto.migrate to apply the migration")
    
    :ok
  end

  # Generate Haxe migration source file content
  defp generate_haxe_migration_content(migration_name, table_name, columns, opts) do
    index_field = Keyword.get(opts, :index)
    unique = Keyword.get(opts, :unique, false)
    
    column_definitions = columns
    |> Enum.map(fn {name, type} -> "  public var #{name}: #{haxe_type_from_elixir(type)};" end)
    |> Enum.join("\n")
    
    index_annotation = if index_field do
      unique_option = if unique, do: ", unique: true", else: ""
      "@:index(\"#{index_field}\"#{unique_option})\n"
    else
      ""
    end

    """
    package migrations;

    /**
     * Generated Haxe migration: #{migration_name}
     * 
     * This migration will create/modify the #{table_name} table.
     * Customize the fields and operations below, then run `mix compile` 
     * to generate the corresponding Elixir migration.
     */
    @:migration(table: "#{table_name}")
    #{index_annotation}class #{migration_name} {
      
    #{column_definitions}
      
      /**
       * Custom migration operations
       * Functions starting with 'migrate' will be included in the migration
       */
      public function migrateCustomOperation(): Void {
        // Add any custom migration logic here
        // This will be compiled to the migration's change/up function
      }
      
      /**
       * Rollback operations  
       * Functions starting with 'rollback' will be included in the down function
       */
      public function rollbackCustomOperation(): Void {
        // Add any custom rollback logic here
      }
    }
    """
  end

  # Generate Elixir migration content (immediate compilation)
  defp generate_elixir_migration_content(migration_name, table_name, columns, opts, _timestamp) do
    index_field = Keyword.get(opts, :index)
    unique = Keyword.get(opts, :unique, false)
    
    # Generate table creation
    column_definitions = columns
    |> Enum.map(fn {name, type} -> "      add :#{name}, :#{type}" end)
    |> Enum.join("\n")
    
    # Generate index creation if specified
    index_creation = if index_field do
      if unique do
        "    create unique_index(:#{table_name}, [:#{index_field}])"
      else
        "    create index(:#{table_name}, [:#{index_field}])"
      end
    else
      ""
    end

    # Get the application module name from config or use a default
    app_module = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    module_name = "#{app_module}.Repo.Migrations.#{migration_name}"

    """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      Generated from Haxe @:migration class: #{migration_name}
      
      Creates #{table_name} table with Haxe-defined schema.
      This migration was automatically generated from a Haxe source file
      as part of the Reflaxe.Elixir compilation pipeline.
      \"\"\"
      
      use Ecto.Migration

      @doc \"\"\"
      Run the migration - creates #{table_name} table
      \"\"\"
      def change do
        create table(:#{table_name}) do
    #{column_definitions}
          timestamps()
        end
        
    #{index_creation}
      end
      
      @doc \"\"\"
      Rollback migration - drops #{table_name} table  
      \"\"\"
      def down do
        drop table(:#{table_name})
      end
    end
    """
  end

  # Infer table name from migration class name
  defp infer_table_name(migration_name) do
    migration_name
    |> String.replace(~r/^Create/, "")
    |> String.replace(~r/^Alter/, "")  
    |> String.replace(~r/^Drop/, "")
    |> String.replace(~r/Table$/, "")
    |> Macro.underscore()
  end

  # Parse column specifications from command line
  defp parse_columns(""), do: [{"name", "string"}, {"description", "text"}]
  defp parse_columns(columns_string) do
    columns_string
    |> String.split(",")
    |> Enum.map(fn column_spec ->
      case String.split(column_spec, ":") do
        [name, type] -> {String.trim(name), String.trim(type)}
        [name] -> {String.trim(name), "string"}
      end
    end)
  end

  # Map Elixir migration types to Haxe types
  defp haxe_type_from_elixir("string"), do: "String"
  defp haxe_type_from_elixir("text"), do: "String"
  defp haxe_type_from_elixir("integer"), do: "Int" 
  defp haxe_type_from_elixir("boolean"), do: "Bool"
  defp haxe_type_from_elixir("float"), do: "Float"
  defp haxe_type_from_elixir("datetime"), do: "Date"
  defp haxe_type_from_elixir("naive_datetime"), do: "Date"
  defp haxe_type_from_elixir(_), do: "Dynamic"

  # Generate timestamp for migration filename
  defp generate_timestamp do
    {{year, month, day}, {hour, minute, second}} = :calendar.universal_time()
    
    :io_lib.format("~4..0B~2..0B~2..0B~2..0B~2..0B~2..0B", [year, month, day, hour, minute, second])
    |> List.to_string()
  end
end