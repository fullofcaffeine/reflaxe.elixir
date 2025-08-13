defmodule TodoLive do
  use Phoenix.LiveView
  
  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end
  
  @impl true
  def render(assigns) do
    ~H"""
    <div>LiveView generated from TodoLive</div>
    """
  end
end

@type repo :: Repo.t()