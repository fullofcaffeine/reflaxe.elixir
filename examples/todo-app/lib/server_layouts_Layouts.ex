defmodule TodoAppWeb.Layouts do
  @moduledoc """
  TodoAppWeb.Layouts module generated from Haxe
  
  
 * Main layouts module for Phoenix application
 * Provides the layout functions that Phoenix expects
 
  """

  # Static functions
  @doc """
    Root layout function
    Called by Phoenix for rendering the main HTML document
  """
  @spec root(term()) :: String.t()
  def root(assigns) do
    RootLayout.render(assigns)
  end

  @doc """
    Application layout function
    Called by Phoenix for rendering the application wrapper
  """
  @spec app(term()) :: String.t()
  def app(assigns) do
    AppLayout.render(assigns)
  end

end
