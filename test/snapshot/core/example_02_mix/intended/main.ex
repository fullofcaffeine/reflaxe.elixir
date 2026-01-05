defmodule Main do
  def main() do
    raw_input = "   hello  world   "
    _processed = StringUtils.process_string(raw_input)
    user_name = "john DOE smith"
    _formatted = StringUtils.format_display_name(user_name)
    email = "  User@Example.COM  "
    email_result = StringUtils.process_email(email)
    if (email_result.valid), do: nil
    title = "Hello World! This is a Test..."
    _slug = StringUtils.create_slug(title)
    long_text = "This is a very long text that needs to be truncated to fit in a preview area or card component."
    _truncated = StringUtils.truncate(long_text, 50)
    sensitive_data = "secret123"
    _masked = StringUtils.mask_sensitive_info(sensitive_data, 2)
    nil
  end
end
