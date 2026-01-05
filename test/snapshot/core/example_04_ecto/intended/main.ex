defmodule Main do
  def main() do
    _up_sql = CreateUsers.up()
    _down_sql = CreateUsers.down()
    nil
  end
end
