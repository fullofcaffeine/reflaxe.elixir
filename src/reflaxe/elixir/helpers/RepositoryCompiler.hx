package reflaxe.elixir.helpers;

#if (macro || reflaxe_runtime)

import haxe.macro.Type;
import haxe.macro.Expr;
import reflaxe.elixir.schema.SchemaIntrospection;

using StringTools;

/**
 * Repository pattern compiler for Ecto operations
 * 
 * Provides compile-time type-safe repository operations:
 * - Repo.all(query) - List all records with optional query
 * - Repo.get(schema, id) - Get single record by ID (raises if not found)
 * - Repo.get!(schema, id) - Get single record by ID (returns nil if not found)
 * - Repo.insert(changeset) - Insert new record
 * - Repo.update(changeset) - Update existing record
 * - Repo.delete(struct) - Delete record
 * - Repo.preload(struct, associations) - Preload associations
 * 
 * All operations compile to proper {:ok, result} | {:error, changeset} tuple handling
 */
class RepositoryCompiler {
    
    /**
     * Compile repository method call with type safety
     */
    public static function compileRepoCall(method: String, args: Array<String>, ?schemaName: String): String {
        return switch (method) {
            case "all":
                compileRepoAll(args, schemaName);
            case "get":
                compileRepoGet(args, schemaName, false);
            case "get!":
                compileRepoGet(args, schemaName, true);
            case "insert":
                compileRepoInsert(args, schemaName);
            case "update":
                compileRepoUpdate(args, schemaName);
            case "delete":
                compileRepoDelete(args, schemaName);
            case "preload":
                compileRepoPreload(args, schemaName);
            case "one":
                compileRepoOne(args, schemaName);
            case "aggregate":
                compileRepoAggregate(args, schemaName);
            default:
                compileGenericRepoCall(method, args);
        };
    }
    
    /**
     * Compile Repo.all() - List all records
     */
    static function compileRepoAll(args: Array<String>, schemaName: String): String {
        if (args.length == 0) {
            return 'Repo.all(${schemaName})';
        } else if (args.length == 1) {
            // Query provided
            return 'Repo.all(${args[0]})';
        } else {
            // Multiple arguments - likely query with options
            return 'Repo.all(${args.join(", ")})';
        }
    }
    
    /**
     * Compile Repo.get() and Repo.get!() - Get single record by ID
     */
    static function compileRepoGet(args: Array<String>, schemaName: String, raiseOnNotFound: Bool): String {
        var methodName = raiseOnNotFound ? "get!" : "get";
        
        if (args.length >= 2) {
            return 'Repo.${methodName}(${args.join(", ")})';
        } else if (args.length == 1 && schemaName != null) {
            return 'Repo.${methodName}(${schemaName}, ${args[0]})';
        } else {
            // Not enough arguments
            return 'Repo.${methodName}(${args.join(", ")})';
        }
    }
    
    /**
     * Compile Repo.insert() - Insert new record with changeset
     */
    static function compileRepoInsert(args: Array<String>, schemaName: String): String {
        if (args.length >= 1) {
            return 'Repo.insert(${args.join(", ")})';
        } else {
            return 'Repo.insert(%${schemaName}{})';
        }
    }
    
    /**
     * Compile Repo.update() - Update record with changeset
     */
    static function compileRepoUpdate(args: Array<String>, schemaName: String): String {
        if (args.length >= 1) {
            return 'Repo.update(${args.join(", ")})';
        } else {
            return 'Repo.update(changeset)';
        }
    }
    
    /**
     * Compile Repo.delete() - Delete record
     */
    static function compileRepoDelete(args: Array<String>, schemaName: String): String {
        if (args.length >= 1) {
            return 'Repo.delete(${args.join(", ")})';
        } else {
            return 'Repo.delete(struct)';
        }
    }
    
    /**
     * Compile Repo.preload() - Preload associations
     */
    static function compileRepoPreload(args: Array<String>, schemaName: String): String {
        if (args.length >= 2) {
            return 'Repo.preload(${args.join(", ")})';
        } else if (args.length == 1) {
            return 'Repo.preload(${args[0]}, [])';
        } else {
            return 'Repo.preload(struct, [])';
        }
    }
    
