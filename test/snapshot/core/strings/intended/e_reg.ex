defmodule EReg do
  def match(struct, _s) do
    false
  end
  def matched(struct, _n) do
    nil
  end
  def matched_right(struct) do
    nil
  end
  def replace(struct, _s, _by) do
    nil
  end
end
