defmodule UserView do
  @moduledoc """
  Phoenix HEEx template module generated from Haxe @:template class
  Template file: user_view.html.heex
  """

  use Phoenix.Component
  import Phoenix.HTML
  import Phoenix.HTML.Form

  @doc """
  Renders the user_view.html.heex template with the provided assigns
  """
  def render(assigns) do
    ~H"""
    <!-- Template content will be processed by hxx() function -->
    <div class="haxe-template">
      <%= assigns[:content] || "Template content" %>
    </div>
    """
  end

  @doc """
  Template string processor - converts Haxe template strings to HEEx
  """
  def process_template_string(template_str) do
    # Process template string interpolations and convert to HEEx syntax
    template_str
    |> String.replace(~r/\$\{([^}]+)\}/, "<%= \\1 %>")
    |> String.replace(~r/<\.([^>]+)>/, "<.\\1>")
  end

end
