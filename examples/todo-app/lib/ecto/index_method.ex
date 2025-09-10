defmodule Ecto.IndexMethod do
  def b_tree() do
    {:BTree}
  end
  def hash() do
    {:Hash}
  end
  def gin() do
    {:Gin}
  end
  def gist() do
    {:Gist}
  end
  def brin() do
    {:Brin}
  end
end