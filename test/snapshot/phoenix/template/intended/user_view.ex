defmodule UserView do
  def user_card(_user) do
    "<div class=\"user-card\">\n\t\t\t<h3><%= user.name %></h3>\n\t\t\t<p>Age: <%= user.age %></p>\n\t\t\t<p>Email: <%= user.email %></p>\n\t\t</div>"
  end
  def user_list(_users) do
    "<div class=\"user-list\">\n\t\t\t<%= if length(users) == 0 do %>\n\t\t\t\t<p>No users found</p>\n\t\t\t<% else %>\n\t\t\t\t<ul>\n\t\t\t\t\t<%= for user <- users do %>\n\t\t\t\t\t\t<li><%= user.name %> (<%= user.email %>)</li>\n\t\t\t\t\t<% end %>\n\t\t\t\t</ul>\n\t\t\t<% end %>\n\t\t</div>"
  end
  def dashboard(_assigns) do
    "<div class=\"dashboard\">\n\t\t\t<h1>Welcome, <%= @current_user.name %>!</h1>\n\t\t\t<div class=\"stats\">\n\t\t\t\t<div>Posts: <%= @post_count %></div>\n\t\t\t\t<div>Comments: <%= @comment_count %></div>\n\t\t\t\t<div>Likes: <%= @like_count %></div>\n\t\t\t</div>\n\t\t\t<%= if @show_notifications do %>\n\t\t\t\t<div class=\"notifications\">\n\t\t\t\t\t<%= render_notifications(@notifications) %>\n\t\t\t\t</div>\n\t\t\t<% end %>\n\t\t</div>"
  end
  def button(_text, _type, _disabled) do
    "<button class=\"btn btn-<%= type %>\" <%= if disabled do %>disabled<% end %>>\n\t\t\t<%= text %>\n\t\t</button>"
  end
  def user_form(_changeset) do
    "<%= form_for(changeset, \"#\", fn f -> %>\n\t\t\t<div class=\"form-group\">\n\t\t\t\t<%= label(f, :name) %>\n\t\t\t\t<%= text_input(f, :name) %>\n\t\t\t\t<%= error_tag(f, :name) %>\n\t\t\t</div>\n\t\t\t\n\t\t\t<div class=\"form-group\">\n\t\t\t\t<%= label(f, :email) %>\n\t\t\t\t<%= email_input(f, :email) %>\n\t\t\t\t<%= error_tag(f, :email) %>\n\t\t\t</div>\n\t\t\t\n\t\t\t<div class=\"form-group\">\n\t\t\t\t<%= label(f, :age) %>\n\t\t\t\t<%= number_input(f, :age) %>\n\t\t\t\t<%= error_tag(f, :age) %>\n\t\t\t</div>\n\t\t\t\n\t\t\t<%= submit(\"Save\") %>\n\t\t<% end) %>"
  end
  def app_layout(_inner_content, _assigns) do
    "<!DOCTYPE html>\n\t\t<html>\n\t\t\t<head>\n\t\t\t\t<title><%= @page_title %></title>\n\t\t\t\t<link rel=\"stylesheet\" href=\"/css/app.css\">\n\t\t\t</head>\n\t\t\t<body>\n\t\t\t\t<header>\n\t\t\t\t\t<nav>\n\t\t\t\t\t\t<%= link(\"Home\", to: \"/\") %>\n\t\t\t\t\t\t<%= link(\"Users\", to: \"/users\") %>\n\t\t\t\t\t\t<%= if @current_user do %>\n\t\t\t\t\t\t\t<%= link(\"Profile\", to: \"/profile\") %>\n\t\t\t\t\t\t\t<%= link(\"Logout\", to: \"/logout\", method: :delete) %>\n\t\t\t\t\t\t<% else %>\n\t\t\t\t\t\t\t<%= link(\"Login\", to: \"/login\") %>\n\t\t\t\t\t\t<% end %>\n\t\t\t\t\t</nav>\n\t\t\t\t</header>\n\t\t\t\t\n\t\t\t\t<main>\n\t\t\t\t\t<%= inner_content %>\n\t\t\t\t</main>\n\t\t\t\t\n\t\t\t\t<footer>\n\t\t\t\t\t<p>&copy; 2024 MyApp</p>\n\t\t\t\t</footer>\n\t\t\t</body>\n\t\t</html>"
  end
end