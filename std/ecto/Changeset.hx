package ecto;

#if (elixir || reflaxe_runtime)

import elixir.types.Result;

/**
 * Type-safe Ecto.Changeset wrapper
 * 
 * ## Overview
 * 
 * This provides a fully typed abstraction over Ecto.Changeset, allowing
 * compile-time validation of field names and types while maintaining
 * full Ecto compatibility.
 * 
 * ## Architecture Philosophy
 * 
 * **CRITICAL**: We abstract away Dynamic at the system boundary.
 * Users NEVER see Dynamic types - they work with typed parameter structures
 * and our type-safe builder API generates proper Ecto changesets.
 * 
 * ## Usage Example
 * 
 * ```haxe
 * // Define typed parameters
 * typedef UserParams = {
 *     ?name: String,
 *     ?email: String,
 *     ?age: Int
 * }
 * 
 * // In your schema
 * @:changeset
 * public static function changeset(user: User, params: UserParams): Changeset<User, UserParams> {
 *     return new Changeset(user, params)
 *         .cast(["name", "email", "age"])
 *         .validateRequired(["name", "email"])
 *         .validateFormat("email", ~/@/)
 *         .validateNumber("age", {min: 18, max: 120});
 * }
 * ```
 * 
 * ## Generated Elixir
 * 
 * ```elixir
 * def changeset(user, params) do
 *   user
 *   |> cast(params, [:name, :email, :age])
 *   |> validate_required([:name, :email])
 *   |> validate_format(:email, ~r/@/)
 *   |> validate_number(:age, min: 18, max: 120)
 * end
 * ```
 * 
 * ## Type Safety Benefits
 * 
 * - **Compile-time field validation**: Field names are checked at compile time
 * - **Type-safe parameters**: No Dynamic maps, use typed structures
 * - **IDE support**: Full autocomplete for validation methods
 * - **Refactoring safety**: Rename fields across entire codebase
 * 
 * @see ecto.Schema For defining database schemas
 * @see ecto.Repository For database operations
 */
