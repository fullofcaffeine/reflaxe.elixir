defmodule PhoenixChatWeb.ReactComponents do
  use Phoenix.Component
  def preference_studio(assigns) do
    ~H"""
    <div class="react-island-host">
          <LiveReact.react id={@id} name="PreferenceStudio" title={@title} density={@density} ssr={false}></LiveReact.react>
        </div>
    """
  end
end
