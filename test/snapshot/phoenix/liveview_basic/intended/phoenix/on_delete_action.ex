defmodule Phoenix.OnDeleteAction do
  def nothing() do
    {:nothing}
  end
  def restrict() do
    {:restrict}
  end
  def delete_all() do
    {:delete_all}
  end
  def nilify_all() do
    {:nilify_all}
  end
end
