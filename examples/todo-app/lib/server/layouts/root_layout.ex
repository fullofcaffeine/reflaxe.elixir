defmodule RootLayout do
  use Phoenix.Component

  @moduledoc """
    RootLayout module generated from Haxe

     * Root layout component for the Phoenix application
     * Handles HTML document structure, meta tags, and asset loading
     *
     * IMPORTANT: JavaScript Architecture Decision
     * =========================================
     *
     * This template deliberately avoids inline JavaScript code inside <script> tags.
     * Phoenix's HEEx parser treats JavaScript syntax (parentheses, quotes) as template
     * syntax, causing compilation errors like "expected closing `"` for attribute value".
     *
     * CORRECT PATTERN (This file):
     * - Reference external JavaScript files: <script src="/assets/app.js"></script>
     * - Keep templates clean with only HTML and Elixir interpolation
     * - Place all JavaScript logic in app.js or hook files
     *
     * INCORRECT PATTERN (Causes compilation errors):
     * - Inline JavaScript: <script>if (condition) { ... }</script>
     * - Complex JavaScript expressions in templates
     * - JavaScript variables and functions defined in HEEx
     *
     * Dark Mode Implementation:
     * - Theme detection/application: Handled by DarkMode.hx -> app.js
     * - Theme toggle button logic: Handled by ThemeToggle hook in client/hooks/
     * - Theme persistence: Handled by LocalStorage.hx utility
     *
     * This architecture ensures:
     * 1. Clean separation between templates and JavaScript
     * 2. No HEEx parser conflicts with JavaScript syntax
     * 3. Better maintainability and testability
     * 4. Proper Phoenix/LiveView best practices
     *
     * @see /src_haxe/client/utils/DarkMode.hx - Theme logic implementation
     * @see /src_haxe/client/hooks/ThemeToggle.hx - Theme toggle hook
     * @see /assets/js/app.js - Compiled JavaScript output
  """

  # Static functions
  @doc "Generated from Haxe render"
  def render(assigns) do
    ~H"""
      <!DOCTYPE html>
      <html lang="en" class="h-full">
      <head>
      <meta charset="utf-8"/>
      <meta http-equiv="X-UA-Compatible" content="IE=edge"/>
      <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
      <meta name="csrf-token" content={Component.get_csrf_token()}/>
      <title>Todo App - Haxe ❤️ Phoenix LiveView</title>
      <meta name="description" content="A beautiful todo application built with Haxe and Phoenix LiveView, showcasing modern UI and type-safe development"/>
      <!-- Favicon -->
      <link rel="icon" type="image/svg+xml" href="/images/favicon.svg">
      <!-- Preconnect to Google Fonts for performance -->
      <link rel="preconnect" href="https://fonts.googleapis.com">
      <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
      <!-- Inter font for modern typography -->
      <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
      <!-- Phoenix LiveView assets -->
      <script defer phx-track-static type="text/javascript" src="/assets/app.js"></script>
      <link phx-track-static rel="stylesheet" href="/assets/app.css"/>
      <!-- Dark mode detection handled by app.js -->
      </head>
      <body class="h-full bg-gray-50 dark:bg-gray-900 font-inter antialiased">
      <!-- Skip to main content for accessibility -->
      <a href="#main-content" class="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 bg-blue-600 text-white px-4 py-2 rounded-md">
      Skip to main content
      </a>
      <!-- Theme toggle button -->
      <div class="fixed top-4 right-4 z-50">
      <button
      id="theme-toggle"
      type="button"
      class="p-2 text-gray-500 dark:text-gray-400 hover:bg-gray-100 dark:hover:bg-gray-700 rounded-lg focus:outline-none focus:ring-2 focus:ring-gray-200 dark:focus:ring-gray-700 transition-colors"
      title="Toggle dark mode">
      <svg id="theme-toggle-dark-icon" class="hidden w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
      <path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"></path>
      </svg>
      <svg id="theme-toggle-light-icon" class="hidden w-5 h-5" fill="currentColor" viewBox="0 0 20 20">
      <path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 001.414-1.414l-.707-.707a1 1 0 00-1.414 1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 6.464A1 1 0 106.465 5.05l-.708-.707a1 1 0 00-1.414 1.414l.707.707zm1.414 8.486l-.707.707a1 1 0 01-1.414-1.414l.707-.707a1 1 0 011.414 1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z" fill-rule="evenodd" clip-rule="evenodd"></path>
      </svg>
      </button>
      </div>
      <!-- Main content -->
      <main id="main-content" class="h-full">
      <%= @inner_content %>
      </main>
      <!-- Dark mode toggle handled by app.js -->
      </body>
      </html>
      """
  end

end
