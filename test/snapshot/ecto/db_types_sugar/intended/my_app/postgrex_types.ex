defmodule MyApp.PostgrexTypes do
  Postgrex.Types.define(__MODULE__, [], json: Jason)
end