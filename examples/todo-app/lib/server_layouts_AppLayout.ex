defmodule AppLayout do
  use Phoenix.Component

  @moduledoc """
    AppLayout module generated from Haxe

     * Application layout component
     * Provides the main container and navigation structure for the app
  """

  # Static functions
  @doc """
    Main application wrapper template
    Includes navigation, breadcrumbs, and content area
  """
  @spec render(term()) :: String.t()
  def render(assigns) do
    ~H"""
      <div class="min-h-screen bg-gradient-to-br from-blue-50 via-white to-indigo-50 dark:from-gray-900 dark:via-gray-800 dark:to-blue-900">
      <!-- Header Navigation -->
      <header class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm border-b border-gray-200 dark:border-gray-700 sticky top-0 z-40">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex justify-between items-center h-16">
      <!-- Logo and App Name -->
      <div class="flex items-center space-x-4">
      <div class="flex-shrink-0">
      <div class="w-8 h-8 bg-gradient-to-br from-blue-500 to-indigo-600 rounded-lg flex items-center justify-center">
      <span class="text-white font-bold text-sm">📝</span>
      </div>
      </div>
      <div>
      <h1 class="text-xl font-bold text-gray-900 dark:text-white">
      Todo App
      </h1>
      <p class="text-xs text-gray-500 dark:text-gray-400">
      Haxe ❤️ Phoenix LiveView
      </p>
      </div>
      </div>
      <!-- Navigation Links -->
      <nav class="hidden md:flex space-x-8">
      <a href="/" class="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors font-medium">
      Dashboard
      </a>
      <a href="/todos" class="text-blue-600 dark:text-blue-400 font-medium">
      Todos
      </a>
      <a href="/profile" class="text-gray-600 dark:text-gray-300 hover:text-blue-600 dark:hover:text-blue-400 transition-colors font-medium">
      Profile
      </a>
      </nav>
      <!-- User Menu -->
      <div class="flex items-center space-x-4">
      <div class="text-sm text-gray-700 dark:text-gray-300">
      Welcome, <span class="font-semibold"><%= get_user_display_name(assigns.current_user) %></span>
      </div>
      <div class="w-8 h-8 bg-gradient-to-br from-purple-500 to-pink-500 rounded-full flex items-center justify-center">
      <span class="text-white text-sm font-medium">
      <%= get_initials(get_user_display_name(assigns.current_user)) %>
      </span>
      </div>
      </div>
      </div>
      </div>
      </header>
      <!-- Breadcrumbs -->
      <nav class="bg-white/60 dark:bg-gray-800/60 backdrop-blur-sm border-b border-gray-100 dark:border-gray-700" aria-label="Breadcrumb">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
      <div class="flex items-center space-x-4 h-12 text-sm">
      <a href="/" class="text-gray-500 dark:text-gray-400 hover:text-gray-700 dark:hover:text-gray-300">
      🏠 Home
      </a>
      <span class="text-gray-400 dark:text-gray-500">/</span>
      <span class="text-gray-900 dark:text-white font-medium">
      <%= get_page_title(assigns.page_title) %>
      </span>
      </div>
      </div>
      </nav>
      <!-- Main Content Area -->
      <main class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-8">
      <!-- Page Header -->
      <div class="mb-8">
      <div class="md:flex md:items-center md:justify-between">
      <div class="flex-1 min-w-0">
      <h2 class="text-2xl font-bold leading-7 text-gray-900 dark:text-white sm:text-3xl sm:truncate">
      <%= get_page_title(assigns.page_title) %>
      </h2>
      <div class="mt-1 flex flex-col sm:flex-row sm:flex-wrap sm:mt-0 sm:space-x-6">
      <div class="mt-2 flex items-center text-sm text-gray-500 dark:text-gray-400">
      <span class="mr-2">🕒</span>
      Last updated: <%= format_timestamp(get_last_updated(assigns.last_updated)) %>
      </div>
      <div class="mt-2 flex items-center text-sm text-gray-500 dark:text-gray-400">
      <span class="mr-2">⚡</span>
      Real-time sync enabled
      </div>
      </div>
      </div>
      <!-- Quick Actions -->
      <div class="mt-4 flex md:mt-0 md:ml-4 space-x-2">
      <button type="button" class="inline-flex items-center px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm text-sm font-medium text-gray-700 dark:text-gray-300 bg-white dark:bg-gray-700 hover:bg-gray-50 dark:hover:bg-gray-600 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors">
      📊 Stats
      </button>
      <button type="button" class="inline-flex items-center px-3 py-2 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors">
      ➕ New Todo
      </button>
      </div>
      </div>
      </div>
      <!-- Content -->
      <div class="space-y-6">
      <%= @inner_content %>
      </div>
      </main>
      <!-- Footer -->
      <footer class="bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm border-t border-gray-200 dark:border-gray-700 mt-auto">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6">
      <div class="flex justify-between items-center">
      <div class="text-sm text-gray-500 dark:text-gray-400">
      Built with ❤️ using Haxe and Phoenix LiveView
      </div>
      <div class="flex space-x-6 text-sm text-gray-500 dark:text-gray-400">
      <a href="/about" class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors">About</a>
      <a href="/help" class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors">Help</a>
      <a href="https://github.com/reflaxe/elixir" class="hover:text-gray-700 dark:hover:text-gray-300 transition-colors">GitHub</a>
      </div>
      </div>
      </div>
      </footer>
      </div>
      """
  end

  @doc """
    Get user display name with fallback

  """
  @spec get_user_display_name(Null.t()) :: String.t()
  def get_user_display_name(user) do
    if (user != nil && user.name != nil), do: user.name, else: nil
    "User"
  end

  @doc """
    Get page title with fallback

  """
  @spec get_page_title(Null.t()) :: String.t()
  def get_page_title(title) do
    if (title != nil), do: title, else: nil
    "Todo Dashboard"
  end

  @doc """
    Get last updated timestamp with fallback

  """
  @spec get_last_updated(Null.t()) :: String.t()
  def get_last_updated(timestamp) do
    if (timestamp != nil), do: timestamp, else: nil
    "now"
  end

  @doc """
    Get user initials for avatar

  """
  @spec get_initials(String.t()) :: String.t()
  def get_initials(name) do
    if (name == nil || name == ""), do: "U", else: nil
    parts = String.split(name, " ")
    if (length(parts) >= 2), do: String.upcase(String.at(Enum.at(parts, 0), 0)) <> String.upcase(String.at(Enum.at(parts, 1), 0)), else: nil
    String.upcase(String.at(name, 0))
  end

  @doc """
    Format timestamp for display

  """
  @spec format_timestamp(String.t()) :: String.t()
  def format_timestamp(timestamp) do
    timestamp
  end

end
