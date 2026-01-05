defmodule Email_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(email) do
    if (not is_valid_email(email)) do
      throw("Invalid email address: " <> email)
    end
    email
  end
  def parse(email) do
    if (not is_valid_email(email)), do: {:error, "Invalid email address: " <> email}, else: {:ok, email}
  end
  def get_domain(this1) do
    at_index = (case String.split(String.slice(this1, 0, String.length(this1)), "@") do
      parts when Kernel.length(parts) > 1 ->
        String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "@"))
      _ -> -1
    end)
    _ = String.slice(this1, at_index + 1..-1//1)
  end
  def get_local_part(this1) do
    at_index = (case String.split(String.slice(this1, 0, String.length(this1)), "@") do
      parts when Kernel.length(parts) > 1 ->
        String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "@"))
      _ -> -1
    end)
    _ = String.slice(this1, 0, (at_index - 0))
  end
  def has_domain(this1, domain) do
    String.downcase(get_domain(this1)) == String.downcase(domain)
  end
  def normalize(this1) do
    String.downcase(this1)
  end
  def to_string(this1) do
    this1
  end
  def equals(this1, other) do
    String.downcase(this1) == String.downcase(to_string(other))
  end
  defp is_valid_email(email) do
    if (Kernel.is_nil(email) or String.length(email) == 0) do
      false
    else
      at_index = (case :binary.match(email, "@") do
        {pos, _} -> pos
        :nomatch -> -1
      end)
      last_at_index = (case String.split(String.slice(email, 0, String.length(email)), "@") do
        parts when Kernel.length(parts) > 1 ->
          String.length(Enum.join((fn -> Enum.slice(parts, 0..-2//1) end).(), "@"))
        _ -> -1
      end)
      if (at_index == -1 or at_index != last_at_index) do
        false
      else
        if (at_index == 0 or at_index == (String.length(email) - 1)) do
          false
        else
          local_part = String.slice(email, 0, (at_index - 0))
          domain_part = String.slice(email, at_index + 1..-1//1)
          if (String.length(local_part) == 0 or String.length(local_part) > 64) do
            false
          else
            if (String.length(domain_part) == 0 or String.length(domain_part) > 255) do
              false
            else
              cond_value = (case :binary.match(domain_part, ".") do
                {pos, _} -> pos
                :nomatch -> -1
              end)
              if (cond_value == -1) do
                false
              else
                cond_value = String.at(domain_part, 0) || "" == "." or String.at(domain_part, 0) || "" == "-" or (if ((String.length(domain_part) - 1) < 0) do
  ""
else
  String.at(domain_part, (String.length(domain_part) - 1)) || ""
end) == "."
                if (cond_value or cond_value), do: false, else: true
              end
            end
          end
        end
      end
    end
  end
end