    /**
     * Compile Repo.one() - Get single record from query
     */
    static function compileRepoOne(args: Array<String>, schemaName: String): String {
        if (args.length >= 1) {
            return 'Repo.one(${args.join(", ")})';
        } else {
            return 'Repo.one(query)';
        }
    }
    
    /**
     * Compile Repo.aggregate() - Aggregate functions (count, sum, avg, etc.)
     */
    static function compileRepoAggregate(args: Array<String>, schemaName: String): String {
        if (args.length >= 2) {
            return 'Repo.aggregate(${args.join(", ")})';
        } else {
            return 'Repo.aggregate(query, :count)';
        }
    }
    
    /**
     * Compile generic repository call
     */
    static function compileGenericRepoCall(method: String, args: Array<String>): String {
        return 'Repo.${method}(${args.join(", ")})';
    }
    
    /**
     * Generate type-safe repository context with CRUD operations
     */
    public static function generateRepositoryContext(schemaName: String): String {
        var schema = SchemaIntrospection.getSchemaInfo(schemaName);
        if (schema == null) {
            return generateGenericRepository(schemaName);
        }
        
        var moduleName = '${schemaName}s'; // Users, Posts, etc.
        var tableName = schema.tableName;
        var primaryKey = schema.primaryKey;
        
        return 'defmodule ${moduleName} do
  @moduledoc """
  Repository functions for ${schemaName} schema.
  Generated from Haxe source with compile-time type validation.
  """
  
  import Ecto.Query, warn: false
  alias MyApp.Repo
  alias MyApp.${schemaName}
  
  @doc """
  Returns the list of ${tableName}.
  """
  def list_${tableName}() do
    Repo.all(${schemaName})
  end
  
  @doc """
  Gets a single ${schemaName.toLowerCase()}.
  Raises `Ecto.NoResultsError` if the ${schemaName} does not exist.
  """
  def get_${schemaName.toLowerCase()}!(id) do
    Repo.get!(${schemaName}, id)
  end
  
  @doc """
  Gets a single ${schemaName.toLowerCase()}.
  Returns `nil` if the ${schemaName} does not exist.
  """
  def get_${schemaName.toLowerCase()}(id) do
    Repo.get(${schemaName}, id)
  end
  
  @doc """
  Creates a ${schemaName.toLowerCase()}.
  """
  def create_${schemaName.toLowerCase()}(attrs \\\\ %{}) do
    %${schemaName}{}
    |> ${schemaName}.changeset(attrs)
    |> Repo.insert()
  end
  
  @doc """
  Updates a ${schemaName.toLowerCase()}.
  """
  def update_${schemaName.toLowerCase()}(%${schemaName}{} = ${schemaName.toLowerCase()}, attrs) do
    ${schemaName.toLowerCase()}
    |> ${schemaName}.changeset(attrs)
    |> Repo.update()
  end
  
  @doc """
  Deletes a ${schemaName}.
  """
  def delete_${schemaName.toLowerCase()}(%${schemaName}{} = ${schemaName.toLowerCase()}) do
    Repo.delete(${schemaName.toLowerCase()})
  end
  
  @doc """
  Returns an `%Ecto.Changeset{}` for tracking ${schemaName.toLowerCase()} changes.
  """
  def change_${schemaName.toLowerCase()}(%${schemaName}{} = ${schemaName.toLowerCase()}, attrs \\\\ %{}) do
    ${schemaName}.changeset(${schemaName.toLowerCase()}, attrs)
  end';
    }
    
    /**
     * Generate generic repository for schemas without introspection
     */
    static function generateGenericRepository(schemaName: String): String {
        var tableName = schemaName.toLowerCase() + "s";
        
        return 'defmodule ${schemaName}Repository do
  @moduledoc """
  Repository functions for ${schemaName}.
  Generic implementation without schema introspection.
  """
  
  import Ecto.Query
  alias MyApp.Repo
  
  def all() do
    Repo.all(${schemaName})
  end
  
  def get(id) do
    Repo.get(${schemaName}, id)
  end
  
  def get!(id) do
    Repo.get!(${schemaName}, id)
  end
  
  def insert(attrs) do
    %${schemaName}{}
    |> ${schemaName}.changeset(attrs)
    |> Repo.insert()
  end
  
  def update(struct, attrs) do
    struct
    |> ${schemaName}.changeset(attrs)
    |> Repo.update()
  end
  
  def delete(struct) do
    Repo.delete(struct)
  end
end';
    }
    
