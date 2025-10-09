defmodule Result_Impl_ do
  def _new(result) do
    result
  end
  def success(value) do
    result = {:success, value}
    this1 = result
  end
  def error(error, context) do
    result = {:error, error, context}
    this1 = result
  end
end