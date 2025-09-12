defmodule UserId_Impl_ do
  @min_length nil
  @max_length nil
  def _new(user_id) do
    this1 = nil
    g = validate(user_id)
    case (g) do
      {:ok, g} ->
        _g = g
        this1 = user_id
      {:error, g} ->
        g = g
        reason = g
        throw(reason)
    end
    this1
  end
  def parse(user_id) do
    g = validate(user_id)
    case (g) do
      {:ok, g} ->
        _g = g
        user_id
      {:error, g} ->
        g = g
        reason = g
        reason
    end
  end
  def length(this1) do
    length(this1)
  end
  def normalize(this1) do
    this1.to_lower_case()
  end
  def starts_with(this1, prefix) do
    this1.index_of(prefix) == 0
  end
  def starts_with_ignore_case(this1, prefix) do
    this1.to_lower_case().index_of(prefix.to_lower_case()) == 0
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    this1 == to_string(other)
  end
  def equals_ignore_case(this1, other) do
    this1.to_lower_case() == to_string(other).to_lower_case()
  end
  def compare(this1, other) do
    this1 < to_string(other)
  end
  defp validate(user_id) do
    if (user_id == nil), do: {:error, "User ID cannot be null"}
    if (length(user_id) == 0), do: {:error, "User ID cannot be empty"}
    if (length(user_id) < 3), do: {:error, "User ID too short: minimum " <> Kernel.to_string(3) <> " characters, got " <> Kernel.to_string(length(user_id))}
    if (length(user_id) > 50), do: {:error, "User ID too long: maximum " <> Kernel.to_string(50) <> " characters, got " <> Kernel.to_string(length(user_id))}
    g = 0
    g1 = length(user_id)
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {g, g1, :ok}, fn _, {acc_g, acc_g1, acc_state} ->
  if (acc_g < acc_g1) do
    i = acc_g = acc_g + 1
    char = user_id.char_at(i)
    if (not is_alpha_numeric(char)), do: {:error, "User ID contains invalid character: \"" <> char <> "\" at position " <> Kernel.to_string(i) <> ". Only alphanumeric characters allowed."}
    {:cont, {acc_g, acc_g1, acc_state}}
  else
    {:halt, {acc_g, acc_g1, acc_state}}
  end
end)
    {:ok, nil}
  end
  defp is_alpha_numeric(char) do
    if (length(char) != 1), do: false
    code = char.char_code_at(0)
    code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122
  end
end