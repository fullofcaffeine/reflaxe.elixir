defmodule Elixir.Types.TermDecodeError do
  def expected_type(arg0, arg1) do
    {0, arg0, arg1}
  end
  def missing_key(arg0) do
    {1, arg0}
  end
  def expected_ok_error_tuple(arg0) do
    {2, arg0}
  end
end
