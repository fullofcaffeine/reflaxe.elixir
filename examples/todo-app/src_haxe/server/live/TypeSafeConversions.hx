package server.live;

import server.types.Types.EventParams;
import phoenix.Ecto.ChangesetParams;
import phoenix.Ecto.ChangesetValue;

/**
 * Type-safe conversion utilities for Phoenix LiveView operations
 * 
 * This module provides compile-time validated conversions between different
 * parameter types, eliminating unsafe casts and ensuring data integrity.
 * 
 * ## Design Philosophy
 * 
 * Instead of using Dynamic types or unsafe casts, we create explicit conversion
 * functions that validate and transform data in a type-safe manner.
 * 
 * ## Benefits
 * - **Compile-time validation**: All conversions are type-checked
 * - **No data loss**: Explicit handling of all field types  
 * - **Error tracking**: Clear handling of conversion failures
 * - **Maintainable**: Easy to extend and modify conversion logic
 */
class TypeSafeConversions {
    
    /**
     * Convert EventParams to ChangesetParams with full type safety
     * 
     * EventParams comes from Phoenix LiveView events with Null<String> fields.
     * ChangesetParams expects Map<String, ChangesetValue> for Ecto operations.
     * 
     * @param params EventParams from LiveView event handling
     * @return ChangesetParams suitable for Ecto changeset operations
     */
    public static function eventParamsToChangesetParams(params: EventParams): ChangesetParams {
        var changesetParams = new Map<String, ChangesetValue>();
        
        // Convert each field with proper null handling
        if (params.title != null) {
            changesetParams.set("title", ChangesetValue.StringValue(params.title));
        }
        
        if (params.description != null) {
            changesetParams.set("description", ChangesetValue.StringValue(params.description));
        }
        
        if (params.priority != null) {
            changesetParams.set("priority", ChangesetValue.StringValue(params.priority));
        }
        
        if (params.due_date != null) {
            changesetParams.set("due_date", ChangesetValue.StringValue(params.due_date));
        }
        
        if (params.tags != null) {
            changesetParams.set("tags", ChangesetValue.StringValue(params.tags));
        }
        
        // Handle special fields
        if (params.completed != null) {
            changesetParams.set("completed", ChangesetValue.BoolValue(params.completed));
        }
        
        // Note: user_id is not in EventParams - it's set separately in TodoLive
        
        return changesetParams;
    }
    
    /**
     * Convert raw todo creation parameters to ChangesetParams
     * 
     * Used when creating new todos with structured data rather than event params.
     * 
     * @param title Todo title
     * @param description Todo description  
     * @param priority Priority level
     * @param due_date Due date string
     * @param tags Tags string (comma-separated)
     * @param user_id User ID for ownership
     * @return Type-safe ChangesetParams
     */
    public static function createTodoParams(
        title: String,
        description: Null<String>,
        priority: String,
        due_date: Null<String>, 
        tags: Null<String>,
        user_id: Int
    ): ChangesetParams {
        var changesetParams = new Map<String, ChangesetValue>();
        
        // Required fields
        changesetParams.set("title", ChangesetValue.StringValue(title));
        changesetParams.set("priority", ChangesetValue.StringValue(priority));
        changesetParams.set("user_id", ChangesetValue.IntValue(user_id));
        changesetParams.set("completed", ChangesetValue.BoolValue(false));
        
        // Optional fields
        if (description != null) {
            changesetParams.set("description", ChangesetValue.StringValue(description));
        }
        
        if (due_date != null) {
            changesetParams.set("due_date", ChangesetValue.StringValue(due_date));
        }
        
        if (tags != null) {
            changesetParams.set("tags", ChangesetValue.StringValue(tags));
        }
        
        return changesetParams;
    }
    
    /**
     * Validate that EventParams contains required fields for todo creation
     * 
     * @param params EventParams from LiveView
     * @return true if all required fields are present and valid
     */
    public static function validateTodoCreationParams(params: EventParams): Bool {
        return params.title != null && 
               params.title.length > 0;
    }
    
    /**
     * Create a complete TodoLiveAssigns object with all required fields
     * 
     * Instead of partial objects that fail assign_multiple, create complete
     * assigns structures with proper defaults for missing fields.
     * 
     * @param base Base assigns to extend (optional)
     * @param updates Fields to update
     * @return Complete TodoLiveAssigns object
     */
    public static function createCompleteAssigns(
        ?base: server.live.TodoLive.TodoLiveAssigns,
        ?todos: Array<server.schemas.Todo>,
        ?filter: String,
        ?sort_by: String,
        ?current_user: server.types.Types.User,
        ?editing_todo: Null<server.schemas.Todo>,
        ?show_form: Bool,
        ?search_query: String,
        ?selected_tags: Array<String>
    ): server.live.TodoLive.TodoLiveAssigns {
        
        // Use base or create defaults
        var assigns: server.live.TodoLive.TodoLiveAssigns = {
            todos: todos != null ? todos : (base != null ? base.todos : []),
            filter: filter != null ? filter : (base != null ? base.filter : "all"),
            sort_by: sort_by != null ? sort_by : (base != null ? base.sort_by : "created"),
            current_user: current_user != null ? current_user : (base != null ? base.current_user : createDefaultUser()),
            editing_todo: editing_todo != null ? editing_todo : (base != null ? base.editing_todo : null),
            show_form: show_form != null ? show_form : (base != null ? base.show_form : false),
            search_query: search_query != null ? search_query : (base != null ? base.search_query : ""),
            selected_tags: selected_tags != null ? selected_tags : (base != null ? base.selected_tags : []),
            total_todos: 0, // Will be calculated below
            completed_todos: 0, // Will be calculated below  
            pending_todos: 0 // Will be calculated below
        };
        
        // Calculate statistics
        assigns.total_todos = assigns.todos.length;
        assigns.completed_todos = countCompleted(assigns.todos);
        assigns.pending_todos = assigns.total_todos - assigns.completed_todos;
        
        return assigns;
    }
    
    /**
     * Create a default user for fallback scenarios
     */
    private static function createDefaultUser(): server.types.Types.User {
        return {
            id: 1,
            name: "Default User",
            email: "default@example.com",
            password_hash: "default_hash",
            confirmed_at: null,
            last_login_at: null,
            active: true
        };
    }
    
    /**
     * Count completed todos in array
     */
    private static function countCompleted(todos: Array<server.schemas.Todo>): Int {
        var count = 0;
        for (todo in todos) {
            if (todo.completed) count++;
        }
        return count;
    }
}