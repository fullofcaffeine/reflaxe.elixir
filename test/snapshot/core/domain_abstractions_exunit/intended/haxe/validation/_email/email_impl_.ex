defmodule Email_Impl_ do
  def _new(email) do
    if (not is_valid_email(email)) do
      throw("Invalid email address: " <> email)
    end
    this1 = email
    this1
  end
  def parse(email) do
    if (not is_valid_email(email)), do: {:error, "Invalid email address: " <> email}
    {:ok, email}
  end
  def get_domain(this1) do
    String.slice(this1, (this1.last_index_of("@")) + 1)
  end
  def get_local_part(this1) do
    String.slice(this1, 0, (this1.last_index_of("@")))
  end
  def has_domain(this1, domain) do
    get_domain(this1).to_lower_case() == domain.to_lower_case()
  end
  def normalize(this1) do
    this1.to_lower_case()
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    this1.to_lower_case() == to_string(other).to_lower_case()
  end
  defp is_valid_email(email) do
    if (email == nil || length(email) == 0), do: false
    at_index = email.index_of("@")
    last_at_index = email.last_index_of("@")
    if (at_index == -1 || at_index != last_at_index), do: false
    if (at_index == 0 || at_index == (length(email) - 1)), do: false
    local_part = email.substring(0, at_index)
    domain_part = email.substring(at_index + 1)
    if (length(local_part) == 0 || length(local_part) > 64), do: false
    if (length(domain_part) == 0 || length(domain_part) > 255), do: false
    if (domain_part.index_of(".") == -1), do: false
    if (domain_part.char_at(0) == "." || domain_part.char_at(0) == "-" || domain_part.char_at((length(domain_part) - 1)) == "." || domain_part.char_at((length(domain_part) - 1)) == "-"), do: false
    true
  end
end