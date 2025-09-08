defmodule ecto.ChangesetAction do
  def insert() do
    {:Insert}
  end
  def update() do
    {:Update}
  end
  def delete() do
    {:Delete}
  end
  def replace() do
    {:Replace}
  end
  def ignore() do
    {:Ignore}
  end
end