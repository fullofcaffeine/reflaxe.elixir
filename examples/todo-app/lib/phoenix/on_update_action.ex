defmodule phoenix.OnUpdateAction do
  def nothing() do
    {:Nothing}
  end
  def restrict() do
    {:Restrict}
  end
  def update_all() do
    {:Update_all}
  end
  def nilify_all() do
    {:Nilify_all}
  end
end