defmodule Mix.Tasks.Haxe.Gen.Schema do
  @moduledoc """
  Mix task for generating Ecto schema modules from Haxe @:schema classes.
  
  Generates both Haxe source files with @:schema annotations and the corresponding
  compiled Elixir schema modules with proper Ecto.Schema integration.

  ## Examples

      mix haxe.gen.schema User
      mix haxe.gen.schema Post --table posts
      mix haxe.gen.schema Account --fields "name:string,email:string:unique,age:integer"
      mix haxe.gen.schema Product --belongs-to "User:user" --has-many "Review:reviews"

  ## Options

    * `--table` - Specify the table name (defaults to pluralized schema name)
    * `--fields` - Comma-separated list of fields (e.g., "name:string,email:string,age:integer")
    * `--primary-key` - Specify custom primary key field (default: "id")
    * `--belongs-to` - Add belongs_to associations (format: "Schema:field" or "Schema:field:foreign_key")
    * `--has-many` - Add has_many associations (format: "Schema:field" or "Schema:field:foreign_key") 
    * `--has-one` - Add has_one associations (format: "Schema:field" or "Schema:field:foreign_key")
    * `--timestamps` - Include timestamps (default: true)
    * `--haxe-dir` - Directory for Haxe schema files (default: "src_haxe/schemas")
    * `--elixir-dir` - Directory for generated Elixir schemas (default: "lib")
    * `--changeset` - Generate changeset function (default: true)

  """
  use Mix.Task

  @shortdoc "Generates a new Haxe-based Ecto schema"

  @doc """
  Entry point for the Mix task
  """
  def run(args) do
    {opts, [schema_name | _], _} = OptionParser.parse(args, 
      switches: [
        table: :string,
        fields: :string,
        primary_key: :string,
        belongs_to: [:string, :keep],
        has_many: [:string, :keep], 
        has_one: [:string, :keep],
        timestamps: :boolean,
        haxe_dir: :string,
        elixir_dir: :string,
        changeset: :boolean
      ]
    )

    if schema_name == nil do
      Mix.shell().error("Schema name is required. Usage: mix haxe.gen.schema SchemaName")
      System.halt(1)
    end

    generate_schema(schema_name, opts)
  end

  # Generate both Haxe schema source and compiled Elixir schema
  defp generate_schema(schema_name, opts) do
    # Configuration
    haxe_dir = Keyword.get(opts, :haxe_dir, "src_haxe/schemas")
    elixir_dir = Keyword.get(opts, :elixir_dir, "lib")
    table_name = Keyword.get(opts, :table, infer_table_name(schema_name))
    fields = parse_fields(Keyword.get(opts, :fields, ""))
    
    # Associations
    belongs_to_assocs = parse_associations(Keyword.get_values(opts, :belongs_to))
    has_many_assocs = parse_associations(Keyword.get_values(opts, :has_many))
    has_one_assocs = parse_associations(Keyword.get_values(opts, :has_one))
    
    # Create directories
    File.mkdir_p!(haxe_dir)
    File.mkdir_p!(elixir_dir)
    
    # Generate Haxe schema file
    haxe_content = generate_haxe_schema_content(schema_name, table_name, fields, opts, 
                                              belongs_to_assocs, has_many_assocs, has_one_assocs)
    haxe_filename = "#{haxe_dir}/#{schema_name}.hx"
    
    File.write!(haxe_filename, haxe_content)
    Mix.shell().info("Generated Haxe schema: #{haxe_filename}")
    
    # Generate Elixir schema file using SchemaCompiler patterns
    elixir_content = generate_elixir_schema_content(schema_name, table_name, fields, opts,
                                                  belongs_to_assocs, has_many_assocs, has_one_assocs)
    elixir_filename = "#{elixir_dir}/#{Macro.underscore(schema_name)}.ex"
    
    File.write!(elixir_filename, elixir_content)
    Mix.shell().info("Generated Elixir schema: #{elixir_filename}")
    
    # Display next steps
    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("  1. Edit #{haxe_filename} to customize your schema fields and associations")
    Mix.shell().info("  2. Run: mix compile to compile Haxe to Elixir")
    Mix.shell().info("  3. Run: mix ecto.gen.migration create_#{table_name} to create migration")
    Mix.shell().info("  4. Run: mix ecto.migrate to apply the migration")
    
    :ok
  end

  # Generate Haxe schema source file content
  defp generate_haxe_schema_content(schema_name, table_name, fields, opts, belongs_to, has_many, has_one) do
    primary_key = Keyword.get(opts, :primary_key, "id")
    include_timestamps = Keyword.get(opts, :timestamps, true)
    generate_changeset = Keyword.get(opts, :changeset, true)
    
    # Generate field definitions
    field_definitions = generate_haxe_fields(fields, primary_key, include_timestamps, belongs_to, has_many, has_one)
    
    # Generate changeset annotation if needed
    changeset_annotation = if generate_changeset do
      "@:changeset\n"
    else
      ""
    end

    """
    package schemas;

    /**
     * Generated Haxe schema: #{schema_name}
     * 
     * This schema maps to the #{table_name} table in your database.
     * Customize the fields, associations, and validation rules below.
     * 
     * After editing, run `mix compile` to generate the corresponding Elixir schema.
     */
    @:schema(table: "#{table_name}")
    #{changeset_annotation}class #{schema_name} {
      
    #{field_definitions}
    
      /**
       * Custom validation functions
       * Add your own validation logic here
       */
      public function customValidation(): Bool {
        // Add custom validation logic
        return true;
      }
      
      /**
       * Schema transformations
       * Add any data transformation logic here
       */
      public function transform(): #{schema_name} {
        return this;
      }
    }
    """
  end

  # Generate Haxe field definitions
  defp generate_haxe_fields(fields, primary_key, include_timestamps, belongs_to, has_many, has_one) do
    field_lines = []
    
    # Primary key
    field_lines = ["  @:primary_key\n  public var #{primary_key}: Int;" | field_lines]
    
    # Regular fields
    field_lines = Enum.reduce(fields, field_lines, fn {name, type, opts}, acc ->
      field_annotation = generate_field_annotation(type, opts)
      haxe_type = elixir_type_to_haxe(type)
      ["  #{field_annotation}\n  public var #{name}: #{haxe_type};" | acc]
    end)
    
    # belongs_to associations  
    field_lines = Enum.reduce(belongs_to, field_lines, fn {schema, field, foreign_key}, acc ->
      annotation = "@:belongs_to(\"#{field}\", \"#{schema}\", \"#{foreign_key || (field <> "_id")}\")"
      ["  #{annotation}\n  public var #{field}: #{schema};" | acc]
    end)
    
    # has_many associations
    field_lines = Enum.reduce(has_many, field_lines, fn {schema, field, foreign_key}, acc ->
      annotation = "@:has_many(\"#{field}\", \"#{schema}\", \"#{foreign_key || (String.downcase(schema) <> "_id")}\")"
      ["  #{annotation}\n  public var #{field}: Array<#{schema}>;" | acc]
    end)
    
    # has_one associations  
    field_lines = Enum.reduce(has_one, field_lines, fn {schema, field, foreign_key}, acc ->
      annotation = "@:has_one(\"#{field}\", \"#{schema}\", \"#{foreign_key || (String.downcase(schema) <> "_id")}\")"
      ["  #{annotation}\n  public var #{field}: #{schema};" | acc]
    end)
    
    # timestamps  
    field_lines = if include_timestamps do
      ["  @:timestamps\n  public var timestamps: Bool;" | field_lines]
    else
      field_lines
    end
    
    # Join and format
    field_lines
    |> Enum.reverse()
    |> Enum.join("\n\n")
  end

  # Generate @:field annotation with options
  defp generate_field_annotation(type, opts) do
    annotation_parts = ["type: \"#{type}\""]
    
    annotation_parts = if Enum.member?(opts, :unique) do
      ["unique: true" | annotation_parts]
    else
      annotation_parts
    end
    
    annotation_parts = if Enum.member?(opts, :null) do
      ["null: true" | annotation_parts] 
    else
      ["null: false" | annotation_parts]
    end
    
    "@:field({#{Enum.join(annotation_parts, ", ")}})"
  end

  # Generate Elixir schema content (immediate compilation)
  defp generate_elixir_schema_content(schema_name, table_name, fields, opts, belongs_to, has_many, has_one) do
    primary_key = Keyword.get(opts, :primary_key, "id")
    include_timestamps = Keyword.get(opts, :timestamps, true)
    generate_changeset = Keyword.get(opts, :changeset, true)
    
    # Get the application module name from config or use a default
    app_module = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    module_name = "#{app_module}.#{schema_name}"
    
    # Generate field definitions
    field_definitions = generate_elixir_fields(fields, primary_key, include_timestamps, belongs_to, has_many, has_one)
    
    # Generate changeset function if needed
    changeset_function = if generate_changeset do
      """
        @doc \"\"\"
        Changeset function for #{schema_name} schema
        \"\"\"
        def changeset(%#{schema_name}{} = #{String.downcase(schema_name)}, attrs \\\\ %{}) do
          #{String.downcase(schema_name)}
          |> cast(attrs, changeable_fields())
          |> validate_required(required_fields())#{generate_validation_calls(fields)}
        end

        defp changeable_fields do
          [#{generate_changeable_fields(fields)}]
        end

        defp required_fields do
          [#{generate_required_fields(fields)}]
        end
      """
    else
      ""
    end

    """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      #{schema_name} schema module generated from Haxe @:schema class
      
      Table: #{table_name}
      Generated with mix haxe.gen.schema
      \"\"\"
      
      use Ecto.Schema
      import Ecto.Changeset

      @primary_key {:#{primary_key}, :id, autogenerate: true}
      @derive {Phoenix.Param, key: :#{primary_key}}

      schema "#{table_name}" do
    #{field_definitions}#{if include_timestamps, do: "    timestamps()", else: ""}
      end

    #{changeset_function}
    end
    """
  end

  # Generate Elixir field definitions
  defp generate_elixir_fields(fields, _primary_key, _include_timestamps, belongs_to, has_many, has_one) do
    field_lines = []
    
    # Regular fields (excluding primary key which is handled by schema/2 macro)
    field_lines = Enum.reduce(fields, field_lines, fn {name, type, opts}, acc ->
      field_options = generate_elixir_field_options(opts)
      option_str = if field_options != "", do: ", #{field_options}", else: ""
      ["    field :#{name}, :#{type}#{option_str}" | acc]
    end)
    
    # belongs_to associations
    field_lines = Enum.reduce(belongs_to, field_lines, fn {schema, field, foreign_key}, acc ->
      fk_option = if foreign_key && foreign_key != "#{field}_id", do: ", foreign_key: :#{foreign_key}", else: ""
      ["    belongs_to :#{field}, #{schema}#{fk_option}" | acc]
    end)
    
    # has_many associations
    field_lines = Enum.reduce(has_many, field_lines, fn {schema, field, foreign_key}, acc ->
      fk_option = if foreign_key, do: ", foreign_key: :#{foreign_key}", else: ""
      ["    has_many :#{field}, #{schema}#{fk_option}" | acc]
    end)
    
    # has_one associations
    field_lines = Enum.reduce(has_one, field_lines, fn {schema, field, foreign_key}, acc ->
      fk_option = if foreign_key, do: ", foreign_key: :#{foreign_key}", else: ""
      ["    has_one :#{field}, #{schema}#{fk_option}" | acc]
    end)
    
    case field_lines do
      [] -> ""
      lines -> 
        lines
        |> Enum.reverse()
        |> Enum.join("\n")
        |> then(&(&1 <> "\n"))
    end
  end

  # Generate field options for Elixir schema
  defp generate_elixir_field_options(opts) do
    options = []
    
    options = if Enum.member?(opts, :null) do
      options
    else
      ["null: false" | options] 
    end
    
    options = if Enum.member?(opts, :unique) do
      ["unique: true" | options]
    else
      options
    end
    
    Enum.join(options, ", ")
  end

  # Generate validation calls for changeset
  defp generate_validation_calls(fields) do
    validations = Enum.reduce(fields, [], fn {name, type, opts}, acc ->
      case type do
        "string" ->
          if Enum.member?(opts, :unique) do
            ["\n          |> unique_constraint(:#{name})" | acc]
          else
            acc
          end
        _ -> acc
      end
    end)
    
    Enum.join(validations, "")
  end

  # Generate changeable fields list
  defp generate_changeable_fields(fields) do
    fields
    |> Enum.map(fn {name, _type, _opts} -> ":#{name}" end)
    |> Enum.join(", ")
  end

  # Generate required fields list  
  defp generate_required_fields(fields) do
    fields
    |> Enum.reject(fn {_name, _type, opts} -> Enum.member?(opts, :null) end)
    |> Enum.map(fn {name, _type, _opts} -> ":#{name}" end)
    |> Enum.join(", ")
  end

  # Infer table name from schema name
  defp infer_table_name(schema_name) do
    schema_name
    |> Macro.underscore()
    |> pluralize()
  end

  # Simple pluralization without external dependencies
  defp pluralize(word) when is_binary(word) do
    cond do
      String.ends_with?(word, ["s", "sh", "ch", "x", "z"]) -> word <> "es"
      String.ends_with?(word, "y") and not String.ends_with?(word, ["ay", "ey", "iy", "oy", "uy"]) ->
        String.slice(word, 0..-2//-1) <> "ies"
      String.ends_with?(word, "f") -> String.slice(word, 0..-2//-1) <> "ves"
      String.ends_with?(word, "fe") -> String.slice(word, 0..-3//-1) <> "ves"
      true -> word <> "s"
    end
  end

  # Parse field specifications from command line
  defp parse_fields(""), do: [{"name", "string", []}, {"description", "text", []}]
  defp parse_fields(fields_string) do
    fields_string
    |> String.split(",")
    |> Enum.map(fn field_spec ->
      case String.split(field_spec, ":") do
        [name, type, "unique"] -> {String.trim(name), String.trim(type), [:unique]}
        [name, type, "null"] -> {String.trim(name), String.trim(type), [:null]}
        [name, type] -> {String.trim(name), String.trim(type), []}
        [name] -> {String.trim(name), "string", []}
      end
    end)
  end

  # Parse association specifications
  defp parse_associations([]), do: []
  defp parse_associations(assoc_list) do
    Enum.map(assoc_list, fn assoc_spec ->
      case String.split(assoc_spec, ":") do
        [schema, field, foreign_key] -> {String.trim(schema), String.trim(field), String.trim(foreign_key)}
        [schema, field] -> {String.trim(schema), String.trim(field), nil}
      end
    end)
  end

  # Map Elixir types to Haxe types
  defp elixir_type_to_haxe("string"), do: "String"
  defp elixir_type_to_haxe("text"), do: "String"
  defp elixir_type_to_haxe("integer"), do: "Int" 
  defp elixir_type_to_haxe("boolean"), do: "Bool"
  defp elixir_type_to_haxe("float"), do: "Float"
  defp elixir_type_to_haxe("datetime"), do: "Date"
  defp elixir_type_to_haxe("naive_datetime"), do: "Date"
  defp elixir_type_to_haxe("decimal"), do: "Float"
  defp elixir_type_to_haxe(_), do: "Dynamic"
end