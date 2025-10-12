defmodule Log do
  def format_output(v, infos) do
    str = inspect(v)
    if Kernel.is_nil(infos), do: str
    str
  end
  def trace(v, infos) do
    (

            case infos do
              nil -> IO.inspect(v)
              infos ->
                file = Map.get(infos, :fileName)
                line = Map.get(infos, :lineNumber)
                base = if file != nil and line != nil, do: "#{file}:#{line}", else: nil
                class = Map.get(infos, :className)
                method = Map.get(infos, :methodName)
                label = cond do
                  class != nil and method != nil and base != nil -> "#{class}.#{method} - #{base}"
                  base != nil -> base
                  true -> nil
                end
                if label != nil, do: IO.inspect(v, label: label), else: IO.inspect(v)
            end
            
)
  end
end
