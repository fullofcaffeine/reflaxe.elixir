package client.hooks;

import js.html.Element;
import js.html.InputElement;
import js.html.KeyboardEvent;
import client.extern.Phoenix.LiveViewHook;
import client.utils.LocalStorage;
import shared.TodoTypes;

/**
 * TodoFilter hook for search and filtering functionality
 * Handles search input, filter persistence, and keyboard shortcuts
 */
class TodoFilter implements LiveViewHook {
    
    public var el: Element;
    
    private var searchTimer: Int = -1;
    private var searchDelay: Int = 300; // 300ms debounce
    
    public function new() {}
    
    /**
     * Set up filter functionality when mounted
     */
    public function mounted(): Void {
        setupSearchInput();
        setupFilterButtons();
        setupKeyboardShortcuts();
        restoreFilterState();
    }
    
    /**
     * Clean up when destroyed
     */
    public function destroyed(): Void {
        clearSearchTimer();
    }
    
    /**
     * Set up search input with debouncing
     */
    private function setupSearchInput(): Void {
        var searchInput = el.querySelector("input[type='text']");
        if (searchInput == null) return;
        
        var input: InputElement = cast searchInput;
        
        input.addEventListener("input", function(e) {
            scheduleSearch(input.value);
        });
        
        input.addEventListener("keydown", function(e: KeyboardEvent) {
            // Escape: Clear search
            if (e.key == "Escape") {
                e.preventDefault();
                clearSearch(input);
            }
            
            // Enter: Execute search immediately
            if (e.key == "Enter") {
                e.preventDefault();
                executeSearch(input.value);
            }
        });
        
        // Placeholder text based on current filter
        updateSearchPlaceholder(input);
    }
    
    /**
     * Set up filter button interactions
     */
    private function setupFilterButtons(): Void {
        var filterButtons = el.querySelectorAll("[phx-click='filter_todos']");
        
        for (i in 0...filterButtons.length) {
            var button = filterButtons[i];
            
            button.addEventListener("click", function(e) {
                var filterValue = cast(button, js.html.Element).getAttribute("phx-value-filter");
                saveFilterState(filterValue);
                updateActiveButton(cast(button, js.html.Element));
            });
        }
    }
    
    /**
     * Set up keyboard shortcuts for filtering
     */
    private function setupKeyboardShortcuts(): Void {
        js.Browser.document.addEventListener("keydown", function(e: KeyboardEvent) {
            // Only handle if this filter component is active
            if (!isComponentActive()) return;
            
            // Ctrl/Cmd + F: Focus search
            if ((e.ctrlKey || e.metaKey) && e.key == "f") {
                e.preventDefault();
                focusSearch();
            }
            
            // Alt + 1/2/3: Filter shortcuts
            if (e.altKey && !e.ctrlKey && !e.metaKey) {
                var filterMap = ["all", "active", "completed"];
                var index = Std.parseInt(e.key) - 1;
                
                if (index >= 0 && index < filterMap.length) {
                    e.preventDefault();
                    setFilter(filterMap[index]);
                }
            }
        });
    }
    
    /**
     * Schedule search with debouncing
     */
    private function scheduleSearch(query: String): Void {
        clearSearchTimer();
        
        searchTimer = js.Browser.window.setTimeout(function() {
            executeSearch(query);
        }, searchDelay);
    }
    
    /**
     * Clear the search timer
     */
    private function clearSearchTimer(): Void {
        if (searchTimer != -1) {
            js.Browser.window.clearTimeout(searchTimer);
            searchTimer = -1;
        }
    }
    
    /**
     * Execute the search
     */
    private function executeSearch(query: String): Void {
        // Save search query
        LocalStorage.setString("todo_search_query", query);
        
        // Push event to LiveView
        pushEventIfAvailable("search_todos", {query: query});
        
        // Update URL if supported
        updateURL(query);
    }
    
    /**
     * Clear search input and results
     */
    private function clearSearch(input: InputElement): Void {
        input.value = "";
        executeSearch("");
        input.blur();
    }
    
    /**
     * Focus the search input
     */
    private function focusSearch(): Void {
        var searchInput = el.querySelector("input[type='text']");
        if (searchInput != null) {
            searchInput.focus();
        }
    }
    
