defprotocol Displayable do
  @spec display() :: String
  def display(value)
  @spec format(any()) :: String
  def format(value)
end
