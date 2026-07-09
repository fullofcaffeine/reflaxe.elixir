defmodule Email_Impl_ do
  import Kernel, except: [to_string: 1], warn: false
  def _new(email) do
    if (not is_valid_email(email)) do
      raise Reflaxe.Elixir.HaxeThrow, [value: "Invalid email address: " <> email]
    end
    email
  end
  def parse(email) do
    if (not is_valid_email(email)), do: {:error, "Invalid email address: " <> email}, else: {:ok, email}
  end
  def get_domain(this1) do
    at_index = StringTools.haxe_last_index_of(this1, "@", nil)
    _ = StringTools.haxe_substring(this1, at_index + 1, nil)
  end
  def get_local_part(this1) do
    at_index = StringTools.haxe_last_index_of(this1, "@", nil)
    _ = StringTools.haxe_substring(this1, 0, at_index)
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
      at_index = StringTools.haxe_index_of(email, "@", 0)
      last_at_index = StringTools.haxe_last_index_of(email, "@", nil)
      if (at_index == -1 or at_index != last_at_index) do
        false
      else
        if (at_index == 0 or at_index == (String.length(email) - 1)) do
          false
        else
          local_part = StringTools.haxe_substring(email, 0, at_index)
          domain_part = StringTools.haxe_substring(email, at_index + 1, nil)
          if (String.length(local_part) == 0 or String.length(local_part) > 64) do
            false
          else
            if (String.length(domain_part) == 0 or String.length(domain_part) > 255) do
              false
            else
              if (StringTools.haxe_index_of(domain_part, ".", 0) == -1) do
                false
              else
                if (StringTools.haxe_char_at(domain_part, 0) == "." or StringTools.haxe_char_at(domain_part, 0) == "-" or StringTools.haxe_char_at(domain_part, (String.length(domain_part) - 1)) == "." or StringTools.haxe_char_at(domain_part, (String.length(domain_part) - 1)) == "-"), do: false, else: true
              end
            end
          end
        end
      end
    end
  end
end