    /**
     * Validate repository operation against schema
     */
    public static function validateRepositoryOperation(operation: String, schemaName: String, args: Array<String>): Array<String> {
        var errors = [];
        
        if (!SchemaIntrospection.schemaExists(schemaName)) {
            errors.push('Schema "${schemaName}" not found in schema registry');
        }
        
        switch (operation) {
            case "get", "get!":
                if (args.length < 1) {
                    errors.push('${operation} requires at least 1 argument (id)');
                }
                
            case "insert", "update":
                if (args.length < 1) {
                    errors.push('${operation} requires at least 1 argument (changeset)');
                }
                
            case "delete":
                if (args.length < 1) {
                    errors.push('delete requires at least 1 argument (struct)');
                }
                
            case "preload":
                if (args.length < 2) {
                    errors.push('preload requires at least 2 arguments (struct, associations)');
                }
        }
        
        return errors;
    }
    
    /**
     * Generate error tuple handling for repository operations
     */
    public static function generateErrorHandling(operation: String, successVar: String = "result", errorVar: String = "changeset"): String {
        return switch (operation) {
            case "insert", "update":
                'case ${operation}_result do
  {:ok, ${successVar}} ->
    {:ok, ${successVar}}
  {:error, ${errorVar}} ->
    {:error, ${errorVar}}
end';
            
            case "delete":
                'case ${operation}_result do
  {:ok, ${successVar}} ->
    {:ok, ${successVar}}
  {:error, ${errorVar}} ->
    {:error, ${errorVar}}
end';
            
            case "get", "get!", "all", "one":
                // These operations return the result directly or raise
                '${successVar}';
            
            default:
                'result';
        };
    }
    
    /**
     * Check if operation returns error tuples
     */
    public static function returnsErrorTuple(operation: String): Bool {
        return ["insert", "update", "delete"].contains(operation);
    }
    
    /**
     * Get operation return type for type checking
     */
    public static function getOperationReturnType(operation: String, schemaName: String): String {
        return switch (operation) {
            case "all":
                '[${schemaName}]';
            case "get":
                '${schemaName} | nil';
            case "get!":
                '${schemaName}';
            case "insert", "update":
                '{:ok, ${schemaName}} | {:error, Ecto.Changeset.t()}';
            case "delete":
                '{:ok, ${schemaName}} | {:error, Ecto.Changeset.t()}';
            case "one":
                '${schemaName} | nil';
            case "preload":
                '${schemaName}';
            case "aggregate":
                'term()';
            default:
                'term()';
        };
    }
    
    /**
     * Generate repository module with all CRUD operations
     */
    public static function generateFullRepository(className: String, schemaName: String): String {
        var repositoryFunctions = generateRepositoryContext(schemaName);
        
        return 'defmodule ${className} do
  @moduledoc """
  Generated repository module for ${schemaName} operations.
  Provides type-safe CRUD operations with proper error handling.
  """
  
  ${repositoryFunctions}
  
  @doc """
  List ${schemaName.toLowerCase()}s with optional filters
  """
  def list_with_filters(filters \\\\ %{}) do
    query = from(s in ${schemaName})
    
    query =
      Enum.reduce(filters, query, fn {key, value}, acc ->
        case key do
          :active -> where(acc, [s], s.active == ^value)
          :name -> where(acc, [s], ilike(s.name, ^"%#{value}%"))
          :email -> where(acc, [s], s.email == ^value)
          _ -> acc
        end
      end)
    
    Repo.all(query)
  end
  
  @doc """
  Count total records
  """
  def count() do
    Repo.aggregate(${schemaName}, :count)
  end
  
  @doc """
  Check if record exists
  """
  def exists?(id) do
    case get_${schemaName.toLowerCase()}(id) do
      nil -> false
      _ -> true
    end
  end
end';
    }
}

#end