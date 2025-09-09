defmodule reflaxe.elixir.macros.HttpMethod do
  def get() do
    {:GET}
  end
  def post() do
    {:POST}
  end
  def put() do
    {:PUT}
  end
  def delete() do
    {:DELETE}
  end
  def patch() do
    {:PATCH}
  end
  def live() do
    {:LIVE}
  end
  def live_dashboard() do
    {:LIVE_DASHBOARD}
  end
end