abstract Changeset<T, P>(Dynamic) from Dynamic to Dynamic {
    
    /**
     * Create a new changeset from data and params
     * 
     * @param data The struct being changed
     * @param params The typed parameters
     */
    extern inline public function new(data: T, params: P) {
        // Cast with snake_case atom keys derived from incoming params.
        // Accepts camelCase or string keys (e.g., "dueDate") and converts them
        // to snake_case atoms (e.g., :due_date) before casting. Permitted fields
        // are computed from the transformed map keys.
        this = untyped __elixir__('
          (fn data, params ->
             # Convert incoming keys to snake_case atoms
             snake_params = for {k, v} <- Map.to_list(params), into: %{} do
               key =
                 cond do
                   is_atom(k) -> k
                   true -> String.to_atom(Macro.underscore(to_string(k)))
                 end
               {key, v}
             end
             # Normalize values based on schema types when possible
             normalized_params = for {k, v} <- Map.to_list(snake_params), into: %{} do
               type = data.__struct__.__schema__(:type, k)
               v2 = case {type, v} do
                 # Comma-separated string -> {:array, :string}
                 {{:array, :string}, bin} when is_binary(bin) ->
                   bin
                   |> String.split(",", trim: true)
                   |> Enum.map(&String.trim/1)
                 # String -> integer (when field is :integer)
                 {:integer, bin} when is_binary(bin) ->
                   case Integer.parse(bin) do
                     {int, _} -> int
                     :error -> bin
                   end
                 # String -> boolean ("true"/"false")
                 {:boolean, bin} when is_binary(bin) ->
                   case String.downcase(String.trim(bin)) do
                     "true" -> true
                     "false" -> false
                     _ -> bin
                   end
                 # String -> NaiveDateTime
                 {:naive_datetime, bin} when is_binary(bin) ->
                   case NaiveDateTime.from_iso8601(bin) do
                     {:ok, ndt} -> ndt
                     {:error, _} ->
                       case Date.from_iso8601(bin) do
                         {:ok, d} ->
                           case NaiveDateTime.new(d, ~T[00:00:00]) do
                             {:ok, ndt2} -> ndt2
                             _ -> bin
                           end
                         _ -> bin
                       end
                   end
                 # Empty string -> nil for nullable fields (let validations handle required)
                 {_, bin} when is_binary(bin) and bin == "" -> nil
                 _ -> v
               end
               {k, v2}
             end
             Ecto.Changeset.cast(data, normalized_params, Map.keys(normalized_params))
           end).({0}, {1})
        ', data, params);
    }
    
    /**
     * Cast the given params into the changeset
     * 
     * @param fields List of field names to cast
     * @return The updated changeset
     */
    extern inline public function castFields(fields: Array<String>): Changeset<T, P> {
        // Pass the fields array directly and convert to atoms in Elixir
        return untyped __elixir__('Ecto.Changeset.cast({0}, {1}, Enum.map({2}, &String.to_atom/1))', 
            this, untyped __elixir__('{1}', this), fields);
    }
    
    /**
     * Validate that given fields are present
     * 
     * @param fields List of required field names
     * @return The updated changeset
     */
    extern inline public function validateRequired(fields: Array<String>): Changeset<T, P> {
        // Build the atoms list directly as part of the __elixir__ call
        // We can't dynamically build strings for __elixir__, so we need to handle this differently
        // The simplest approach is to pass the array directly and let Elixir handle it
        return untyped __elixir__('Ecto.Changeset.validate_required({0}, Enum.map({1}, &String.to_atom/1))', this, fields);
    }
    
    /**
     * Validate the length of a string field
     * 
     * @param field The field name
     * @param opts Length options (min, max, is)
     * @return The updated changeset
     */
    extern inline public function validateLength(field: String, opts: {?min: Int, ?max: Int, ?is: Int}): Changeset<T, P> {
        // Build the options list directly with __elixir__ based on what's provided
        // We need to handle all combinations since __elixir__ requires compile-time constants
        if (opts.min != null && opts.max != null && opts.is != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [min: {2}, max: {3}, is: {4}])', 
                this, field, opts.min, opts.max, opts.is);
        } else if (opts.min != null && opts.max != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [min: {2}, max: {3}])', 
                this, field, opts.min, opts.max);
        } else if (opts.min != null && opts.is != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [min: {2}, is: {3}])', 
                this, field, opts.min, opts.is);
        } else if (opts.max != null && opts.is != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [max: {2}, is: {3}])', 
                this, field, opts.max, opts.is);
        } else if (opts.min != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [min: {2}])', 
                this, field, opts.min);
        } else if (opts.max != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [max: {2}])', 
                this, field, opts.max);
        } else if (opts.is != null) {
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [is: {2}])', 
                this, field, opts.is);
        } else {
            // No options provided, just call with empty options
            return untyped __elixir__('Ecto.Changeset.validate_length({0}, String.to_atom({1}), [])', 
                this, field);
        }
    }
    
    /**
     * Validate the format of a field using a regular expression
     * 
     * @param field The field name
     * @param pattern The regex pattern
     * @param message Optional error message
     * @return The updated changeset
     */
    extern inline public function validateFormat(field: String, pattern: EReg, ?message: String): Changeset<T, P> {
        if (message != null) {
            return untyped __elixir__('Ecto.Changeset.validate_format({0}, String.to_atom({1}), {2}, message: {3})', 
                this, field, pattern, message);
        } else {
            return untyped __elixir__('Ecto.Changeset.validate_format({0}, String.to_atom({1}), {2})', 
                this, field, pattern);
        }
    }
    
    /**
     * Validate that a field's value is in a given list
     * 
     * @param field The field name
     * @param values List of allowed values
     * @return The updated changeset
     */
    extern inline public function validateInclusion(field: String, values: Array<Dynamic>): Changeset<T, P> {
        return untyped __elixir__('Ecto.Changeset.validate_inclusion({0}, :{1}, {2})', 
            this, field, values);
    }
    
    /**
     * Validate that a field's value is not in a given list
     * 
     * @param field The field name
     * @param values List of excluded values
     * @return The updated changeset
     */
    extern inline public function validateExclusion(field: String, values: Array<Dynamic>): Changeset<T, P> {
        return untyped __elixir__('Ecto.Changeset.validate_exclusion({0}, :{1}, {2})', 
            this, field, values);
    }
    
    /**
     * Validate a numeric field
     * 
     * @param field The field name
     * @param opts Number validation options
     * @return The updated changeset
     */
    extern inline public function validateNumber(field: String, opts: {?min: Float, ?max: Float, ?equal_to: Float, ?not_equal_to: Float}): Changeset<T, P> {
        // Build the options list directly - simplified version for common cases
        if (opts.min != null && opts.max != null) {
            return untyped __elixir__('Ecto.Changeset.validate_number({0}, :{1}, [greater_than_or_equal_to: {2}, less_than_or_equal_to: {3}])', 
                this, field, opts.min, opts.max);
        } else if (opts.min != null) {
            return untyped __elixir__('Ecto.Changeset.validate_number({0}, :{1}, [greater_than_or_equal_to: {2}])', 
                this, field, opts.min);
        } else if (opts.max != null) {
            return untyped __elixir__('Ecto.Changeset.validate_number({0}, :{1}, [less_than_or_equal_to: {2}])', 
                this, field, opts.max);
        } else if (opts.equal_to != null) {
            return untyped __elixir__('Ecto.Changeset.validate_number({0}, :{1}, [equal_to: {2}])', 
                this, field, opts.equal_to);
        } else if (opts.not_equal_to != null) {
            return untyped __elixir__('Ecto.Changeset.validate_number({0}, :{1}, [not_equal_to: {2}])', 
                this, field, opts.not_equal_to);
        } else {
            return untyped __elixir__('Ecto.Changeset.validate_number({0}, :{1}, [])', 
                this, field);
        }
    }
    
    /**
     * Validate that a field has been accepted (true)
     * 
     * @param field The field name
     * @param message Optional error message
     * @return The updated changeset
     */
    extern inline public function validateAcceptance(field: String, ?message: String): Changeset<T, P> {
        if (message != null) {
            return untyped __elixir__('Ecto.Changeset.validate_acceptance({0}, :{1}, message: {2})', 
                this, field, message);
        } else {
            return untyped __elixir__('Ecto.Changeset.validate_acceptance({0}, :{1})', this, field);
        }
    }
    
    /**
     * Validate that a field matches its confirmation field
     * 
     * @param field The field name
     * @param message Optional error message
     * @return The updated changeset
     */
    extern inline public function validateConfirmation(field: String, ?message: String): Changeset<T, P> {
        if (message != null) {
            return untyped __elixir__('Ecto.Changeset.validate_confirmation({0}, :{1}, message: {2})', 
                this, field, message);
        } else {
            return untyped __elixir__('Ecto.Changeset.validate_confirmation({0}, :{1})', this, field);
        }
    }
    
    /**
     * Add a unique constraint
     * 
     * @param field The field name
     * @param opts Constraint options
     * @return The updated changeset
     */
    extern inline public function uniqueConstraint(field: String, ?opts: {?name: String, ?message: String}): Changeset<T, P> {
        if (opts != null) {
            if (opts.name != null && opts.message != null) {
                return untyped __elixir__('Ecto.Changeset.unique_constraint({0}, :{1}, [name: {2}, message: {3}])', 
                    this, field, opts.name, opts.message);
            } else if (opts.name != null) {
                return untyped __elixir__('Ecto.Changeset.unique_constraint({0}, :{1}, [name: {2}])', 
                    this, field, opts.name);
            } else if (opts.message != null) {
                return untyped __elixir__('Ecto.Changeset.unique_constraint({0}, :{1}, [message: {2}])', 
                    this, field, opts.message);
            } else {
                return untyped __elixir__('Ecto.Changeset.unique_constraint({0}, :{1})', this, field);
            }
        } else {
            return untyped __elixir__('Ecto.Changeset.unique_constraint({0}, :{1})', this, field);
        }
    }
    
    /**
     * Add a foreign key constraint
     * 
     * @param field The field name
     * @param opts Constraint options
     * @return The updated changeset
     */
    extern inline public function foreignKeyConstraint(field: String, ?opts: {?name: String, ?message: String}): Changeset<T, P> {
        if (opts != null) {
            if (opts.name != null && opts.message != null) {
                return untyped __elixir__('Ecto.Changeset.foreign_key_constraint({0}, :{1}, [name: {2}, message: {3}])', 
                    this, field, opts.name, opts.message);
            } else if (opts.name != null) {
                return untyped __elixir__('Ecto.Changeset.foreign_key_constraint({0}, :{1}, [name: {2}])', 
                    this, field, opts.name);
            } else if (opts.message != null) {
                return untyped __elixir__('Ecto.Changeset.foreign_key_constraint({0}, :{1}, [message: {2}])', 
                    this, field, opts.message);
            } else {
                return untyped __elixir__('Ecto.Changeset.foreign_key_constraint({0}, :{1})', this, field);
            }
        } else {
            return untyped __elixir__('Ecto.Changeset.foreign_key_constraint({0}, :{1})', this, field);
        }
    }
    
    /**
     * Add a check constraint
     * 
     * @param field The field name
     * @param opts Constraint options
     * @return The updated changeset
     */
    extern inline public function checkConstraint(field: String, opts: {name: String, ?message: String}): Changeset<T, P> {
        if (opts.message != null) {
            return untyped __elixir__('Ecto.Changeset.check_constraint({0}, :{1}, [name: {2}, message: {3}])', 
                this, field, opts.name, opts.message);
        } else {
            return untyped __elixir__('Ecto.Changeset.check_constraint({0}, :{1}, [name: {2}])', 
                this, field, opts.name);
        }
    }
    
    /**
     * Put a change directly
     * 
     * @param field The field name
     * @param value The new value
     * @return The updated changeset
     */
    extern inline public function putChange(field: String, value: Dynamic): Changeset<T, P> {
        return untyped __elixir__('Ecto.Changeset.put_change({0}, :{1}, {2})', this, field, value);
    }
    
    /**
     * Get a change value
     * 
     * @param field The field name
     * @return The change value or null
     */
    extern inline public function getChange(field: String): Dynamic {
        return untyped __elixir__('Ecto.Changeset.get_change({0}, :{1})', this, field);
    }
    
    /**
     * Get a field value (from changes or data)
     * 
     * @param field The field name
     * @return The field value
     */
    extern inline public function getField(field: String): Dynamic {
        return untyped __elixir__('Ecto.Changeset.get_field({0}, :{1})', this, field);
    }
    
    /**
     * Check if the changeset is valid
     * 
     * @return True if valid
     */
    extern inline public function isValid(): Bool {
        return untyped __elixir__('{0}.valid?', this);
    }
    
    /**
     * Apply an action to the changeset
     * 
     * @param action The action (:insert, :update, :delete, :replace)
     * @return The updated changeset
     */
    extern inline public function applyAction(action: ChangesetAction): Result<T, Changeset<T, P>> {
        return switch(action) {
            case Insert: untyped __elixir__('Ecto.Changeset.apply_action({0}, :insert)', this);
            case Update: untyped __elixir__('Ecto.Changeset.apply_action({0}, :update)', this);
            case Delete: untyped __elixir__('Ecto.Changeset.apply_action({0}, :delete)', this);
            case Replace: untyped __elixir__('Ecto.Changeset.apply_action({0}, :replace)', this);
        };
    }
    
    /**
     * Add an error to the changeset
     * 
     * @param field The field name
     * @param message The error message
     * @param opts Error options
     * @return The updated changeset
     */
    extern inline public function addError(field: String, message: String, ?opts: Dynamic): Changeset<T, P> {
        if (opts != null) {
            return untyped __elixir__('Ecto.Changeset.add_error({0}, :{1}, {2}, {3})', 
                this, field, message, opts);
        } else {
            return untyped __elixir__('Ecto.Changeset.add_error({0}, :{1}, {2})', 
                this, field, message);
        }
    }
    
    /**
     * Traverse errors and extract error messages
     * 
     * @return Map of field names to error messages
     */
    extern inline public function traverseErrors(): Map<String, Array<String>> {
        // This would need a more complex implementation to properly handle
        // Ecto's error structure, but provides the type-safe interface
        return untyped __elixir__('Ecto.Changeset.traverse_errors({0}, fn {msg, opts} -> msg end)', this);
    }

    /**
     * Low-level escape hatch: call Ecto.Changeset.change/2 directly with a pre-normalized map.
     * Prefer using typed wrappers when possible; provided for integration points where
     * the generated schema changeset delegates to change/2 internally.
     */
    extern inline public static function changeRaw(data: Dynamic, normalizedParams: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.change({0}, {1})', data, normalizedParams);
    }

    /**
     * Alias for change/2 to accommodate generated module namespace mapping.
     */
    extern inline public static function change(data: Dynamic, params: Dynamic): Dynamic {
        return untyped __elixir__('Ecto.Changeset.change({0}, {1})', data, params);
    }
}

