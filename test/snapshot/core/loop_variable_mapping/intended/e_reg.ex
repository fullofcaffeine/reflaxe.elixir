defmodule EReg do
  def new(r, opt) do
    %{}
  end
  def match(struct, s) do
    false
  end
  def matched(struct, n) do
    nil
  end
  def matched_left(struct) do
    nil
  end
  def matched_right(struct) do
    nil
  end
  def matched_pos(struct) do
    nil
  end
  def match_sub(struct, s, pos, len) do
    false
  end
  def split(struct, s) do
    nil
  end
  def replace(struct, s, by) do
    nil
  end
  def map(struct, s, f) do
    nil
  end
  def escape(s) do
    nil
  end
end