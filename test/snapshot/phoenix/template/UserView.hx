package;

/**
 * Template compiler test case
 * Tests @:template and HEEx compilation
 */
@:template
class UserView {
	// Simple template function
	public static function userCard(user: Dynamic): String {
		return '<div class="user-card">
			<h3><%= user.name %></h3>
			<p>Age: <%= user.age %></p>
			<p>Email: <%= user.email %></p>
		</div>';
	}
	
	// Template with conditionals
	public static function userList(users: Array<Dynamic>): String {
		return '<div class="user-list">
			<%= if length(users) == 0 do %>
				<p>No users found</p>
			<% else %>
				<ul>
					<%= for user <- users do %>
						<li><%= user.name %> (<%= user.email %>)</li>
					<% end %>
				</ul>
			<% end %>
		</div>';
	}
	
	// Template with assigns
	public static function dashboard(assigns: Dynamic): String {
		return '<div class="dashboard">
			<h1>Welcome, <%= @current_user.name %>!</h1>
			<div class="stats">
				<div>Posts: <%= @post_count %></div>
				<div>Comments: <%= @comment_count %></div>
				<div>Likes: <%= @like_count %></div>
			</div>
			<%= if @show_notifications do %>
				<div class="notifications">
					<%= render_notifications(@notifications) %>
				</div>
			<% end %>
		</div>';
	}
	
	// Component template
	@:component
	public static function button(text: String, ?type: String = "primary", ?disabled: Bool = false): String {
		return '<button class="btn btn-<%= type %>" <%= if disabled do %>disabled<% end %>>
			<%= text %>
		</button>';
	}
	
	// Form template
	public static function userForm(changeset: Dynamic): String {
		return '<%= form_for(changeset, "#", fn f -> %>
			<div class="form-group">
				<%= label(f, :name) %>
				<%= text_input(f, :name) %>
				<%= error_tag(f, :name) %>
			</div>
			
			<div class="form-group">
				<%= label(f, :email) %>
				<%= email_input(f, :email) %>
				<%= error_tag(f, :email) %>
			</div>
			
			<div class="form-group">
				<%= label(f, :age) %>
				<%= number_input(f, :age) %>
				<%= error_tag(f, :age) %>
			</div>
			
			<%= submit("Save") %>
		<% end) %>';
	}
	
	// Layout template
	@:layout
	public static function appLayout(inner_content: String, assigns: Dynamic): String {
		return '<!DOCTYPE html>
		<html>
			<head>
				<title><%= @page_title %></title>
				<link rel="stylesheet" href="/css/app.css">
			</head>
			<body>
				<header>
					<nav>
						<%= link("Home", to: "/") %>
						<%= link("Users", to: "/users") %>
						<%= if @current_user do %>
							<%= link("Profile", to: "/profile") %>
							<%= link("Logout", to: "/logout", method: :delete) %>
						<% else %>
							<%= link("Login", to: "/login") %>
						<% end %>
					</nav>
				</header>
				
				<main>
					<%= inner_content %>
				</main>
				
				<footer>
					<p>&copy; 2024 MyApp</p>
				</footer>
			</body>
		</html>';
	}
}