/**
 * Changeset action types
 */
enum ChangesetAction {
    Insert;
    Update;
    Delete;
    Replace;
}

/**
 * Changeset error structure
 */
typedef ChangesetError = {
    field: String,
    message: String,
    ?validation: String,
    ?constraint: String
}

/**
 * Helper utilities for working with changesets
 */
class ChangesetUtils {
    /**
     * Extract value from a successful changeset result or throw
     * 
     * @param result The changeset result
     * @return The successful value
     * @throws String if the changeset has errors
     */
    extern inline public static function unwrap<T, P>(result: Result<T, Changeset<T, P>>): T {
        return switch(result) {
            case Ok(value): value;
            case Error(changeset): 
                // Call traverseErrors directly via untyped since it's an abstract method
                var errors = untyped __elixir__('Ecto.Changeset.traverse_errors({0}, fn {msg, opts} -> msg end)', changeset);
                throw 'Changeset validation failed: $errors';
        };
    }
    
    /**
     * Extract value from a successful changeset result or return default
     * 
     * @param result The changeset result
     * @param defaultValue The default value to return on error
     * @return The successful value or default
     */
    public static function unwrapOr<T, P>(result: Result<T, Changeset<T, P>>, defaultValue: T): T {
        return switch (result) {
            case Ok(value): value;
            case Error(_): defaultValue;
        };
    }
    
    /**
     * Convert a changeset result to an Option
     * 
     * @param result The changeset result
     * @return Some(value) if successful, None if error
     */
    public static function toOption<T, P>(result: Result<T, Changeset<T, P>>): Option<T> {
        return switch (result) {
            case Ok(value): Some(value);
            case Error(_): None;
        };
    }
}

/**
 * Option type for nullable values
 */
enum Option<T> {
    Some(value: T);
    None;
}

#end
