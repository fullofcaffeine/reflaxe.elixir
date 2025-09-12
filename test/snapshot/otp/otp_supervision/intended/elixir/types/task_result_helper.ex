defmodule TaskResultHelper do
  def is_ok(result) do
    if (result == nil) do
      false
    else
      case (result) do
        0 ->
          _g = elem(result, 1)
          true
        1 ->
          _g = elem(result, 1)
          false
      end
    end
  end
  def get_value(result) do
    if (result == nil) do
      nil
    else
      case (result) do
        0 ->
          g = elem(result, 1)
          value = g
          value
        1 ->
          _g = elem(result, 1)
          nil
      end
    end
  end
  def get_exit_reason(result) do
    if (result == nil) do
      nil
    else
      case (result) do
        0 ->
          _g = elem(result, 1)
          nil
        1 ->
          g = elem(result, 1)
          reason = g
          reason
      end
    end
  end
end