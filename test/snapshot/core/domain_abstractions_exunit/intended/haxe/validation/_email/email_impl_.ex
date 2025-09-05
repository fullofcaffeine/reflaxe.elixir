defmodule Email_Impl_ do
  def _new(email) do
    this1 = nil
    if (not is_valid_email(email)) do
      throw("Invalid email address: " <> email)
    end
    this1 = email
    this1
  end
  def parse(email) do
    if (not is_valid_email(email)), do: {:Error, "Invalid email address: " <> email}
    {:Ok, email}
  end
  def get_domain(this1) do
    at_index = this1.lastIndexOf("@")
    this1 = String.slice(this1, at_index + 1)
  end
  def get_local_part(this1) do
    at_index = this1.lastIndexOf("@")
    this1 = String.slice(this1, 0, at_index)
  end
  def has_domain(this1, domain) do
    String.downcase(get_domain(this1)) == String.downcase(domain)
  end
  def normalize(this1) do
    this1 = String.downcase(this1)
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    String.downcase(this1) == String.downcase(to_string(other))
  end
  defp is_valid_email(email) do
    if (email == nil || email.length == 0), do: false
    at_index = email.indexOf("@")
    last_at_index = email.lastIndexOf("@")
    if (at_index == -1 || at_index != last_at_index), do: false
    if (at_index == 0 || at_index == (email.length - 1)), do: false
    local_part = email.substring(0, at_index)
    domain_part = email.substring(at_index + 1)
    if (local_part.length == 0 || local_part.length > 64), do: false
    if (domain_part.length == 0 || domain_part.length > 255), do: false
    if (domain_part.indexOf(".") == -1), do: false
    if (domain_part.charAt(0) == "." || domain_part.charAt(0) == "-" || domain_part.charAt((domain_part.length - 1)) == "." || domain_part.charAt((domain_part.length - 1)) == "-"), do: false
    true
  end
end