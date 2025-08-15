defmodule UserProfileTemplate do
  @moduledoc """
  Phoenix HEEx template module generated from Haxe @:template class
  Template file: user_profile_template.html.heex
  """

  use Phoenix.Component
  import Phoenix.HTML
  import Phoenix.HTML.Form

  @doc """
  Renders the user_profile_template.html.heex template with the provided assigns
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


defmodule FormTemplate do
  @moduledoc """
  Phoenix HEEx template module generated from Haxe @:template class
  Template file: form_template.html.heex
  """

  use Phoenix.Component
  import Phoenix.HTML
  import Phoenix.HTML.Form

  @doc """
  Renders the form_template.html.heex template with the provided assigns
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


defmodule LiveViewComponents do
  @moduledoc """
  Phoenix HEEx template module generated from Haxe @:template class
  Template file: live_view_components.html.heex
  """

  use Phoenix.Component
  import Phoenix.HTML
  import Phoenix.HTML.Form

  @doc """
  Renders the live_view_components.html.heex template with the provided assigns
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


defmodule Main do
  @moduledoc """
  Main module generated from Haxe
  """

  # Static functions
  @doc "Function main"
  @spec main() :: nil
  def main() do
    Log.trace("Template compilation test", %{"fileName" => "Main.hx", "lineNumber" => 119, "className" => "Main", "methodName" => "main"})
  end

end
