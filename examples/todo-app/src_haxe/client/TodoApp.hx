package client;

import shared.TodoTypes;
import client.hooks.Hooks;
import client.utils.DarkMode;
import client.utils.LocalStorage;
import reflaxe.js.Async;

/**
 * Main client-side entry point for Todo App
 * Compiles to JavaScript and integrates with Phoenix LiveView
 * 
 * This provides a clean, modular architecture for client-side functionality
 * while maintaining type safety throughout the application.
 */
@:build(reflaxe.js.Async.build())
class TodoApp {
    
    private static var isInitialized: Bool = false;
    
    /**
     * Application entry point
     * Called when the JavaScript loads in the browser
     */
    @:expose
    public static function main(): Void {
        if (isInitialized) {
            trace("TodoApp already initialized");
            return;
        }
        
        trace("Todo App client initializing...");
        
        // Initialize client-side utilities
        initializeUtilities();
        
        // Set up global error handling
        setupGlobalErrorHandling();
        
        // Export hooks for Phoenix LiveView
        exportHooks();
        
        // Initialize UI enhancements
        initializeEnhancements();
        
        isInitialized = true;
        trace("Todo App client ready!");
    }
    
    /**
     * Initialize client-side utilities
     */
    private static function initializeUtilities(): Void {
        DarkMode.initialize();
        LocalStorage.initialize();
    }
    
    /**
     * Set up global error handling for the client
     */
    private static function setupGlobalErrorHandling(): Void {
        js.Browser.window.addEventListener("error", function(event) {
            trace('Client error: ${event.error}');
            // Log error asynchronously (fire and forget)
            js.Syntax.code("(async () => {
                try {
                    await {0}('javascript_error', {
                        message: {1},
                        filename: {2},
                        lineno: {3},
                        colno: {4},
                        timestamp: Date.now()
                    });
                } catch (e) {
                    console.warn('Failed to log error:', e);
                }
            })()", logErrorToServerAsync, event.message, event.filename, event.lineno, event.colno);
        });
        
