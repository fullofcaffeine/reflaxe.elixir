package ecto;

#if (elixir || reflaxe_runtime)

import elixir.types.Term;

/**
 * Base class for Ecto schemas following Phoenix patterns exactly
 * 
 * ## Overview
 * 
 * This provides the foundation for database-backed models in Phoenix applications.
 * Classes that extend Schema or use @:schema annotation will be transformed into
 * proper Ecto schema modules with all the standard Phoenix/Ecto features.
 * 
 * ## Key Features
 * 
 * - **Automatic schema generation**: Generates proper Ecto schema blocks
 * - **Type-safe fields**: Full compile-time validation of field types
 * - **Changeset preservation**: Functions marked with @:changeset are preserved through DCE
 * - **Association support**: belongs_to, has_many, has_one relationships
 * - **Timestamp support**: Automatic inserted_at/updated_at with @:timestamps
 * 
 * ## Usage Example
 * 
 * ```haxe
 * @:schema("todos")
 * @:timestamps
 * @:build(reflaxe.elixir.macros.SchemaRegistrar.build())
 * class Todo extends Schema {
 *     @:field public var id: Int;
 *     @:field public var title: String;
 *     @:field public var completed: Bool = false;
 *     @:field public var userId: Int;
 *     
 *     @:belongs_to("user")
 *     public var user: User;
 *     
 *     @:changeset
 *     public static function changeset(todo: Todo, params: Term): Changeset<Todo, Term> {
 *         return new Changeset(todo, params)
 *             .validateRequired(["title", "userId"])
 *             .validateLength("title", {min: 3, max: 200});
 *     }
 * }
 * ```
 * 
 * ## Generated Elixir
 * 
 * ```elixir
 * defmodule Todo do
 *   use Ecto.Schema
 *   import Ecto.Changeset
 *   
 *   schema "todos" do
 *     field :title, :string
 *     field :completed, :boolean, default: false
 *     field :user_id, :integer
 *     belongs_to :user, User
 *     timestamps()
 *   end
 *   
 *   def changeset(todo, params) do
 *     todo
 *     |> cast(params, [:title, :completed, :user_id])
 *     |> validate_required([:title, :user_id])
 *     |> validate_length(:title, min: 3, max: 200)
 *   end
 * end
 * ```
 * 
 * ## Architecture Note
 * 
 * This class works with SchemaRegistrar build macro to solve the DCE problem.
 * The registrar collects metadata and adds @:keep to preserve changeset functions.
 * 
 * @see reflaxe.elixir.macros.SchemaRegistrar For metadata preservation
 * @see ecto.Changeset For data validation
 * @see ecto.TypedQuery For querying schemas
 */
@:autoBuild(reflaxe.elixir.macros.SchemaRegistrar.build())
class Schema {
    /**
     * Schema metadata annotations
     */
    
    /**
     * Mark a field as an Ecto schema field
     * 
     * @example
     * ```haxe
     * @:field public var title: String;
     * ```
     */
    static public var field: Term;
    
    /**
     * Define a belongs_to association
     * 
     * @example
     * ```haxe
     * @:belongs_to("user")
     * public var user: User;
     * ```
     */
    static public var belongs_to: Term;
    
    /**
     * Define a has_many association
     * 
     * @example
     * ```haxe
     * @:has_many("posts")
     * public var posts: Array<Post>;
     * ```
     */
    static public var has_many: Term;
    
    /**
     * Define a has_one association
     * 
     * @example
     * ```haxe
     * @:has_one("profile")
     * public var profile: Profile;
     * ```
     */
    static public var has_one: Term;
    
    /**
     * Mark a function as a changeset generator
     * 
     * ## Purpose
     * 
     * Functions with this annotation are preserved through Dead Code Elimination (DCE)
     * and included in the generated Ecto schema module. This is critical because
     * changeset functions appear "unused" from Haxe's perspective - they're only
     * called from generated Elixir code.
     * 
     * ## How It Works
     * 
     * When you add @:changeset to a function:
     * 1. The compiler detects it during AST transformation
     * 2. The function is preserved through compilation
     * 3. It's included in the generated Ecto schema module
     * 
     * ## DCE Prevention Strategy
     * 
     * We use a simple @:keep approach rather than complex build macros:
     * - **Simple**: Just add @:keep alongside @:changeset if needed
     * - **Reliable**: Haxe's built-in DCE respects @:keep
     * - **Maintainable**: No complex macro infrastructure required
     * 
     * ## Example Usage
     * 
     * ```haxe
     * @:changeset
     * @:keep  // Optional: Add if function is being eliminated
     * public static function changeset(todo: Todo, params: TodoParams): Changeset<Todo, TodoParams> {
     *     return new Changeset(todo, params)
     *         .validateRequired(["title", "userId"])
     *         .validateLength("title", {min: 3, max: 200});
     * }
     * ```
     * 
     * ## Generated Elixir
     * 
     * ```elixir
     * def changeset(todo, params) do
     *   todo
     *   |> cast(params, [:title, :user_id, :completed])
     *   |> validate_required([:title, :user_id])
     *   |> validate_length(:title, min: 3, max: 200)
     * end
     * ```
     * 
     * ## Automatic Fallback
     * 
     * If no @:changeset function is defined, the compiler generates a basic one:
     * - Casts all fields except id and timestamps
     * - Makes non-nullable fields required
     * - Ensures schema always has a working changeset
     * 
     * @see docs/03-compiler-development/preserving-functions-through-dce.md For DCE details
     */
    static public var changeset: Term;
}

/**
 * Field type mappings from Haxe to Ecto
 * 
 * This provides guidance on how Haxe types map to Ecto field types:
 * 
 * - `Int` → `:integer`
 * - `Float` → `:float`
 * - `String` → `:string`
 * - `Bool` → `:boolean`
 * - `Date` → `:date`
 * - `DateTime` → `:naive_datetime` or `:utc_datetime`
 * - `Array<T>` → `{:array, :type}`
 * - `Map<String, T>` → `:map` or `{:map, :type}`
 * - `Null<T>` → Field is nullable
 * - Custom types → Can use `:embed` or custom Ecto types
 */
class FieldTypes {
    public static inline var Integer = ":integer";
    public static inline var Float = ":float";
    public static inline var String = ":string";
    public static inline var Boolean = ":boolean";
    public static inline var Date = ":date";
    public static inline var DateTime = ":naive_datetime";
    public static inline var UtcDateTime = ":utc_datetime";
    public static inline var Map = ":map";
    public static inline var Binary = ":binary";
    public static inline var Decimal = ":decimal";
}

#end
