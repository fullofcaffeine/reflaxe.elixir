defmodule HttpStatus do
  def ok() do
    {0}
  end
  def custom(arg0) do
    {1, arg0}
  end
  def error(arg0) do
    {2, arg0}
  end
  def redirect(arg0, arg1) do
    {3, arg0, arg1}
  end
end
