defmodule phoenix.OnDeleteAction do
  def nothing() do
    {:Nothing}
  end
  def restrict() do
    {:Restrict}
  end
  def delete_all() do
    {:Delete_all}
  end
  def nilify_all() do
    {:Nilify_all}
  end
end