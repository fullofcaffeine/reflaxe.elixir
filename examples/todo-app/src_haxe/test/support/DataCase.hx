package test.support;

import haxe.test.phoenix.DataCase as BaseDataCase;
import ecto.Changeset;
import server.schemas.Todo;

/**
 * DataCase provides the foundation for Ecto schema and data tests.
 * 
 * This module extends the standard library DataCase with todo-app specific
 * helpers for testing schemas, changesets, and database operations.
 */
@:exunit
class DataCase extends BaseDataCase {
    
    /**
     * Override repository for todo-app
     */
    override public static var repo(default, null): String = "TodoApp.Repo";
    
    /**
     * Create a valid Todo changeset for testing.
     */
    override public static function validChangeset<T>(schema: Class<T>, attrs: Dynamic): Changeset<T> {
        // For Todo schema specifically
        if (schema == Todo) {
            var validAttrs = {
                title: "Test Todo",
                description: "A test todo item",
                completed: false,
                priority: "medium"
            };
            
            // Merge with provided attrs
            for (key in Reflect.fields(attrs)) {
                Reflect.setField(validAttrs, key, Reflect.field(attrs, key));
            }
            
            return cast Todo.changeset(new Todo(), validAttrs);
        }
        
        throw 'Unknown schema type: ${schema}';
    }
    
    /**
     * Create an invalid Todo changeset for testing.
     */
    override public static function invalidChangeset<T>(schema: Class<T>, attrs: Dynamic): Changeset<T> {
        // For Todo schema specifically
        if (schema == Todo) {
            var invalidAttrs = {
                title: "", // Invalid: empty title
                priority: "invalid_priority" // Invalid priority
            };
            
            // Merge with provided attrs
            for (key in Reflect.fields(attrs)) {
                Reflect.setField(invalidAttrs, key, Reflect.field(attrs, key));
            }
            
            return cast Todo.changeset(new Todo(), invalidAttrs);
        }
        
        throw 'Unknown schema type: ${schema}';
    }
    
    /**
     * Create a Todo struct for testing.
     */
    override public static function struct<T>(schema: Class<T>): T {
        if (schema == Todo) {
            return cast new Todo();
        }
        
        throw 'Unknown schema type: ${schema}';
    }
}