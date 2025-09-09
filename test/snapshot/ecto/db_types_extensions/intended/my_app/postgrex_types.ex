defmodule MyApp.PostgrexTypes do
  Postgrex.Types.define(__MODULE__, [], json: Jason, extensions: [MyExt.One, MyExt.Two])
end