    /**
     * Set active filter
     */
    private function setFilter(filter: String): Void {
        // Find and click the appropriate filter button
        var button = el.querySelector('[phx-value-filter="$filter"]');
        if (button != null) {
            button.click();
        }
    }
    
    /**
     * Save filter state to localStorage
     */
    private function saveFilterState(filter: String): Void {
        LocalStorage.setString("todo_filter", filter);
        LocalStorage.setNumber("todo_filter_timestamp", Date.now().getTime());
    }
    
    /**
     * Restore filter state from localStorage
     */
    private function restoreFilterState(): Void {
        var savedFilter = LocalStorage.getString("todo_filter");
        var timestamp = LocalStorage.getNumber("todo_filter_timestamp");
        
        // Only restore if recent (within last hour)
        var now = Date.now().getTime();
        var maxAge = 60 * 60 * 1000; // 1 hour
        
        if (savedFilter != null && (now - timestamp) < maxAge) {
            // Set the saved filter if different from current
            var currentFilter = getCurrentFilter();
            if (currentFilter != savedFilter) {
                setFilter(savedFilter);
            }
        }
        
        // Restore search query
        var savedQuery = LocalStorage.getString("todo_search_query", "");
        var searchInput = el.querySelector("input[type='text']");
        if (searchInput != null && savedQuery != "") {
            var input: InputElement = cast searchInput;
            input.value = savedQuery;
        }
    }
    
    /**
     * Get current active filter
     */
    private function getCurrentFilter(): String {
        var activeButton = el.querySelector(".bg-blue-500, [data-active='true']");
        if (activeButton != null) {
            return activeButton.getAttribute("phx-value-filter") ?? "all";
        }
        return "all";
    }
    
    /**
     * Update active button styling
     */
    private function updateActiveButton(clickedButton: Element): Void {
        // Remove active styling from all buttons
        var allButtons = el.querySelectorAll("[phx-click='filter_todos']");
        for (i in 0...allButtons.length) {
            var button = allButtons[i];
            cast(button, js.html.Element).classList.remove("bg-blue-500", "text-white");
            cast(button, js.html.Element).classList.add("bg-white", "text-gray-700");
            cast(button, js.html.Element).setAttribute("data-active", "false");
        }
        
        // Add active styling to clicked button
        clickedButton.classList.remove("bg-white", "text-gray-700");
        clickedButton.classList.add("bg-blue-500", "text-white");
        clickedButton.setAttribute("data-active", "true");
    }
    
    /**
     * Update search placeholder based on current filter
     */
    private function updateSearchPlaceholder(input: InputElement): Void {
        var currentFilter = getCurrentFilter();
        var placeholders = [
            "all" => "Search all todos...",
            "active" => "Search active todos...",
            "completed" => "Search completed todos..."
        ];
        
        input.placeholder = placeholders[currentFilter] ?? "Search todos...";
    }
    
    /**
     * Check if this component is currently active/visible
     */
    private function isComponentActive(): Bool {
        return el.offsetParent != null; // Simple visibility check
    }
    
    /**
     * Update URL with search/filter state (if browser supports history API)
     */
    private function updateURL(query: String): Void {
        if (js.Browser.window.history != null && js.Browser.window.history.pushState != null) {
            try {
                var url = new js.html.URL(js.Browser.window.location.href);
                
                if (query != "") {
                    url.searchParams.set("search", query);
                } else {
                    url.searchParams.delete("search");
                }
                
                js.Browser.window.history.replaceState(null, "", url.href);
            } catch (e: Dynamic) {
                // Silently fail if URL manipulation is not supported
                trace('Could not update URL: $e');
            }
        }
    }
    
    /**
     * Push event to LiveView if available
     */
    private function pushEventIfAvailable(event: String, payload: Dynamic): Void {
        try {
            var pushEvent = Reflect.field(this, "pushEvent");
            if (pushEvent != null && Reflect.isFunction(pushEvent)) {
                pushEvent(event, payload);
            }
        } catch (e: Dynamic) {
            trace('Could not push event ${event}: ${e}');
        }
    }
}