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

	/** Standard HTTP OPTIONS request */
	OPTIONS;

	/** Standard HTTP HEAD request */
	HEAD;

	/** Standard HTTP CONNECT request */
	CONNECT;

	/** Standard HTTP TRACE request */
	TRACE;

	/** Phoenix match macro route */
	MATCH;

	/** Phoenix LiveView route */
	LIVE;

	/** Phoenix LiveDashboard route (special handling) */
	LIVE_DASHBOARD;

	/** Swoosh mailbox preview route (special handling; dev-only) */
	MAILBOX;
}
