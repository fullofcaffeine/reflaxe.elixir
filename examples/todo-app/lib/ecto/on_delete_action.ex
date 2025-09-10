defmodule Ecto.OnDeleteAction do
  def restrict() do
    {:Restrict}
  end
  def cascade() do
    {:Cascade}
  end
  def set_null() do
    {:SetNull}
  end
  def no_action() do
    {:NoAction}
  end
end