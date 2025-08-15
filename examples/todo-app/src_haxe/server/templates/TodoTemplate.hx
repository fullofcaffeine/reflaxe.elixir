package templates;

import reflaxe.elixir.HXX;

/**
 * Todo LiveView template using proper HXX inline syntax
 * This demonstrates the correct way to use HXX - inline with HXX.hxx() calls
 */
class TodoTemplate {
    
    /**
     * Main todo app template with modern UI design
     */
    public static function render(): String {
        return HXX.hxx('
            <div class="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 dark:from-gray-900 dark:to-blue-900">
                <div class="container mx-auto px-4 py-8 max-w-4xl">
                    
                    <!-- Header -->
                    <header class="text-center mb-8">
                        <h1 class="text-4xl font-bold text-gray-800 dark:text-white mb-2">
                            📝 Todo App
                        </h1>
                        <p class="text-gray-600 dark:text-gray-300">
                            Built with Haxe → Elixir + Phoenix LiveView
                        </p>
                        <div class="mt-4 inline-flex items-center px-3 py-1 rounded-full bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                            <span class="w-2 h-2 bg-green-500 rounded-full mr-2 animate-pulse"></span>
                            👤 ${@current_user.name}
                        </div>
                    </header>
                    
                    <!-- Statistics Cards -->
                    <div class="grid grid-cols-1 md:grid-cols-3 gap-4 mb-8">
                        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 border-l-4 border-blue-500">
                            <div class="flex items-center">
                                <div class="flex-1">
                                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Total Todos</h3>
                                    <p class="text-2xl font-bold text-gray-900 dark:text-white">${@total_todos}</p>
                                </div>
                                <div class="text-blue-500 text-2xl">📊</div>
                            </div>
                        </div>
                        
                        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 border-l-4 border-yellow-500">
                            <div class="flex items-center">
                                <div class="flex-1">
                                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Pending</h3>
                                    <p class="text-2xl font-bold text-yellow-600 dark:text-yellow-400">${@pending_todos}</p>
                                </div>
                                <div class="text-yellow-500 text-2xl">⏳</div>
                            </div>
                        </div>
                        
                        <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 border-l-4 border-green-500">
                            <div class="flex items-center">
                                <div class="flex-1">
                                    <h3 class="text-sm font-medium text-gray-500 dark:text-gray-400">Completed</h3>
                                    <p class="text-2xl font-bold text-green-600 dark:text-green-400">${@completed_todos}</p>
                                </div>
                                <div class="text-green-500 text-2xl">✅</div>
                            </div>
                        </div>
                    </div>
                    
                    <!-- Controls Panel -->
                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 mb-8">
                        <div class="flex flex-wrap items-center gap-4">
                            
                            <!-- New Todo Button -->
                            <button 
                                phx-click="toggle_form" 
                                class="inline-flex items-center px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                <span class="mr-2">${@show_form ? "❌" : "➕"}</span>
                                ${@show_form ? "Cancel" : "New Todo"}
                            </button>
                            
                            <!-- Filter Buttons -->
                            <div class="flex rounded-lg border border-gray-300 dark:border-gray-600 overflow-hidden">
                                <button 
                                    phx-click="filter_todos" 
                                    phx-value-filter="all"
                                    class="${@filter == "all" ? "bg-blue-500 text-white" : "bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300"} px-4 py-2 text-sm font-medium hover:bg-blue-100 dark:hover:bg-gray-600 transition-colors">
                                    All
                                </button>
                                <button 
                                    phx-click="filter_todos" 
                                    phx-value-filter="active"
                                    class="${@filter == "active" ? "bg-blue-500 text-white" : "bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300"} px-4 py-2 text-sm font-medium border-l border-gray-300 dark:border-gray-600 hover:bg-blue-100 dark:hover:bg-gray-600 transition-colors">
                                    Active
                                </button>
                                <button 
                                    phx-click="filter_todos" 
                                    phx-value-filter="completed"
                                    class="${@filter == "completed" ? "bg-blue-500 text-white" : "bg-white dark:bg-gray-700 text-gray-700 dark:text-gray-300"} px-4 py-2 text-sm font-medium border-l border-gray-300 dark:border-gray-600 hover:bg-blue-100 dark:hover:bg-gray-600 transition-colors">
                                    Completed
                                </button>
                            </div>
                            
                            <!-- Search Bar -->
                            <div class="flex-1 min-w-64">
                                <div class="relative">
                                    <input 
                                        type="text"
                                        phx-keyup="search_todos"
                                        phx-debounce="300"
                                        placeholder="Search todos..."
                                        value="${@search_query}"
                                        class="w-full pl-10 pr-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400" />
                                    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
                                        <span class="text-gray-400">🔍</span>
                                    </div>
                                </div>
                            </div>
                            
                            <!-- Sort Dropdown -->
                            <select 
                                phx-change="sort_todos" 
                                name="sort_by"
                                class="px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white">
                                <option value="created" ${@sort_by == "created" ? "selected" : ""}>📅 Date Created</option>
                                <option value="priority" ${@sort_by == "priority" ? "selected" : ""}>⚡ Priority</option>
                                <option value="due_date" ${@sort_by == "due_date" ? "selected" : ""}>⏰ Due Date</option>
                            </select>
                            
                        </div>
                    </div>
                    
                    ${renderNewTodoForm()}
                    ${renderTodoList()}
                    
                </div>
            </div>
        ');
    }
    
    /**
     * New todo form component
     */
    public static function renderNewTodoForm(): String {
        return HXX.hxx('
            <%= if @show_form do %>
                <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6 mb-8 border-l-4 border-blue-500">
                    <h3 class="text-lg font-semibold text-gray-800 dark:text-white mb-4">✨ Create New Todo</h3>
                    
                    <form phx-submit="create_todo" class="space-y-4">
                        
                        <!-- Title Input -->
                        <div>
                            <label for="title" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Title *
                            </label>
                            <input 
                                type="text"
                                name="title"
                                id="title"
                                placeholder="What needs to be done?"
                                required
                                class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400"
                                phx-hook="AutoFocus" />
                        </div>
                        
                        <!-- Description Input -->
                        <div>
                            <label for="description" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                Description
                            </label>
                            <textarea 
                                name="description"
                                id="description"
                                placeholder="Add more details (optional)"
                                rows="3"
                                class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400"></textarea>
                        </div>
                        
                        <!-- Priority and Due Date Row -->
                        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
                            
                            <!-- Priority Select -->
                            <div>
                                <label for="priority" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                    Priority
                                </label>
                                <select 
                                    name="priority"
                                    id="priority"
                                    class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white">
                                    <option value="low">🟢 Low Priority</option>
                                    <option value="medium" selected>🟡 Medium Priority</option>
                                    <option value="high">🔴 High Priority</option>
                                </select>
                            </div>
                            
                            <!-- Due Date Input -->
                            <div>
                                <label for="due_date" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                    Due Date
                                </label>
                                <input 
                                    type="date"
                                    name="due_date"
                                    id="due_date"
                                    class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white" />
                            </div>
                            
                            <!-- Tags Input -->
                            <div>
                                <label for="tags" class="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
                                    Tags
                                </label>
                                <input 
                                    type="text"
                                    name="tags"
                                    id="tags"
                                    placeholder="work, personal, urgent"
                                    class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white dark:placeholder-gray-400" />
                            </div>
                            
                        </div>
                        
                        <!-- Submit Buttons -->
                        <div class="flex justify-end space-x-3 pt-4">
                            <button 
                                type="button"
                                phx-click="toggle_form"
                                class="px-4 py-2 text-gray-700 dark:text-gray-300 bg-gray-100 dark:bg-gray-700 hover:bg-gray-200 dark:hover:bg-gray-600 rounded-lg transition-colors duration-200">
                                Cancel
                            </button>
                            <button 
                                type="submit"
                                class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white font-medium rounded-lg transition-colors duration-200 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2">
                                ✨ Create Todo
                            </button>
                        </div>
                        
                    </form>
                </div>
            <% end %>
        ');
    }
    
    /**
     * Todo list component with modern card design
     */
    public static function renderTodoList(): String {
        return HXX.hxx('
            <div class="space-y-4">
                
                <!-- Bulk Actions -->
                <%= if length(@todos) > 0 do %>
                    <div class="flex justify-between items-center">
                        <h2 class="text-xl font-semibold text-gray-800 dark:text-white">Your Todos</h2>
                        <div class="flex space-x-2">
                            <button 
                                phx-click="bulk_complete"
                                class="inline-flex items-center px-3 py-1 text-sm bg-green-100 hover:bg-green-200 text-green-800 rounded-lg transition-colors">
                                <span class="mr-1">✅</span>
                                Complete All
                            </button>
                            <button 
                                phx-click="bulk_delete_completed"
                                data-confirm="Delete all completed todos?"
                                class="inline-flex items-center px-3 py-1 text-sm bg-red-100 hover:bg-red-200 text-red-800 rounded-lg transition-colors">
                                <span class="mr-1">🗑️</span>
                                Clear Completed
                            </button>
                        </div>
                    </div>
                <% end %>
                
                <!-- Todo Items -->
                <%= for todo <- filter_and_sort_todos(@todos, @filter, @sort_by, @search_query) do %>
                    <div class="bg-white dark:bg-gray-800 rounded-lg shadow-md hover:shadow-lg transition-shadow duration-200 border-l-4 ${getPriorityBorderColor(todo.priority)}">
                        
                        <%= if @editing_todo && @editing_todo.id == todo.id do %>
                            ${renderEditForm(todo)}
                        <% else %>
                            ${renderTodoItem(todo)}
                        <% end %>
                        
                    </div>
                <% end %>
                
                <!-- Empty State -->
                <%= if length(filter_and_sort_todos(@todos, @filter, @sort_by, @search_query)) == 0 do %>
                    <div class="text-center py-12">
                        <div class="text-6xl mb-4">📝</div>
                        <h3 class="text-xl font-medium text-gray-500 dark:text-gray-400 mb-2">
                            ${getEmptyStateMessage(@filter, @search_query)}
                        </h3>
                        <p class="text-gray-400 dark:text-gray-500">
                            ${getEmptyStateSubtext(@filter, @search_query)}
                        </p>
                    </div>
                <% end %>
                
            </div>
        ');
    }
    
    /**
     * Individual todo item component
     */
    public static function renderTodoItem(todo: Dynamic): String {
        return HXX.hxx('
            <div class="p-6">
                <div class="flex items-start space-x-4">
                    
                    <!-- Checkbox -->
                    <button 
                        phx-click="toggle_todo"
                        phx-value-id="${todo.id}"
                        class="flex-shrink-0 w-6 h-6 rounded-full border-2 ${todo.completed ? "bg-green-500 border-green-500" : "border-gray-300 dark:border-gray-600"} hover:border-green-400 transition-colors duration-200 flex items-center justify-center">
                        ${todo.completed ? "✓" : ""}
                    </button>
                    
                    <!-- Todo Content -->
                    <div class="flex-1 min-w-0">
                        <h4 class="${todo.completed ? "line-through text-gray-500 dark:text-gray-400" : "text-gray-900 dark:text-white"} font-medium text-lg">
                            ${todo.title}
                        </h4>
                        
                        <%= if todo.description do %>
                            <p class="text-gray-600 dark:text-gray-300 mt-1 text-sm">
                                ${todo.description}
                            </p>
                        <% end %>
                        
                        <!-- Meta Information -->
                        <div class="flex items-center space-x-4 mt-3 text-sm text-gray-500 dark:text-gray-400">
                            
                            <!-- Priority Badge -->
                            <span class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium ${getPriorityClasses(todo.priority)}">
                                ${getPriorityIcon(todo.priority)} ${String.toUpperCase(todo.priority)}
                            </span>
                            
                            <!-- Due Date -->
                            <%= if todo.due_date do %>
                                <span class="inline-flex items-center">
                                    <span class="mr-1">📅</span>
                                    ${formatDate(todo.due_date)}
                                </span>
                            <% end %>
                            
                            <!-- Tags -->
                            <%= if todo.tags do %>
                                <div class="flex flex-wrap gap-1">
                                    <%= for tag <- String.split(todo.tags, ",") do %>
                                        <span class="inline-flex items-center px-2 py-1 rounded-full text-xs bg-blue-100 dark:bg-blue-900 text-blue-800 dark:text-blue-200">
                                            #${String.trim(tag)}
                                        </span>
                                    <% end %>
                                </div>
                            <% end %>
                            
                        </div>
                    </div>
                    
                    <!-- Action Buttons -->
                    <div class="flex-shrink-0 flex items-center space-x-2">
                        
                        <!-- Priority Quick Change -->
                        <select 
                            phx-change="set_priority"
                            phx-value-id="${todo.id}"
                            name="priority"
                            class="text-sm border-0 bg-transparent focus:ring-2 focus:ring-blue-500 rounded">
                            <option value="low" ${todo.priority == "low" ? "selected" : ""}>🟢</option>
                            <option value="medium" ${todo.priority == "medium" ? "selected" : ""}>🟡</option>
                            <option value="high" ${todo.priority == "high" ? "selected" : ""}>🔴</option>
                        </select>
                        
                        <!-- Edit Button -->
                        <button 
                            phx-click="edit_todo"
                            phx-value-id="${todo.id}"
                            class="p-2 text-blue-600 hover:text-blue-800 hover:bg-blue-50 dark:hover:bg-blue-900 rounded-lg transition-colors"
                            title="Edit todo">
                            ✏️
                        </button>
                        
                        <!-- Delete Button -->
                        <button 
                            phx-click="delete_todo"
                            phx-value-id="${todo.id}"
                            data-confirm="Delete this todo?"
                            class="p-2 text-red-600 hover:text-red-800 hover:bg-red-50 dark:hover:bg-red-900 rounded-lg transition-colors"
                            title="Delete todo">
                            🗑️
                        </button>
                        
                    </div>
                    
                </div>
            </div>
        ');
    }
    
    /**
     * Edit form for todo items
     */
    public static function renderEditForm(todo: Dynamic): String {
        return HXX.hxx('
            <div class="p-6 bg-blue-50 dark:bg-blue-900">
                <form phx-submit="save_todo" class="space-y-4">
                    <input type="hidden" name="id" value="${todo.id}" />
                    
                    <!-- Edit Title -->
                    <div>
                        <input 
                            type="text"
                            name="title"
                            value="${todo.title}"
                            placeholder="Todo title"
                            required
                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
                            phx-hook="AutoFocus" />
                    </div>
                    
                    <!-- Edit Description -->
                    <div>
                        <textarea 
                            name="description"
                            placeholder="Description (optional)"
                            rows="2"
                            class="w-full px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white">${todo.description || ""}</textarea>
                    </div>
                    
                    <!-- Edit Form Actions -->
                    <div class="flex justify-end space-x-3">
                        <button 
                            type="button"
                            phx-click="cancel_edit"
                            class="px-4 py-2 text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 border border-gray-300 dark:border-gray-600 rounded-lg transition-colors">
                            Cancel
                        </button>
                        <button 
                            type="submit"
                            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg transition-colors">
                            💾 Save
                        </button>
                    </div>
                </form>
            </div>
        ');
    }
    
    // Helper functions that would be implemented in the LiveView module
    public static function filter_and_sort_todos(todos: Array<Dynamic>, filter: String, sort_by: String, search_query: String): Array<Dynamic> {
        return todos; // Implementation in LiveView
    }
    
    public static function getPriorityBorderColor(priority: String): String {
        return switch (priority) {
            case "high": "border-red-500";
            case "medium": "border-yellow-500";
            case "low": "border-green-500";
            case _: "border-gray-300";
        };
    }
    
    public static function getPriorityClasses(priority: String): String {
        return switch (priority) {
            case "high": "bg-red-100 text-red-800 dark:bg-red-900 dark:text-red-200";
            case "medium": "bg-yellow-100 text-yellow-800 dark:bg-yellow-900 dark:text-yellow-200";
            case "low": "bg-green-100 text-green-800 dark:bg-green-900 dark:text-green-200";
            case _: "bg-gray-100 text-gray-800 dark:bg-gray-900 dark:text-gray-200";
        };
    }
    
    public static function getPriorityIcon(priority: String): String {
        return switch (priority) {
            case "high": "🔴";
            case "medium": "🟡";
            case "low": "🟢";
            case _: "⚪";
        };
    }
    
    public static function formatDate(date: String): String {
        return date; // Would implement proper date formatting
    }
    
    public static function getEmptyStateMessage(filter: String, search_query: String): String {
        if (search_query != "") {
            return "No todos found";
        }
        return switch (filter) {
            case "active": "No active todos";
            case "completed": "No completed todos";
            case _: "No todos yet";
        };
    }
    
    public static function getEmptyStateSubtext(filter: String, search_query: String): String {
        if (search_query != "") {
            return "Try a different search term";
        }
        return switch (filter) {
            case "active": "All todos are completed! 🎉";
            case "completed": "Complete some todos to see them here";
            case _: "Create your first todo to get started";
        };
    }
}