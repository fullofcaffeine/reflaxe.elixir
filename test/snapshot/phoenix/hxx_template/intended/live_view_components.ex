defmodule LiveViewComponents do
  def render_counter(count) do
    "<div class='counter'><h3>Count: " <> count <> "</h3>" <> "<button phx-click='increment'>+</button>" <> "<button phx-click='decrement'>-</button>" <> "<button phx-click='reset'>Reset</button>" <> "</div>"
  end
  def render_live_data(data) do
    "<div class='sensor-data' phx-update='replace'><div class='temperature'><span class='label'>Temperature:</span><span class='value'>" <> data.temperature <> "°C</span>" <> "</div>" <> "<div class='humidity'>" <> "<span class='label'>Humidity:</span>" <> "<span class='value'>" <> data.humidity <> "%</span>" <> "</div>" <> "</div>"
  end
end