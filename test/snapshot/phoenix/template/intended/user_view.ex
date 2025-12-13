defmodule UserView do
  use Phoenix.Component
  def user_card(user) do
    "<div class=\"user-card\">\n\t\t\t<h3><%= user.name %></h3>\n\t\t\t<p>Age: <%= user.age %></p>\n\t\t\t<p>Email: <%= user.email %></p>\n\t\t</div>"
  end
  def user_list(users) do
    "<div class=\"user-list\">\n\t\t\t<%= if length(users) == 0 do %>\n\t\t\t\t<p>No users found</p>\n\t\t\t<% else %>\n\t\t\t\t<ul>\n\t\t\t\t\t<%= for user <- users do %>\n\t\t\t\t\t\t<li><%= user.name %> (<%= user.email %>)</li>\n\t\t\t\t\t<% end %>\n\t\t\t\t</ul>\n\t\t\t<% end %>\n\t\t</div>"
  end
  def dashboard(assigns) do
    ~H"""
<div class="dashboard">
			<h1>Welcome, <%= @current_user.name %>!</h1>
			<div class="stats">
				<div>Posts: <%= @post_count %></div>
				<div>Comments: <%= @comment_count %></div>
				<div>Likes: <%= @like_count %></div>
			</div>
			<%= if @show_notifications do %>
				<div class="notifications">
					<%= Phoenix.HTML.raw(render_notifications(@notifications) ) %>
				</div>
			<% end %>
		</div>
"""
  end
  def button(text, type, disabled) do
    "<button class=\"btn btn-<%= type %>\" <%= if disabled do %>disabled<% end %>>\n\t\t\t<%= text %>\n\t\t</button>"
  end
  def user_form(changeset) do
    "<%= form_for(changeset, \"#\", fn f -> %>\n\t\t\t<div class=\"form-group\">\n\t\t\t\t<%= label(f, :name) %>\n\t\t\t\t<%= text_input(f, :name) %>\n\t\t\t\t<%= error_tag(f, :name) %>\n\t\t\t</div>\n\t\t\t\n\t\t\t<div class=\"form-group\">\n\t\t\t\t<%= label(f, :email) %>\n\t\t\t\t<%= email_input(f, :email) %>\n\t\t\t\t<%= error_tag(f, :email) %>\n\t\t\t</div>\n\t\t\t\n\t\t\t<div class=\"form-group\">\n\t\t\t\t<%= label(f, :age) %>\n\t\t\t\t<%= number_input(f, :age) %>\n\t\t\t\t<%= error_tag(f, :age) %>\n\t\t\t</div>\n\t\t\t\n\t\t\t<%= submit(\"Save\") %>\n\t\t<% end) %>"
  end
  def app_layout(inner_content, assigns) do
    ~H"""
<!DOCTYPE html>
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
		</html>
"""
  end
end
