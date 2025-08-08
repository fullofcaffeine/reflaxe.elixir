# Example switch/case compilation output for enum pattern matching

# Simple enum switch - Haxe switch to Elixir case
defmodule StatusHandler do
  def handle_status(status) do
    case status do
      :none ->
        "No status available"
      :ready ->
        "System is ready"
      :error ->
        "An error occurred"
    end
  end
end

# Parameterized enum switch with variable binding
defmodule ResultHandler do
  def handle_result(result) do
    case result do
      {:ok, value} ->
        "Success: #{value}"
      {:error, message} ->
        "Error: #{message}"
      _ ->
        "Unknown result"
    end
  end
end

# Mixed enum switch - combining atoms and tagged tuples
defmodule MessageProcessor do
  def process_message(msg) do
    case msg do
      {:info, text} ->
        IO.puts("Info: #{text}")
      {:warning, text, level} ->
        IO.puts("Warning (level #{level}): #{text}")
      :critical ->
        IO.puts("CRITICAL ERROR!")
      _ ->
        IO.puts("Unknown message type")
    end
  end
end

# Option enum pattern matching - common functional pattern
defmodule OptionHandler do
  def get_value_or_default(option, default) do
    case option do
      :none ->
        default
      {:some, value} ->
        value
    end
  end
  
  def map_option(option, func) do
    case option do
      :none ->
        :none
      {:some, value} ->
        {:some, func.(value)}
    end
  end
end

# Nested enum pattern matching
defmodule NestedHandler do
  def handle_nested_result(nested) do
    case nested do
      {:ok, {:some, value}} ->
        "Success with value: #{value}"
      {:ok, :none} ->
        "Success but no value"
      {:error, message} ->
        "Error: #{message}"
      _ ->
        "Unexpected result"
    end
  end
end

# Guard clauses with enum patterns (advanced pattern matching)
defmodule GuardHandler do
  def handle_with_guards(msg) do
    case msg do
      {:info, text} when byte_size(text) > 0 ->
        "Valid info: #{text}"
      {:warning, text, level} when level > 0 and level < 5 ->
        "Warning level #{level}: #{text}"
      {:warning, text, level} when level >= 5 ->
        "HIGH WARNING level #{level}: #{text}"
      :critical ->
        "CRITICAL!"
      _ ->
        "Invalid or empty message"
    end
  end
end