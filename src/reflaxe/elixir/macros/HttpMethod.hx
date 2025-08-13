package reflaxe.elixir.macros;

/**
 * Type-safe HTTP methods for Router DSL
 * 
 * Provides compile-time validation and IDE autocomplete for route methods
 * instead of error-prone string literals.
 */
enum HttpMethod {
    /** Standard HTTP GET request */
    GET;
    
    /** Standard HTTP POST request */
    POST;
    
    /** Standard HTTP PUT request */
    PUT;
    
    /** Standard HTTP DELETE request */
    DELETE;
    
    /** Standard HTTP PATCH request */
    PATCH;
    
    /** Phoenix LiveView route */
    LIVE;
    
    /** Phoenix LiveDashboard route (special handling) */
    LIVE_DASHBOARD;
}