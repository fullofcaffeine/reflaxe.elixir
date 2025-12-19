defmodule MyAppWeb.Layouts do
  use Phoenix.Component
  use MyAppWeb, :html
  def root(assigns) do
    ~H"""
<!DOCTYPE html>
<html>
<head>
    <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()}/>
</head>
<body>
    <%= @inner_content %>
</body>
</html>
"""
  end
end
