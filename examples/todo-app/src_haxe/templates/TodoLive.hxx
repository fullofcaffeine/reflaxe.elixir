@:template
class TodoLiveTemplate {
	public static function render(): String {
		return '
<div class="todo-app">
	<header class="todo-header">
		<h1>📝 Todo App</h1>
		<div class="user-info">
			👤 <%= @current_user.name %>
		</div>
	</header>
	
	<!-- Statistics -->
	<div class="stats-bar">
		<div class="stat">
			<span class="stat-label">Total:</span>
			<span class="stat-value"><%= @total_todos %></span>
		</div>
		<div class="stat">
			<span class="stat-label">Pending:</span>
			<span class="stat-value pending"><%= @pending_todos %></span>
		</div>
		<div class="stat">
			<span class="stat-label">Completed:</span>
			<span class="stat-value completed"><%= @completed_todos %></span>
		</div>
	</div>
	
	<!-- Controls Bar -->
	<div class="controls-bar">
		<button phx-click="toggle_form" class="btn btn-primary">
			<%= if @show_form, do: "Hide Form", else: "+ New Todo" %>
		</button>
		
		<div class="filter-controls">
			<button phx-click="filter_todos" phx-value-filter="all" 
					class={"filter-btn": true, active: @filter == "all"}>
				All
			</button>
			<button phx-click="filter_todos" phx-value-filter="active"
					class={"filter-btn": true, active: @filter == "active"}>
				Active
			</button>
			<button phx-click="filter_todos" phx-value-filter="completed"
					class={"filter-btn": true, active: @filter == "completed"}>
				Completed
			</button>
		</div>
		
		<div class="sort-controls">
			<select phx-change="sort_todos" name="sort_by">
				<option value="created" selected={@sort_by == "created"}>Date Created</option>
				<option value="priority" selected={@sort_by == "priority"}>Priority</option>
				<option value="due_date" selected={@sort_by == "due_date"}>Due Date</option>
			</select>
		</div>
		
		<div class="search-bar">
			<input type="text" 
				   phx-keyup="search_todos" 
				   phx-debounce="300"
				   placeholder="Search todos..."
				   value={@search_query} />
		</div>
	</div>
	
	<!-- New Todo Form -->
	<%= if @show_form do %>
	<div class="todo-form">
		<form phx-submit="create_todo">
			<div class="form-row">
				<input type="text" 
					   name="title" 
					   placeholder="What needs to be done?"
					   required
					   class="form-input" />
			</div>
			
			<div class="form-row">
				<textarea name="description" 
						  placeholder="Description (optional)"
						  rows="3"
						  class="form-input"></textarea>
			</div>
			
			<div class="form-row form-row-multi">
				<select name="priority" class="form-select">
					<option value="low">🟢 Low Priority</option>
					<option value="medium" selected>🟡 Medium Priority</option>
					<option value="high">🔴 High Priority</option>
				</select>
				
				<input type="date" 
					   name="due_date"
					   class="form-input" />
				
				<input type="text"
					   name="tags"
					   placeholder="Tags (comma separated)"
					   class="form-input" />
			</div>
			
			<div class="form-actions">
				<button type="submit" class="btn btn-success">Create Todo</button>
				<button type="button" phx-click="toggle_form" class="btn btn-cancel">Cancel</button>
			</div>
		</form>
	</div>
	<% end %>
	
	<!-- Bulk Actions -->
	<%= if @pending_todos > 0 || @completed_todos > 0 do %>
	<div class="bulk-actions">
		<%= if @pending_todos > 0 do %>
			<button phx-click="bulk_complete" class="btn btn-sm">
				✅ Complete All
			</button>
		<% end %>
		
		<%= if @completed_todos > 0 do %>
			<button phx-click="bulk_delete_completed" 
					class="btn btn-sm btn-danger"
					data-confirm="Delete all completed todos?">
				🗑️ Clear Completed
			</button>
		<% end %>
	</div>
	<% end %>
	
	<!-- Todo List -->
	<div class="todo-list">
		<%= for todo <- filter_and_sort_todos(@todos, @filter, @sort_by, @search_query) do %>
			<div class={"todo-item": true, completed: todo.completed, editing: @editing_todo && @editing_todo.id == todo.id}>
				
				<%= if @editing_todo && @editing_todo.id == todo.id do %>
					<!-- Edit Mode -->
					<form phx-submit="save_todo" class="edit-form">
						<input type="hidden" name="id" value={todo.id} />
						<input type="text" 
							   name="title" 
							   value={todo.title}
							   class="edit-input" />
						<textarea name="description"
								  class="edit-input">{todo.description}</textarea>
						<div class="edit-actions">
							<button type="submit" class="btn btn-sm btn-success">Save</button>
							<button type="button" phx-click="cancel_edit" class="btn btn-sm">Cancel</button>
						</div>
					</form>
				<% else %>
					<!-- View Mode -->
					<div class="todo-content">
						<input type="checkbox" 
							   phx-click="toggle_todo" 
							   phx-value-id={todo.id}
							   checked={todo.completed} />
						
						<div class="todo-details">
							<h3 class="todo-title">{todo.title}</h3>
							
							<%= if todo.description do %>
								<p class="todo-description">{todo.description}</p>
							<% end %>
							
							<div class="todo-meta">
								<span class={"priority-badge priority-" <> todo.priority}>
									{String.capitalize(todo.priority)}
								</span>
								
								<%= if todo.due_date do %>
									<span class="due-date">
										📅 {format_date(todo.due_date)}
									</span>
								<% end %>
								
								<%= for tag <- todo.tags || [] do %>
									<span class="tag" 
										  phx-click="toggle_tag" 
										  phx-value-tag={tag}>
										#{tag}
									</span>
								<% end %>
							</div>
						</div>
						
						<div class="todo-actions">
							<select phx-change="set_priority" 
									phx-value-id={todo.id}
									name="priority"
									class="priority-select">
								<option value="low" selected={todo.priority == "low"}>🟢</option>
								<option value="medium" selected={todo.priority == "medium"}>🟡</option>
								<option value="high" selected={todo.priority == "high"}>🔴</option>
							</select>
							
							<button phx-click="edit_todo" 
									phx-value-id={todo.id}
									class="btn-icon">
								✏️
							</button>
							
							<button phx-click="delete_todo" 
									phx-value-id={todo.id}
									data-confirm="Delete this todo?"
									class="btn-icon btn-danger">
								🗑️
							</button>
						</div>
					</div>
				<% end %>
			</div>
		<% end %>
		
		<%= if length(filter_and_sort_todos(@todos, @filter, @sort_by, @search_query)) == 0 do %>
			<div class="empty-state">
				<p>No todos found. Create your first todo!</p>
			</div>
		<% end %>
	</div>
</div>
		';
	}
	
	// Helper function for filtering and sorting
	public static function filter_and_sort_todos(todos, filter, sort_by, search_query) {
		// This would be implemented in the LiveView module
		return todos;
	}
	
	public static function format_date(date) {
		// Date formatting helper
		return date;
	}
}