        js.Browser.window.addEventListener("unhandledrejection", function(event) {
            trace('Unhandled promise rejection: ${event.reason}');
            // Log promise rejection asynchronously (fire and forget)
            js.Syntax.code("(async () => {
                try {
                    await {0}('promise_rejection', {
                        reason: {1},
                        timestamp: Date.now()
                    });
                } catch (e) {
                    console.warn('Failed to log promise rejection:', e);
                }
            })()", logErrorToServerAsync, Std.string(event.reason));
        });
    }
    
    /**
     * Export hooks for Phoenix LiveView to use
     * This makes our Haxe hooks available to the Phoenix JavaScript runtime
     */
    private static function exportHooks(): Void {
        var hooks = Hooks.getAll();
        
        // Export to global scope for Phoenix LiveView using modern js.Syntax.code
        js.Syntax.code("
            // Make hooks available globally
            if (typeof window !== 'undefined') {
                window.TodoAppHooks = {0};
                
                // Also export individual hooks for direct access
                window.AutoFocus = {1};
                window.ThemeToggle = {2};
                window.TodoForm = {3};
                window.TodoFilter = {4};
                window.LiveSync = {5};
            }
            
            // Export as ES6 module
            if (typeof module !== 'undefined' && module.exports) {
                module.exports = {
                    Hooks: {0},
                    AutoFocus: {1},
                    ThemeToggle: {2},
                    TodoForm: {3},
                    TodoFilter: {4},
                    LiveSync: {5}
                };
            }
        ", 
            hooks,
            Hooks.getAutoFocus(),
            Hooks.getThemeToggle(),
            Hooks.getTodoForm(),
            Hooks.getTodoFilter(),
            Hooks.getLiveSync()
        );
        
        trace("Phoenix LiveView hooks exported successfully");
    }
    
    /**
     * Initialize UI enhancements and additional features
     */
    private static function initializeEnhancements(): Void {
        // Set up keyboard shortcuts
        setupGlobalKeyboardShortcuts();
        
        // Initialize performance monitoring
        setupPerformanceMonitoring();
        
        // Add CSS enhancements
        addDynamicStyles();
        
        // Initialize accessibility features
        setupAccessibilityFeatures();
    }
    
    /**
     * Set up global keyboard shortcuts
     */
    private static function setupGlobalKeyboardShortcuts(): Void {
        js.Browser.document.addEventListener("keydown", function(e: js.html.KeyboardEvent) {
            // Only handle shortcuts if not in input/textarea (type-safe casting)
            var target = e.target;
            if (target != null && js.Syntax.instanceof(target, js.html.Element)) {
                var element = cast(target, js.html.Element);
                if (element.nodeName == "INPUT" || element.nodeName == "TEXTAREA") {
                    return;
                }
            }
            
            // Global shortcuts
            if (e.ctrlKey || e.metaKey) {
                switch (e.key) {
                    case "k": // Cmd/Ctrl + K: Quick search
                        e.preventDefault();
                        focusSearch();
                    
                    case "n": // Cmd/Ctrl + N: New todo
                        e.preventDefault();
                        triggerNewTodo();
                    
                    case "/": // Cmd/Ctrl + /: Show keyboard shortcuts
                        e.preventDefault();
                        showKeyboardShortcuts();
                }
            }
            
            // Other shortcuts
            switch (e.key) {
                case "?": // Show help
                    if (e.shiftKey) {
                        e.preventDefault();
                        showKeyboardShortcuts();
                    }
            }
        });
    }
    
    /**
     * Set up performance monitoring with async/await for cleaner error handling
     */
    private static function setupPerformanceMonitoring(): Void {
        // Monitor page load performance using modern PerformanceNavigationTiming API
        js.Browser.window.addEventListener("load", function() {
            // Use async IIFE to handle performance measurement with proper error handling
            js.Syntax.code("(async () => {
                try {
                    await {0}();
                } catch (error) {
                    console.error('Performance monitoring failed:', error);
                }
            })()", measurePagePerformance);
        });
        
        // Monitor LiveView connection time
        monitorLiveViewPerformance();
    }
    
    /**
     * Async function to measure page performance and log metrics
     */
    @:async
    private static function measurePagePerformance(): js.lib.Promise<Void> {
        if (js.Browser.window.performance == null) {
            return js.lib.Promise.resolve();
        }
        
        // Use modern PerformanceNavigationTiming API instead of deprecated timing
        var entries = js.Browser.window.performance.getEntriesByType("navigation");
        if (entries.length == 0) {
            // Fallback for browsers that don't support PerformanceNavigationTiming
            trace("PerformanceNavigationTiming not supported, using basic measurement");
            return js.lib.Promise.resolve();
        }
        
        var navTiming: js.html.PerformanceNavigationTiming = cast entries[0];
        var domLoadTime = navTiming.domContentLoadedEventEnd - navTiming.domContentLoadedEventStart;
        var fullLoadTime = navTiming.loadEventEnd - navTiming.fetchStart;
        
        trace('DOM load time: ${domLoadTime}ms, Full page load: ${fullLoadTime}ms');
        
        // Log metrics asynchronously with proper error handling
        Async.await(logMetricToServerAsync("dom_load_time", domLoadTime));
        Async.await(logMetricToServerAsync("page_load_time", fullLoadTime));
        
        // Log additional performance metrics
        var resourceLoadTime = navTiming.loadEventEnd - navTiming.domContentLoadedEventEnd;
        if (resourceLoadTime > 0) {
            Async.await(logMetricToServerAsync("resource_load_time", resourceLoadTime));
        }
        
        // Check for performance issues and report them
        if (fullLoadTime > 3000) { // Slow page load > 3 seconds
            Async.await(logErrorToServerAsync("performance_warning", {
                type: "slow_page_load",
                load_time: fullLoadTime,
                threshold: 3000
            }));
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Add dynamic CSS styles for enhancements
     */
    private static function addDynamicStyles(): Void {
        var style = js.Browser.document.createStyleElement();
        style.textContent = '
            /* Todo App Enhanced Styles */
            .todo-item {
                transition: all 0.2s ease;
            }
            
            .todo-item:hover {
                transform: translateX(2px);
            }
            
            .updated-highlight {
                background: rgba(59, 130, 246, 0.1);
                border-left: 3px solid #3B82F6;
                animation: highlightFade 2s ease-out;
            }
            
            @keyframes highlightFade {
                from { 
                    background: rgba(59, 130, 246, 0.3);
                    transform: scale(1.01);
                }
                to { 
                    background: rgba(59, 130, 246, 0.1);
                    transform: scale(1);
                }
            }
            
            .theme-toggle-clicked {
                transform: scale(0.95);
                transition: transform 0.1s ease;
            }
            
            .connection-status {
                font-size: 0.75rem;
                color: #6B7280;
            }
            
            .connection-status.online {
                color: #10B981;
            }
            
            .connection-status.offline {
                color: #EF4444;
            }
            
            /* Keyboard shortcuts overlay */
            .keyboard-shortcuts-overlay {
                position: fixed;
                top: 0;
                left: 0;
                right: 0;
                bottom: 0;
                background: rgba(0, 0, 0, 0.8);
                z-index: 1000;
                display: flex;
                align-items: center;
                justify-content: center;
            }
            
            .keyboard-shortcuts-panel {
                background: white;
                dark:bg-gray-800;
                border-radius: 0.5rem;
                padding: 2rem;
                max-width: 500px;
                max-height: 80vh;
                overflow-y: auto;
            }
        ';
        js.Browser.document.head.appendChild(style);
    }
    
    /**
     * Set up accessibility features
     */
    private static function setupAccessibilityFeatures(): Void {
        // Add skip links for keyboard navigation
        addSkipLinks();
        
        // Enhance focus management
        setupFocusManagement();
        
        // Add ARIA live regions for status updates
        setupLiveRegions();
    }
    
    /**
     * Add skip links for accessibility
     */
    private static function addSkipLinks(): Void {
        var skipLinks = js.Browser.document.createDivElement();
        skipLinks.className = "sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50";
        skipLinks.innerHTML = '
            <a href="#main-content" class="bg-blue-600 text-white px-4 py-2 rounded-md">
                Skip to main content
            </a>
            <a href="#todo-form" class="bg-blue-600 text-white px-4 py-2 rounded-md ml-2">
                Skip to new todo form
            </a>
        ';
        js.Browser.document.body.insertBefore(skipLinks, js.Browser.document.body.firstChild);
    }
    
    /**
     * Set up focus management
     */
    private static function setupFocusManagement(): Void {
        // Trap focus in modals when open
        // This would be expanded based on specific modal implementations
    }
    
    /**
     * Set up ARIA live regions for status updates
     */
    private static function setupLiveRegions(): Void {
        var liveRegion = js.Browser.document.createDivElement();
        liveRegion.id = "live-region";
        liveRegion.setAttribute("aria-live", "polite");
        liveRegion.setAttribute("aria-atomic", "true");
        liveRegion.className = "sr-only";
        js.Browser.document.body.appendChild(liveRegion);
    }
    
    /**
     * Focus the search input
     */
    private static function focusSearch(): Void {
        var searchInput = js.Browser.document.querySelector('input[type="text"][placeholder*="Search"]');
        if (searchInput != null) {
            searchInput.focus();
        }
    }
    
    /**
     * Trigger new todo creation
     */
    private static function triggerNewTodo(): Void {
        var newTodoButton = js.Browser.document.querySelector('[phx-click="toggle_form"]');
        if (newTodoButton != null) {
            newTodoButton.click();
        }
    }
    
    /**
     * Show keyboard shortcuts overlay
     */
    private static function showKeyboardShortcuts(): Void {
        var overlay = js.Browser.document.querySelector(".keyboard-shortcuts-overlay");
        if (overlay != null) {
            overlay.style.display = "flex";
            return;
        }
        
        // Create shortcuts overlay
        overlay = js.Browser.document.createDivElement();
        overlay.className = "keyboard-shortcuts-overlay";
        overlay.innerHTML = '
            <div class="keyboard-shortcuts-panel">
                <h3 class="text-lg font-bold mb-4">Keyboard Shortcuts</h3>
                <div class="space-y-2 text-sm">
                    <div><kbd>Ctrl/Cmd + K</kbd> - Focus search</div>
                    <div><kbd>Ctrl/Cmd + N</kbd> - New todo</div>
                    <div><kbd>Ctrl/Cmd + /</kbd> - Show shortcuts</div>
                    <div><kbd>Alt + 1/2/3</kbd> - Filter todos</div>
                    <div><kbd>Escape</kbd> - Close forms/modals</div>
                    <div><kbd>Ctrl/Cmd + Enter</kbd> - Submit form</div>
                </div>
                <button class="mt-4 px-4 py-2 bg-gray-200 rounded close-shortcuts">Close</button>
            </div>
        ';
        
        // Add close functionality
        overlay.addEventListener("click", function(e) {
            if (e.target == overlay || e.target.classList.contains("close-shortcuts")) {
                overlay.style.display = "none";
            }
        });
        
        js.Browser.document.body.appendChild(overlay);
    }
    
    /**
     * Monitor LiveView performance
     */
    private static function monitorLiveViewPerformance(): Void {
        // This would hook into Phoenix LiveView events to monitor connection performance
        // For now, just a placeholder
        trace("LiveView performance monitoring initialized");
    }
    
    
    /**
     * Async error logging to server with retry logic and batching
     */
    @:async
    private static function logErrorToServerAsync(type: String, details: Dynamic): js.lib.Promise<Void> {
        try {
            // Store locally first as fallback
            LocalStorage.setObject('last_error_${type}', {
                type: type,
                details: details,
                timestamp: Date.now().getTime()
            });
            
            // Attempt to send to server via LiveView
            var errorData: Dynamic = {
                error_type: type,
                details: details,
                timestamp: Date.now().getTime(),
                user_agent: js.Browser.navigator.userAgent,
                url: js.Browser.location.href
            };
            var _result = Async.await(sendToLiveViewAsync("error_log", errorData));
            
            trace('Error logged to server: ${type}');
            
        } catch (e: Dynamic) {
            // Server communication failed, error is already stored locally
            trace('Failed to send error to server: ${e}');
            
            // Queue for retry later
            Async.await(queueForRetryAsync("error", {
                type: type,
                details: details,
                timestamp: Date.now().getTime()
            }));
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Async metric logging to server with batching for performance
     */
    @:async
    private static function logMetricToServerAsync(metric: String, value: Float): js.lib.Promise<Void> {
        try {
            // Store locally first as fallback
            LocalStorage.setNumber('metric_${metric}', value);
            
            // Batch metrics for efficient server communication
            var metricData: Dynamic = {
                metric: metric,
                value: value,
                timestamp: Date.now().getTime()
            };
            var _result1 = Async.await(addToBatchAsync("metrics", metricData));
            
            // Send batch if it's full or enough time has passed
            Async.await(maybeSendBatchAsync("metrics"));
            
        } catch (e: Dynamic) {
            trace('Failed to process metric: ${e}');
            // Metric is still stored locally, so we don't lose data
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Send data to Phoenix LiveView with error handling and timeout
     */
    @:async
    private static function sendToLiveViewAsync(event: String, data: Dynamic): js.lib.Promise<Void> {
        // Create a promise that resolves when LiveView responds or times out
        var promise = new js.lib.Promise(function(resolve, reject) {
            var timeout = js.Browser.window.setTimeout(function() {
                reject("LiveView communication timeout");
            }, 5000); // 5 second timeout
            
            try {
                // Simulated LiveView push - in real implementation this would use LiveView hooks
                js.Syntax.code("
                    if (window.liveSocket && window.liveSocket.channel) {
                        window.liveSocket.channel.push({0}, {1})
                            .receive('ok', (resp) => {
                                clearTimeout({2});
                                {3}(resp);
                            })
                            .receive('error', (resp) => {
                                clearTimeout({2});
                                {4}(resp);
                            });
                    } else {
                        clearTimeout({2});
                        {4}('LiveView not available');
                    }
                ", event, data, timeout, resolve, reject);
            } catch (e: Dynamic) {
                js.Browser.window.clearTimeout(timeout);
                reject(e);
            }
        });
        
        Async.await(promise);
    }
    
    /**
     * Queue data for retry when server communication fails
     */
    @:async
    private static function queueForRetryAsync(category: String, data: Dynamic): js.lib.Promise<Void> {
        var queueKey = 'retry_queue_${category}';
        var queue = LocalStorage.getObject(queueKey);
        
        if (queue == null) {
            queue = [];
        }
        
        queue.push(data);
        
        // Limit queue size to prevent memory issues
        if (queue.length > 100) {
            queue = queue.slice(-50); // Keep last 50 items
        }
        
        LocalStorage.setObject(queueKey, queue);
        
        // Schedule retry attempt
        Async.await(scheduleRetryAsync(category));
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Add data to batch for efficient server communication
     */
    @:async
    private static function addToBatchAsync(batchType: String, data: Dynamic): js.lib.Promise<Void> {
        var batchKey = 'batch_${batchType}';
        var batch = LocalStorage.getObject(batchKey);
        
        if (batch == null) {
            batch = {
                items: [],
                created_at: Date.now().getTime()
            };
        }
        
        batch.items.push(data);
        LocalStorage.setObject(batchKey, batch);
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Send batch to server if conditions are met
     */
    @:async
    private static function maybeSendBatchAsync(batchType: String): js.lib.Promise<Void> {
        var batchKey = 'batch_${batchType}';
        var batch = LocalStorage.getObject(batchKey);
        
        if (batch == null || batch.items.length == 0) {
            return;
        }
        
        var shouldSend = false;
        var now = Date.now().getTime();
        
        // Send if batch is full (10 items) or old (30 seconds)
        if (batch.items.length >= 10 || (now - batch.created_at) > 30000) {
            shouldSend = true;
        }
        
        if (shouldSend) {
            try {
                Async.await(sendToLiveViewAsync('batch_${batchType}', {
                    items: batch.items,
                    count: batch.items.length,
                    created_at: batch.created_at,
                    sent_at: now
                }));
                
                // Clear batch after successful send
                LocalStorage.removeItem(batchKey);
                trace('Sent batch of ${batch.items.length} ${batchType} to server');
                
            } catch (e: Dynamic) {
                trace('Failed to send batch ${batchType}: ${e}');
                // Batch remains in LocalStorage for retry
            }
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Schedule retry attempt for failed communications
     */
    @:async
    private static function scheduleRetryAsync(category: String): js.lib.Promise<Void> {
        // Use exponential backoff: 1s, 2s, 4s, 8s, then 30s max
        var retryKey = 'retry_count_${category}';
        var retryCount = LocalStorage.getNumber(retryKey, 0);
        var delay = Math.min(1000 * Math.pow(2, retryCount), 30000);
        
        Async.await(Async.delay(null, Std.int(delay)));
        
        try {
            Async.await(processRetryQueueAsync(category));
            
            // Reset retry count on success
            LocalStorage.removeItem(retryKey);
            
        } catch (e: Dynamic) {
            // Increment retry count and try again later
            LocalStorage.setNumber(retryKey, retryCount + 1);
            trace('Retry ${category} failed (attempt ${retryCount + 1}): ${e}');
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Process queued items for retry
     */
    @:async
    private static function processRetryQueueAsync(category: String): js.lib.Promise<Void> {
        var queueKey = 'retry_queue_${category}';
        var queue = LocalStorage.getObject(queueKey);
        
        if (queue == null || queue.length == 0) {
            return js.lib.Promise.resolve();
        }
        
        // Process items in batch
        Async.await(sendToLiveViewAsync('retry_${category}', {
            items: queue,
            count: queue.length,
            retry_timestamp: Date.now().getTime()
        }));
        
        // Clear queue after successful send
        LocalStorage.removeItem(queueKey);
        trace('Successfully sent ${queue.length} queued ${category} items');
        
        return js.lib.Promise.resolve();
    }
    
    // Async Data Fetching Utilities
    
    /**
     * Fetch todos from server with proper error handling and caching
     */
    @:async
    public static function fetchTodosAsync(): js.lib.Promise<Array<Dynamic>> {
        try {
            // Check cache first (5 minute expiry)
            var cacheKey = "todos_cache";
            var cacheData = LocalStorage.getObject(cacheKey);
            var now = Date.now().getTime();
            
            if (cacheData != null && (now - cacheData.timestamp) < 300000) { // 5 minutes
                trace("Returning cached todos");
                return cacheData.todos;
            }
            
            // Fetch from server
            var response = Async.await(fetchFromAPIAsync("/api/todos", "GET"));
            var todos = response.data;
            
            // Cache the result
            LocalStorage.setObject(cacheKey, {
                todos: todos,
                timestamp: now
            });
            
            trace('Fetched ${todos.length} todos from server');
            return todos;
            
        } catch (e: Dynamic) {
            trace('Failed to fetch todos: ${e}');
            
            // Return cached data as fallback, even if expired
            var fallbackData = LocalStorage.getObject("todos_cache");
            if (fallbackData != null) {
                trace("Returning stale cached todos as fallback");
                return fallbackData.todos;
            }
            
            // Return empty array if no cache available
            return [];
        }
    }
    
    /**
     * Create a new todo on the server
     */
    @:async
    public static function createTodoAsync(title: String, ?description: String, ?priority: String): js.lib.Promise<Dynamic> {
        try {
            var todoData = {
                title: title,
                description: description ?? "",
                priority: priority ?? "medium",
                completed: false
            };
            
            var response = Async.await(fetchFromAPIAsync("/api/todos", "POST", todoData));
            
            // Invalidate cache after successful creation
            LocalStorage.removeItem("todos_cache");
            
            // Log successful creation
            Async.await(logMetricToServerAsync("todo_created", 1));
            
            trace('Created todo: ${title}');
            return response.data;
            
        } catch (e: Dynamic) {
            trace('Failed to create todo: ${e}');
            
            // Log error
            Async.await(logErrorToServerAsync("todo_creation_failed", {
                title: title,
                error: Std.string(e)
            }));
            
            throw e; // Re-throw to let caller handle it
        }
    }
    
    /**
     * Update an existing todo on the server
     */
    @:async
    public static function updateTodoAsync(id: Int, updates: Dynamic): js.lib.Promise<Dynamic> {
        try {
            var response = Async.await(fetchFromAPIAsync('/api/todos/${id}', "PUT", updates));
            
            // Invalidate cache after successful update
            LocalStorage.removeItem("todos_cache");
            
            // Log successful update
            Async.await(logMetricToServerAsync("todo_updated", 1));
            
            trace('Updated todo ${id}');
            return response.data;
            
        } catch (e: Dynamic) {
            trace('Failed to update todo ${id}: ${e}');
            
            // Log error
            Async.await(logErrorToServerAsync("todo_update_failed", {
                todo_id: id,
                updates: updates,
                error: Std.string(e)
            }));
            
            throw e;
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Delete a todo from the server
     */
    @:async
    public static function deleteTodoAsync(id: Int): js.lib.Promise<Void> {
        try {
            Async.await(fetchFromAPIAsync('/api/todos/${id}', "DELETE"));
            
            // Invalidate cache after successful deletion
            LocalStorage.removeItem("todos_cache");
            
            // Log successful deletion
            Async.await(logMetricToServerAsync("todo_deleted", 1));
            
            trace('Deleted todo ${id}');
            
        } catch (e: Dynamic) {
            trace('Failed to delete todo ${id}: ${e}');
            
            // Log error
            Async.await(logErrorToServerAsync("todo_deletion_failed", {
                todo_id: id,
                error: Std.string(e)
            }));
            
            throw e;
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Sync local changes with server
     */
    @:async
    public static function syncWithServerAsync(): js.lib.Promise<Void> {
        try {
            trace("Starting server sync...");
            
            // Process any queued offline changes
            Async.await(processOfflineChangesAsync());
            
            // Fetch latest data from server
            var serverTodos = Async.await(fetchTodosAsync());
            
            // Update local state (this would typically trigger UI updates)
            announceStatus('Synced ${serverTodos.length} todos with server');
            
            // Log successful sync
            Async.await(logMetricToServerAsync("sync_completed", 1));
            
            trace("Server sync completed successfully");
            
        } catch (e: Dynamic) {
            trace('Server sync failed: ${e}');
            
            // Log sync failure
            Async.await(logErrorToServerAsync("sync_failed", {
                error: Std.string(e),
                timestamp: Date.now().getTime()
            }));
            
            announceStatus("Sync failed - working offline");
        }
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Generic API fetch utility with retry logic and proper error handling
     */
    @:async
    private static function fetchFromAPIAsync(url: String, method: String, ?data: Dynamic): js.lib.Promise<Dynamic> {
        var maxRetries = 3;
        var retryDelay = 1000; // Start with 1 second
        
        for (attempt in 0...maxRetries) {
            try {
                var requestOptions: Dynamic = {
                    method: method,
                    headers: {
                        "Content-Type": "application/json",
                        "Accept": "application/json"
                    }
                };
                
                if (data != null && (method == "POST" || method == "PUT" || method == "PATCH")) {
                    requestOptions.body = haxe.Json.stringify(data);
                }
                
                // Create Promise for fetch request
                var promise = new js.lib.Promise(function(resolve, reject) {
                    js.Syntax.code("
                        fetch({0}, {1})
                            .then(response => {
                                if (!response.ok) {
                                    throw new Error(`HTTP error! status: ${response.status}`);
                                }
                                return response.json();
                            })
                            .then(data => {2}({
                                data: data,
                                status: 'success'
                            }))
                            .catch(error => {3}(error));
                    ", url, requestOptions, resolve, reject);
                });
                
                var response = Async.await(promise);
                return response;
                
            } catch (e: Dynamic) {
                if (attempt == maxRetries - 1) {
                    // Last attempt failed, throw error
                    throw e;
                }
                
                // Wait before retry with exponential backoff
                trace('API request failed (attempt ${attempt + 1}/${maxRetries}): ${e}');
                Async.await(Async.delay(null, retryDelay));
                retryDelay *= 2; // Exponential backoff
            }
        }
        
        throw "API request failed after all retries";
    }
    
    /**
     * Process any offline changes that haven't been synced
     */
    @:async
    private static function processOfflineChangesAsync(): js.lib.Promise<Void> {
        var offlineChanges = LocalStorage.getObject("offline_changes");
        
        if (offlineChanges == null || offlineChanges.length == 0) {
            return js.lib.Promise.resolve();
        }
        
        trace('Processing ${offlineChanges.length} offline changes');
        
        for (change in offlineChanges) {
            try {
                switch (change.type) {
                    case "create":
                        Async.await(createTodoAsync(change.data.title, change.data.description, change.data.priority));
                    case "update":
                        Async.await(updateTodoAsync(change.data.id, change.data.updates));
                    case "delete":
                        Async.await(deleteTodoAsync(change.data.id));
                }
            } catch (e: Dynamic) {
                trace('Failed to process offline change: ${e}');
                // Keep the change for next sync attempt
                continue;
            }
        }
        
        // Clear processed changes
        LocalStorage.removeItem("offline_changes");
        trace("Offline changes processed successfully");
        
        return js.lib.Promise.resolve();
    }
    
    /**
     * Queue changes for offline processing
     */
    public static function queueOfflineChange(type: String, data: Dynamic): Void {
        var changes = LocalStorage.getObject("offline_changes");
        if (changes == null) {
            changes = [];
        }
        
        changes.push({
            type: type,
            data: data,
            timestamp: Date.now().getTime()
        });
        
        LocalStorage.setObject("offline_changes", changes);
        trace('Queued offline change: ${type}');
    }
    
    /**
     * Get hook definitions for PhoenixApp integration.
     * 
     * Called by PhoenixApp to retrieve hook definitions without
     * automatically initializing everything. This allows PhoenixApp
     * to control initialization timing and error handling.
     */
    public static function getHooks(): Dynamic {
        return Hooks.getAll();
    }
    
    /**
     * Utility function for client-side state management
     */
    public static function getClientState(): ClientState {
        return {
            darkMode: DarkMode.isEnabled(),
            autoSave: LocalStorage.getBoolean("autoSave", true),
            lastSync: Date.now().getTime()
        };
    }
    
    /**
     * Update client state
     */
    public static function updateClientState(state: ClientState): Void {
        if (state.darkMode != DarkMode.isEnabled()) {
            DarkMode.toggle();
        }
        
        LocalStorage.setBoolean("autoSave", state.autoSave);
    }
    
    /**
     * Announce status update to screen readers
     */
    public static function announceStatus(message: String): Void {
        var liveRegion = js.Browser.document.getElementById("live-region");
        if (liveRegion != null) {
            liveRegion.textContent = message;
        }
    }
}