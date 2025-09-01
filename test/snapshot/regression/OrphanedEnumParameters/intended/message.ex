defmodule Message do
  def created(arg0) do
    {:Created, arg0}
  end
  def updated(arg0, arg1) do
    {:Updated, arg0, arg1}
  end
  def deleted(arg0) do
    {:Deleted, arg0}
  end
  def empty() do
    {:Empty}
  end
end