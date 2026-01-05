defmodule UserId_Impl_ do
  import Kernel, except: [to_string: 1, length: 1], warn: false
  def _new(user_id) do
    _this1 = (case validate(user_id) do
      {:ok, this1} -> this1
      {:error, reason} ->
        throw(reason)
        reason
    end)
  end
  def parse(user_id) do
    (case validate(user_id) do
      {:ok, _value} -> {:ok, user_id}
      {:error, reason} -> {:error, reason}
    end)
  end
  def length(this1) do
    String.length(this1)
  end
  def normalize(this1) do
    String.downcase(this1)
  end
  def starts_with(this1, prefix) do
    (case :binary.match(this1, prefix) do
  {pos, _} -> pos
  :nomatch -> -1
end) == 0
  end
  def starts_with_ignore_case(this1, prefix) do
    (case :binary.match(String.downcase(this1), String.downcase(prefix)) do
  {pos, _} -> pos
  :nomatch -> -1
end) == 0
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    this1 == to_string(other)
  end
  def equals_ignore_case(this1, other) do
    String.downcase(this1) == String.downcase(to_string(other))
  end
  def compare(this1, other) do
    this1 < to_string(other)
  end
  defp validate(user_id) do
    if (Kernel.is_nil(user_id)) do
      {:error, "User ID cannot be null"}
    else
      if (String.length(user_id) == 0) do
        {:error, "User ID cannot be empty"}
      else
        if (String.length(user_id) < 3) do
          {:error, "User ID too short: minimum " <> Kernel.to_string(3) <> " characters, got " <> Kernel.to_string(String.length(user_id))}
        else
          if (String.length(user_id) > 50) do
            {:error, "User ID too long: maximum " <> Kernel.to_string(50) <> " characters, got " <> Kernel.to_string(String.length(user_id))}
          else
            _g = 0
            user_id_length = String.length(user_id)
            _ = Enum.each(0..(user_id_length - 1)//1, fn i ->
  char = if (i < 0) do
    ""
  else
    String.at(user_id, i) || ""
  end
  if (not is_alpha_numeric(char)), do: {:error, "User ID contains invalid character: \"" <> char <> "\" at position " <> Kernel.to_string(i) <> ". Only alphanumeric characters allowed."}
end)
            {:ok, nil}
          end
        end
      end
    end
  end
  defp is_alpha_numeric(char) do
    if (String.length(char) != 1) do
      false
    else
      code = Enum.at(String.to_charlist(char), 0)
      code >= 48 and code <= 57 or code >= 65 and code <= 90 or code >= 97 and code <= 122
    end
  end
end
