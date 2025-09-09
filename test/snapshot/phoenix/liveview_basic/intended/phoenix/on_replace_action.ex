defmodule phoenix.OnReplaceAction do
  def raise() do
    {:Raise}
  end
  def mark_as_invalid() do
    {:Mark_as_invalid}
  end
  def nilify() do
    {:Nilify}
  end
  def delete() do
    {:Delete}
  end
  def update() do
    {:Update}
  end
end