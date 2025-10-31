defmodule Phoenix.OnReplaceAction do
  def raise() do
    {:raise}
  end
  def mark_as_invalid() do
    {:mark_as_invalid}
  end
  def nilify() do
    {:nilify}
  end
  def delete() do
    {:delete}
  end
  def update() do
    {:update}
  end
end
