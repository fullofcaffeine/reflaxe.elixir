defmodule Phoenix.ChangesetAction do
  def insert() do
    {:insert}
  end
  def update() do
    {:update}
  end
  def delete() do
    {:delete}
  end
  def replace() do
    {:replace}
  end
  def ignore() do
    {:ignore}
  end
end
