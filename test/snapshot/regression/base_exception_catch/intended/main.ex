defmodule Main do
  def main() do
    if (not catches_string()) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "String escaped its exception handler."]
    end
    if (message(false) != "expected") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "String message changed."]
    end
    if (message(true) != "object") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Exception message changed."]
    end
    if (ordered(false) != "string:expected") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Typed catch order changed."]
    end
    if (ordered(true) != "base:object") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Base catch changed."]
    end
    if (derived_message() != "derived") do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Subclass message changed."]
    end
  end
  def catches_string() do
    caught = false
    caught = try do
      fail(false)
      caught
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        caught = (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {_, _} ->
            caught = true
            caught
        end)
        caught
    end
    caught
  end
  def message(object) do
    try do
      fail(object)
      "not caught"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} ->
            error = Reflaxe.Elixir.HaxeThrow.normalize_caught(error)
            Reflaxe.Exception.get_message(error)
        end)
    end
  end
  def ordered(object) do
    try do
      fail(object)
      "not caught"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {text, _} when is_binary(text) -> "string:" <> text
          {error, _} ->
            error = Reflaxe.Elixir.HaxeThrow.normalize_caught(error)
            "base:" <> Reflaxe.Exception.get_message(error)
        end)
    end
  end
  def aliased(action) do
    try do
      action.()
      "not caught"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} ->
            error = Reflaxe.Elixir.HaxeThrow.normalize_caught(error)
            Reflaxe.Exception.get_message(error)
        end)
    end
  end
  def number_only(action) do
    try do
      action.()
      0
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {number, _} when is_integer(number) -> number
          _ ->
            reraise(haxe_exception, __STACKTRACE__)
        end)
    end
  end
  def caught_object(action) do
    try do
      action.()
      nil
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} ->
            error = Reflaxe.Elixir.HaxeThrow.normalize_caught(error)
            error
        end)
    end
  end
  def derived_message() do
    try do
      raise Reflaxe.Elixir.HaxeThrow, [value: DerivedFailure.new()]
      "not caught"
    rescue
      haxe_exception ->
        Process.put(:__reflaxe_last_stacktrace__, __STACKTRACE__)
        (case {(case haxe_exception do
          %Reflaxe.Elixir.HaxeThrow{value: haxe_unwrapped_value} -> haxe_unwrapped_value
          _ -> haxe_exception
        end), haxe_exception} do
          {error, _} ->
            error = Reflaxe.Elixir.HaxeThrow.normalize_caught(error)
            Reflaxe.Exception.get_message(error)
        end)
    end
  end
  defp fail(object) do
    if (object) do
      raise Reflaxe.Elixir.HaxeThrow, [value: Reflaxe.Exception.new("object", nil, nil)]
    end
    raise Reflaxe.Elixir.HaxeThrow, [value: "expected"]
  end
end
