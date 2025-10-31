defmodule Phoenix.OnUpdateAction do
  def nothing() do
    {:nothing}
  end
  def restrict() do
    {:restrict}
  end
  def update_all() do
    {:update_all}
  end
  def nilify_all() do
    {:nilify_all}
  end
end
