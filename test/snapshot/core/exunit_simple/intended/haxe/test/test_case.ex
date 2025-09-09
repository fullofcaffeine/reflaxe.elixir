defmodule TestCase do
  def setup(struct, context) do
    context
  end
  def setup_all(struct, context) do
    context
  end
  def teardown(struct, _context) do
    nil
  end
  def teardown_all(struct, _context) do
    nil
  end
end