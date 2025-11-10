defmodule TodoAppWeb.Layouts do
  use Phoenix.Component
  use TodoAppWeb, :html
  def root(assigns) do
    ~H"""
<!DOCTYPE html>
<html lang="en" class="h-full">
    <head>
        <meta charset="utf-8"/>
        <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
        <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
        <title>Todo App</title>
        <meta name="csrf-token" content={Phoenix.Controller.get_csrf_token()}/>
        
        <!-- Static assets (served by Phoenix Endpoint) -->
        <link phx-track-static rel="stylesheet" href="/assets/app.css"/>
        <!-- Bundle that bootstraps LiveSocket and loads Haxe hooks -->
        <script defer phx-track-static type="text/javascript" src="/assets/phoenix_app.js"></script>
    </head>
    <body class="h-full bg-gray-50 dark:bg-gray-900 font-inter antialiased">
        <main id="main-content" class="h-full">
            <%= @inner_content %>
        </main>
    </body>
</html>
"""
  end
  def app(assigns) do
    ~H"""
<div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-blue-900">
    <div class="container mx-auto px-4 py-8 max-w-6xl">
        <%= @inner_content %>
    </div>
</div>
"""
  end
end
