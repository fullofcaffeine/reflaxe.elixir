defmodule Mix.Tasks.Haxe.Gen.Context do
  @moduledoc """
  Mix task for generating Phoenix context modules with CRUD operations.
  
  Generates complete context modules that integrate Ecto schemas, changesets, and repository
  operations following Phoenix conventions. Creates both Haxe source files and corresponding
  Elixir context modules with comprehensive business logic.

  ## Examples

      mix haxe.gen.context Accounts User users
      mix haxe.gen.context Blog Post posts --schema-attrs "title:string,content:text,published:boolean"
      mix haxe.gen.context Shop Product products --context-attrs "category:string,price:decimal"
      mix haxe.gen.context Social Comment comments --belongs-to "Post:post,User:author"

  ## Arguments

    * `context` - Context module name (e.g., Accounts, Blog, Shop)
    * `schema` - Schema module name (e.g., User, Post, Product)  
    * `table` - Table name (e.g., users, posts, products)

  ## Options

    * `--schema-attrs` - Schema field attributes (e.g., "name:string,email:string,age:integer")
    * `--context-attrs` - Additional context-specific attributes
    * `--belongs-to` - belongs_to associations (format: "Schema:field")
    * `--has-many` - has_many associations (format: "Schema:field")
    * `--has-one` - has_one associations (format: "Schema:field")
    * `--no-schema` - Skip schema generation (use existing schema)
    * `--changeset` - Include changeset generation (default: true)
    * `--repo` - Custom repository module (default: Repo)
    * `--haxe-dir` - Directory for Haxe context files (default: "src_haxe/contexts")
    * `--elixir-dir` - Directory for generated Elixir contexts (default: "lib")

  """
  use Mix.Task

  @shortdoc "Generates a new Phoenix context with CRUD operations"

  @doc """
  Entry point for the Mix task
  """
  def run(args) do
    {opts, [context_name, schema_name, table_name | _], _} = OptionParser.parse(args, 
      switches: [
        schema_attrs: :string,
        context_attrs: :string,
        belongs_to: [:string, :keep],
        has_many: [:string, :keep], 
        has_one: [:string, :keep],
        no_schema: :boolean,
        changeset: :boolean,
        repo: :string,
        haxe_dir: :string,
        elixir_dir: :string
      ]
    )

    if context_name == nil or schema_name == nil or table_name == nil do
      Mix.shell().error("Context name, schema name, and table name are required.")
      Mix.shell().error("Usage: mix haxe.gen.context ContextName SchemaName table_name")
      System.halt(1)
    end

    generate_context(context_name, schema_name, table_name, opts)
  end

  # Generate both Haxe context source and compiled Elixir context
  defp generate_context(context_name, schema_name, table_name, opts) do
    # Configuration
    haxe_dir = Keyword.get(opts, :haxe_dir, "src_haxe/contexts")
    elixir_dir = Keyword.get(opts, :elixir_dir, "lib")
    schema_attrs = parse_attrs(Keyword.get(opts, :schema_attrs, ""))
    context_attrs = parse_attrs(Keyword.get(opts, :context_attrs, ""))
    generate_schema = not Keyword.get(opts, :no_schema, false)
    _include_changeset = Keyword.get(opts, :changeset, true)
    _repo_module = Keyword.get(opts, :repo, "Repo")
    
    # Associations
    belongs_to_assocs = parse_associations(Keyword.get_values(opts, :belongs_to))
    has_many_assocs = parse_associations(Keyword.get_values(opts, :has_many))
    has_one_assocs = parse_associations(Keyword.get_values(opts, :has_one))
    
    # Create directories
    File.mkdir_p!(haxe_dir)
    File.mkdir_p!(elixir_dir)
    
    # Generate Haxe context file
    haxe_content = generate_haxe_context_content(context_name, schema_name, table_name, 
                                               schema_attrs, context_attrs, opts, 
                                               belongs_to_assocs, has_many_assocs, has_one_assocs)
    haxe_filename = "#{haxe_dir}/#{context_name}.hx"
    
    File.write!(haxe_filename, haxe_content)
    Mix.shell().info("Generated Haxe context: #{haxe_filename}")
    
    # Generate Elixir context file
    elixir_content = generate_elixir_context_content(context_name, schema_name, table_name,
                                                   schema_attrs, context_attrs, opts,
                                                   belongs_to_assocs, has_many_assocs, has_one_assocs)
    elixir_filename = "#{elixir_dir}/#{Macro.underscore(context_name)}.ex"
    
    File.write!(elixir_filename, elixir_content)
    Mix.shell().info("Generated Elixir context: #{elixir_filename}")
    
    # Display next steps
    Mix.shell().info("")
    Mix.shell().info("Context #{context_name} with #{schema_name} schema created successfully!")
    Mix.shell().info("")
    Mix.shell().info("Next steps:")
    Mix.shell().info("  1. Edit #{haxe_filename} to customize your business logic")
    
    if generate_schema do
      Mix.shell().info("  2. Run: mix ecto.gen.migration create_#{table_name} to create migration")
      Mix.shell().info("  3. Run: mix ecto.migrate to apply the migration")
      Mix.shell().info("  4. Run: mix compile to compile Haxe to Elixir")
    else
      Mix.shell().info("  2. Ensure the #{schema_name} schema exists and is compiled")
      Mix.shell().info("  3. Run: mix compile to compile Haxe to Elixir")
    end
    
    Mix.shell().info("  5. Use #{context_name}.list_#{pluralize(String.downcase(schema_name))}() and other functions in your code")
    
    :ok
  end

  # Generate Haxe context source file content
  defp generate_haxe_context_content(context_name, schema_name, table_name, schema_attrs, _context_attrs, opts, belongs_to, has_many, has_one) do
    generate_schema = not Keyword.get(opts, :no_schema, false)
    include_changeset = Keyword.get(opts, :changeset, true)
    repo_module = Keyword.get(opts, :repo, "Repo")
    
    # Generate schema if requested
    schema_section = if generate_schema do
      generate_haxe_schema_section(schema_name, table_name, schema_attrs, belongs_to, has_many, has_one)
    else
      ""
    end
    
    # Generate changeset if requested
    changeset_section = if include_changeset do
      generate_haxe_changeset_section(schema_name, schema_attrs)
    else
      ""
    end
    
    # Context methods
    singular = String.downcase(schema_name)
    plural = pluralize(singular)
    
    """
    package contexts;

    /**
     * Generated Phoenix context: #{context_name}
     * 
     * Business logic layer for #{schema_name} operations.
     * Provides CRUD operations and business rules following Phoenix conventions.
     * 
     * Generated with: mix haxe.gen.context #{context_name} #{schema_name} #{table_name}
     */

    #{schema_section}#{changeset_section}/**
     * Phoenix Context: #{context_name}
     * 
     * The boundary for #{schema_name} related functionality.
     */
    class #{context_name} {
      
      /**
       * Returns the list of #{plural}.
       */
      public static function list_#{plural}(): Array<#{schema_name}> {
        // Implementation will be generated by Reflaxe.Elixir
        return #{repo_module}.all(#{schema_name});
      }
      
      /**
       * Gets a single #{singular}.
       * 
       * Raises Ecto.NoResultsError if the #{schema_name} does not exist.
       */
      public static function get_#{singular}(id: Int): #{schema_name} {
        return #{repo_module}.get!(#{schema_name}, id);
      }
      
      /**
       * Gets a single #{singular}, returns null if not found.
       */
      public static function get_#{singular}_safe(id: Int): Null<#{schema_name}> {
        return #{repo_module}.get(#{schema_name}, id);
      }
      
      /**
       * Creates a #{singular}.
       */
      public static function create_#{singular}(attrs: Dynamic): {ok: Bool, ?#{singular}: #{schema_name}, ?changeset: Dynamic} {
        #{if include_changeset do
          "var changeset = #{schema_name}Changeset.changeset(new #{schema_name}(), attrs);\n        \n        switch (#{repo_module}.insert(changeset)) {\n          case {ok: true, #{singular}: result}: \n            return {ok: true, #{singular}: result};\n          case {error: true, changeset: error_changeset}:\n            return {ok: false, changeset: error_changeset};\n        }"
        else
          "return #{repo_module}.insert(attrs);"
        end}
      }
      
      /**
       * Updates a #{singular}.
       */
      public static function update_#{singular}(#{singular}: #{schema_name}, attrs: Dynamic): {ok: Bool, ?#{singular}: #{schema_name}, ?changeset: Dynamic} {
        #{if include_changeset do
          "var changeset = #{schema_name}Changeset.changeset(#{singular}, attrs);\n        \n        switch (#{repo_module}.update(changeset)) {\n          case {ok: true, #{singular}: result}: \n            return {ok: true, #{singular}: result};\n          case {error: true, changeset: error_changeset}:\n            return {ok: false, changeset: error_changeset};\n        }"
        else
          "return #{repo_module}.update(#{singular}, attrs);"
        end}
      }
      
      /**
       * Deletes a #{singular}.
       */
      public static function delete_#{singular}(#{singular}: #{schema_name}): {ok: Bool, ?#{singular}: #{schema_name}} {
        return #{repo_module}.delete(#{singular});
      }
      
      /**
       * Returns an %Ecto.Changeset{} for tracking #{singular} changes.
       */
      public static function change_#{singular}(?#{singular}: #{schema_name}): Dynamic {
        #{if include_changeset do
          "return #{schema_name}Changeset.changeset(#{singular} != null ? #{singular} : new #{schema_name}(), {});"
        else
          "// Changeset functionality requires @:changeset annotation\n        return {};"
        end}
      }
      
      #{generate_context_business_methods(context_name, schema_name, belongs_to, has_many, has_one)}
      
      /**
       * Main function for compilation testing
       */
      public static function main(): Void {
        trace("#{context_name} context compiled successfully!");
      }
    }
    """
  end

  # Generate schema section for Haxe context
  defp generate_haxe_schema_section(schema_name, table_name, schema_attrs, belongs_to, has_many, has_one) do
    # Generate field definitions
    field_definitions = generate_haxe_schema_fields(schema_attrs, belongs_to, has_many, has_one)
    
    """
    /**
     * #{schema_name} schema definition
     */
    @:schema(table: "#{table_name}")
    class #{schema_name} {
      @:primary_key
      public var id: Int;
      
    #{field_definitions}
      
      @:timestamps
      public var insertedAt: String;
      public var updatedAt: String;
    }

    """
  end

  # Generate changeset section for Haxe context
  defp generate_haxe_changeset_section(schema_name, schema_attrs) do
    required_fields = schema_attrs
    |> Enum.reject(fn {_name, _type, opts} -> Enum.member?(opts, :nullable) end)
    |> Enum.map(fn {name, _type, _opts} -> "\"#{name}\"" end)
    |> Enum.join(", ")
    
    """
    /**
     * #{schema_name} changeset for validation
     */
    @:changeset
    class #{schema_name}Changeset {
      @:validate_required([#{required_fields}])
      public static function changeset(#{String.downcase(schema_name)}: #{schema_name}, attrs: Dynamic): Dynamic {
        // Changeset pipeline will be generated by Reflaxe.Elixir
        return null;
      }
    }

    """
  end

  # Generate schema fields for Haxe
  defp generate_haxe_schema_fields(schema_attrs, belongs_to, has_many, has_one) do
    field_lines = []
    
    # Regular fields
    field_lines = Enum.reduce(schema_attrs, field_lines, fn {name, type, opts}, acc ->
      field_annotation = generate_haxe_field_annotation(type, opts)
      haxe_type = elixir_type_to_haxe(type)
      ["  #{field_annotation}\n  public var #{name}: #{haxe_type};" | acc]
    end)
    
    # belongs_to associations  
    field_lines = Enum.reduce(belongs_to, field_lines, fn {schema, field}, acc ->
      annotation = "@:belongs_to(\"#{field}\", \"#{schema}\")"
      ["  #{annotation}\n  public var #{field}: #{schema};" | acc]
    end)
    
    # has_many associations
    field_lines = Enum.reduce(has_many, field_lines, fn {schema, field}, acc ->
      annotation = "@:has_many(\"#{field}\", \"#{schema}\")"
      ["  #{annotation}\n  public var #{field}: Array<#{schema}>;" | acc]
    end)
    
    # has_one associations
    field_lines = Enum.reduce(has_one, field_lines, fn {schema, field}, acc ->
      annotation = "@:has_one(\"#{field}\", \"#{schema}\")"
      ["  #{annotation}\n  public var #{field}: #{schema};" | acc]
    end)
    
    case field_lines do
      [] -> ""
      lines ->
        lines
        |> Enum.reverse()
        |> Enum.join("\n\n")
    end
  end

  # Generate business logic methods specific to the context
  defp generate_context_business_methods(_context_name, schema_name, belongs_to, has_many, has_one) do
    singular = String.downcase(schema_name)
    plural = pluralize(singular)
    
    # Generate association-specific methods
    preload_methods = generate_preload_methods(schema_name, has_many, has_one)
    filter_methods = generate_filter_methods(schema_name, belongs_to)
    
    """
      /**
       * Get #{plural} with pagination
       */
      public static function list_#{plural}_paginated(page: Int, per_page: Int): {entries: Array<#{schema_name}>, total: Int} {
        // Pagination implementation will be generated
        return {entries: [], total: 0};
      }
      
      /**
       * Search #{plural} by various criteria
       */
      public static function search_#{plural}(query: String): Array<#{schema_name}> {
        // Search implementation will be generated
        return [];
      }
      
    #{preload_methods}#{filter_methods}
      /**
       * Get #{singular} statistics
       */
      public static function get_#{singular}_stats(): #{String.capitalize(singular)}Stats {
        // Statistics query implementation will be generated
        return {total: 0, active: 0};
      }
    """
  end

  # Generate preload methods for associations
  defp generate_preload_methods(schema_name, has_many, has_one) do
    singular = String.downcase(schema_name)
    
    associations = has_many ++ has_one
    
    if length(associations) > 0 do
      assoc_names = associations |> Enum.map(fn {_schema, field} -> field end)
      preload_list = assoc_names |> Enum.map(&"\"#{&1}\"") |> Enum.join(", ")
      
      """
      /**
       * Get #{singular} with preloaded associations
       */
      public static function get_#{singular}_with_assocs(id: Int): #{schema_name} {
        return Repo.get(#{schema_name}, id) |> Repo.preload([#{preload_list}]);
      }
      
      """
    else
      ""
    end
  end

  # Generate filter methods for belongs_to associations
  defp generate_filter_methods(schema_name, belongs_to) do
    singular = String.downcase(schema_name)
    plural = pluralize(singular)
    
    Enum.map_join(belongs_to, "", fn {parent_schema, _field} ->
      parent_singular = String.downcase(parent_schema)
      
      """
      /**
       * List #{plural} by #{parent_singular}
       */
      public static function list_#{plural}_by_#{parent_singular}(#{parent_singular}_id: Int): Array<#{schema_name}> {
        // Filter by #{parent_singular} implementation will be generated
        return [];
      }
      
      """
    end)
  end

  # Generate @:field annotation with options
  defp generate_haxe_field_annotation(type, opts) do
    annotation_parts = ["type: \"#{type}\""]
    
    annotation_parts = if Enum.member?(opts, :unique) do
      ["unique: true" | annotation_parts]
    else
      annotation_parts
    end
    
    annotation_parts = if Enum.member?(opts, :nullable) do
      ["nullable: true" | annotation_parts] 
    else
      ["nullable: false" | annotation_parts]
    end
    
    "@:field({#{Enum.join(annotation_parts, ", ")}})"
  end

  # Generate Elixir context content
  defp generate_elixir_context_content(context_name, schema_name, _table_name, _schema_attrs, _context_attrs, opts, belongs_to, has_many, has_one) do
    repo_module = Keyword.get(opts, :repo, "Repo")
    
    # Get the application module name
    app_module = Mix.Project.config()[:app] |> to_string() |> Macro.camelize()
    module_name = "#{app_module}.#{context_name}"
    schema_module = "#{app_module}.#{schema_name}"
    
    singular = String.downcase(schema_name)
    plural = pluralize(singular)
    
    """
    defmodule #{module_name} do
      @moduledoc \"\"\"
      The #{context_name} context.
      
      Generated from Haxe context definition.
      Provides business logic for #{schema_name} operations.
      \"\"\"

      import Ecto.Query, warn: false
      alias #{app_module}.#{repo_module}
      alias #{schema_module}

      @doc \"\"\"
      Returns the list of #{plural}.

      ## Examples

          iex> list_#{plural}()
          [%#{schema_name}{}, ...]

      \"\"\"
      def list_#{plural} do
        #{repo_module}.all(#{schema_name})
      end

      @doc \"\"\"
      Gets a single #{singular}.

      Raises `Ecto.NoResultsError` if the #{schema_name} does not exist.

      ## Examples

          iex> get_#{singular}!(123)
          %#{schema_name}{}

          iex> get_#{singular}!(456)
          ** (Ecto.NoResultsError)

      \"\"\"
      def get_#{singular}!(id), do: #{repo_module}.get!(#{schema_name}, id)

      @doc \"\"\"
      Gets a single #{singular}, returns nil if not found.

      ## Examples

          iex> get_#{singular}(123)
          %#{schema_name}{}

          iex> get_#{singular}(456)
          nil

      \"\"\"
      def get_#{singular}(id), do: #{repo_module}.get(#{schema_name}, id)

      @doc \"\"\"
      Creates a #{singular}.

      ## Examples

          iex> create_#{singular}(%{field: value})
          {:ok, %#{schema_name}{}}

          iex> create_#{singular}(%{field: bad_value})
          {:error, %Ecto.Changeset{}}

      \"\"\"
      def create_#{singular}(attrs \\\\ %{}) do
        %#{schema_name}{}
        |> #{schema_name}.changeset(attrs)
        |> #{repo_module}.insert()
      end

      @doc \"\"\"
      Updates a #{singular}.

      ## Examples

          iex> update_#{singular}(#{singular}, %{field: new_value})
          {:ok, %#{schema_name}{}}

          iex> update_#{singular}(#{singular}, %{field: bad_value})
          {:error, %Ecto.Changeset{}}

      \"\"\"
      def update_#{singular}(%#{schema_name}{} = #{singular}, attrs) do
        #{singular}
        |> #{schema_name}.changeset(attrs)
        |> #{repo_module}.update()
      end

      @doc \"\"\"
      Deletes a #{singular}.

      ## Examples

          iex> delete_#{singular}(#{singular})
          {:ok, %#{schema_name}{}}

          iex> delete_#{singular}(#{singular})
          {:error, %Ecto.Changeset{}}

      \"\"\"
      def delete_#{singular}(%#{schema_name}{} = #{singular}) do
        #{repo_module}.delete(#{singular})
      end

      @doc \"\"\"
      Returns an `%Ecto.Changeset{}` for tracking #{singular} changes.

      ## Examples

          iex> change_#{singular}(#{singular})
          %Ecto.Changeset{data: %#{schema_name}{}}

      \"\"\"
      def change_#{singular}(%#{schema_name}{} = #{singular}, attrs \\\\ %{}) do
        #{schema_name}.changeset(#{singular}, attrs)
      end

      #{generate_elixir_business_methods(schema_name, belongs_to, has_many, has_one, app_module, repo_module)}
    end
    """
  end

  # Generate business logic methods for Elixir context
  defp generate_elixir_business_methods(schema_name, belongs_to, has_many, has_one, _app_module, repo_module) do
    singular = String.downcase(schema_name)
    plural = pluralize(singular)
    
    # Generate association methods
    preload_methods = generate_elixir_preload_methods(schema_name, has_many, has_one, repo_module)
    filter_methods = generate_elixir_filter_methods(schema_name, belongs_to, repo_module)
    
    """
      @doc \"\"\"
      Returns a paginated list of #{plural}.
      \"\"\"
      def list_#{plural}_paginated(page \\\\ 1, per_page \\\\ 20) do
        #{schema_name}
        |> limit(^per_page)
        |> offset(^((page - 1) * per_page))
        |> #{repo_module}.all()
      end

      @doc \"\"\"
      Search #{plural} by text query.
      \"\"\"
      def search_#{plural}(query) when is_binary(query) do
        # This would typically search across multiple text fields
        # Implementation depends on your specific search requirements
        #{repo_module}.all(#{schema_name})
      end

    #{preload_methods}#{filter_methods}
      @doc \"\"\"
      Get #{singular} statistics.
      \"\"\"
      def get_#{singular}_stats do
        total = #{repo_module}.aggregate(#{schema_name}, :count, :id)
        %{
          total: total,
          active: total  # Placeholder - implement based on your schema
        }
      end
    """
  end

  # Generate Elixir preload methods
  defp generate_elixir_preload_methods(schema_name, has_many, has_one, repo_module) do
    singular = String.downcase(schema_name)
    
    associations = has_many ++ has_one
    
    if length(associations) > 0 do
      assoc_names = associations |> Enum.map(fn {_schema, field} -> ":#{field}" end)
      preload_list = Enum.join(assoc_names, ", ")
      
      """
      @doc \"\"\"
      Gets #{singular} with preloaded associations.
      \"\"\"
      def get_#{singular}_with_assocs(id) do
        #{schema_name}
        |> #{repo_module}.get(id)
        |> #{repo_module}.preload([#{preload_list}])
      end

      """
    else
      ""
    end
  end

  # Generate Elixir filter methods
  defp generate_elixir_filter_methods(schema_name, belongs_to, repo_module) do
    singular = String.downcase(schema_name)
    plural = pluralize(singular)
    
    Enum.map_join(belongs_to, "", fn {parent_schema, field} ->
      parent_singular = String.downcase(parent_schema)
      foreign_key = "#{field}_id"
      
      """
      @doc \"\"\"
      List #{plural} by #{parent_singular}.
      \"\"\"
      def list_#{plural}_by_#{parent_singular}(#{parent_singular}_id) do
        from(#{singular} in #{schema_name}, where: #{singular}.#{foreign_key} == ^#{parent_singular}_id)
        |> #{repo_module}.all()
      end

      """
    end)
  end

  # Parse attribute specifications
  defp parse_attrs(""), do: [{"name", "string", []}, {"description", "text", [:nullable]}]
  defp parse_attrs(attrs_string) do
    attrs_string
    |> String.split(",")
    |> Enum.map(fn attr_spec ->
      case String.split(attr_spec, ":") do
        [name, type, "unique"] -> {String.trim(name), String.trim(type), [:unique]}
        [name, type, "nullable"] -> {String.trim(name), String.trim(type), [:nullable]}
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
        [schema, field] -> {String.trim(schema), String.trim(field)}
      end
    end)
  end

  # Map Elixir types to Haxe types
  defp elixir_type_to_haxe("string"), do: "String"
  defp elixir_type_to_haxe("text"), do: "String"
  defp elixir_type_to_haxe("integer"), do: "Int" 
  defp elixir_type_to_haxe("boolean"), do: "Bool"
  defp elixir_type_to_haxe("float"), do: "Float"
  defp elixir_type_to_haxe("decimal"), do: "Float"
  defp elixir_type_to_haxe("datetime"), do: "String"  # Simplified
  defp elixir_type_to_haxe("naive_datetime"), do: "String"  # Simplified
  defp elixir_type_to_haxe(_), do: "Dynamic"

  # Simple pluralization
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
end