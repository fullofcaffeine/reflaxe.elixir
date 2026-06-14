defmodule Main do
  def main() do
    _basic = Template.new("Hello ::name::!")
    _conditional = Template.new("::if enabled::on::else::off::end::")
    _loop = Template.new("::foreach items::::label::=::value::;::end::")
    _macro_template = Template.new("$$upper(name)")
    nil
  end
end
