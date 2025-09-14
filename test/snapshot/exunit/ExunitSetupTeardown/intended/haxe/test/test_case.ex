defmodule TestCase do
  def setup(_struct, context) do
    context
  end
  def setup_all(_struct, context) do
    context
  end
  def teardown(_struct, _context) do
    nil
  end
  def teardown_all(_struct, _context) do
    nil
  end
end