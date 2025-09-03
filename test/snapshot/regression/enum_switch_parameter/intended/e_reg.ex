defmodule EReg do
  def new(_r, _opt) do
    %{}
  end
  def match(struct, _s) do
    false
  end
  def matched(struct, _n) do
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
  def match_sub(struct, _s, _pos, _len) do
    false
  end
  def split(struct, _s) do
    nil
  end
  def replace(struct, _s, _by) do
    nil
  end
  def map(struct, _s, _f) do
    nil
  end
  def escape(_s) do
    nil
  end
end