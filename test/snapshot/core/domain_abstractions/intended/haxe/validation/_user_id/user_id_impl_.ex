defmodule UserId_Impl_ do
  def _new(user_id) do
    this_1 = nil
    g = {:Validate, user_id}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        this_1 = user_id
      1 ->
        g = g.elem(1)
        reason = g
        throw(reason)
    end
    this_1
  end
  def parse(user_id) do
    g = {:Validate, user_id}
    case (g.elem(0)) do
      0 ->
        g = g.elem(1)
        {:Ok, user_id}
      1 ->
        g = g.elem(1)
        reason = g
        {:Error, reason}
    end
  end
  def length(this1) do
    this1.length
  end
  def normalize(this1) do
    this1.toLowerCase()
  end
  def starts_with(this1, prefix) do
    this1.indexOf(prefix) == 0
  end
  def starts_with_ignore_case(this1, prefix) do
    this1.toLowerCase().indexOf(prefix.toLowerCase()) == 0
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    this1 == UserId_Impl_.to_string(other)
  end
  def equals_ignore_case(this1, other) do
    this1.toLowerCase() == UserId_Impl_.to_string(other).toLowerCase()
  end
  def compare(this1, other) do
    this1 < UserId_Impl_.to_string(other)
  end
  defp validate(user_id) do
    if (user_id == nil), do: {:Error, "User ID cannot be null"}
    if (user_id.length == 0), do: {:Error, "User ID cannot be empty"}
    if (user_id.length < 3), do: {:Error, "User ID too short: minimum " + 3 + " characters, got " + user_id.length}
    if (user_id.length > 50), do: {:Error, "User ID too long: maximum " + 50 + " characters, got " + user_id.length}
    g = 0
    g1 = user_id.length
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), :ok, fn _, acc -> if (g < g1) do
  i = g + 1
  char = user_id.charAt(i)
  if (not UserId_Impl_.is_alpha_numeric(char)), do: {:Error, "User ID contains invalid character: \"" + char + "\" at position " + i + ". Only alphanumeric characters allowed."}
  {:cont, acc}
else
  {:halt, acc}
end end)
    {:Ok, nil}
  end
  defp is_alpha_numeric(char) do
    if (char.length != 1), do: false
    code = char.charCodeAt(0)
    code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122
  end
end