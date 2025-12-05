defmodule EReg do
  def match(_struct, _s) do
    false
  end
  def matched(_struct, _n) do
    nil
  end
  def matched_right(_struct) do
    nil
  end
  def replace(_struct, _s, _by) do
    nil
  end
end
