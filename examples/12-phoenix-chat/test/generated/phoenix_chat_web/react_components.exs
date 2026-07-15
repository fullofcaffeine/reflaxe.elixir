defmodule PhoenixChatWeb.ReactComponents do
  use Phoenix.Component
  def preference_studio(assigns) do
    ~H"""
    <LiveReact.react id={@id} name="PreferenceStudio" title={@title} density={@density} ssr={false} />
    """
  end
end
