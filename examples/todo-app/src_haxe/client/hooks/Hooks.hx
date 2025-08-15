package client.hooks;

/**
 * Hooks registry for Phoenix LiveView
 * Exports all available hooks for LiveView to use
 */
class Hooks {
    
    /**
     * Get all available hooks as a dynamic object
     * This is what gets exported to Phoenix LiveView
     */
    public static function getAll(): Dynamic {
        return {
            AutoFocus: AutoFocus,
            ThemeToggle: ThemeToggle,
            TodoForm: TodoForm,
            TodoFilter: TodoFilter,
            LiveSync: LiveSync
        };
    }
    
    /**
     * Individual hook getters for direct access
     */
    public static function getAutoFocus(): Dynamic {
        return AutoFocus;
    }
    
    public static function getThemeToggle(): Dynamic {
        return ThemeToggle;
    }
    
    public static function getTodoForm(): Dynamic {
        return TodoForm;
    }
    
    public static function getTodoFilter(): Dynamic {
        return TodoFilter;
    }
    
    public static function getLiveSync(): Dynamic {
        return LiveSync;
    }
}