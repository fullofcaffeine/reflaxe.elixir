defmodule MyAppRouter do
  def routes() do
    [get("/", :page_controller, "index"), get("/about", :page_controller, "about"), get("/contact", :page_controller, "contact"), post("/contact", :page_controller, "submit_contact"), resources("/users", :user_controller), resources("/posts", :post_controller, (fn -> g = %{}
g.set("only", ["index", "show"])
g end).()), resources("/comments", :comment_controller, (fn -> g = %{}
g.set("except", ["delete"])
g end).()), resources("/users", :user_controller, nil, fn ->
  resources("/posts", :post_controller)
  resources("/settings", :settings_controller, (fn -> g = %{}
_g.set("singleton", true)
_g end).())
end), scope("/api", (fn -> g = %{}
g.set("alias", "Api")
g end).(), fn ->
  pipe_through("api")
  get("/status", :status_controller, "index")
  resources("/users", :user_controller, (fn -> g = %{}
_g.set("as", "api_user")
_g end).())
  scope("/v1", (fn -> g = %{}
_g.set("alias", "V1")
_g end).(), fn ->
  resources("/products", :product_controller)
  resources("/orders", :order_controller)
end)
end), live("/dashboard", :dashboard_live, "index"), live("/users/:id", UserLive.Show, "show"), live("/users/:id/edit", UserLive.Edit, "edit"), live_session((fn -> g = %{}
g.set("on_mount", "authenticated")
g end).(), fn ->
  live("/profile", :profile_live, "index")
  live("/settings", :settings_live, "index")
end), pipeline("browser", [accepts(["html"]), fetch_session(), fetch_live_flash(), put_root_layout([MyAppWeb.LayoutView, "root.html"]), protect_from_forgery(), put_secure_browser_headers()]), pipeline("api", [accepts(["json"]), plug(MyAppWeb.APIAuthPlug)]), forward("/admin", :admin_router), match("*path", :error_controller, "not_found")]
  end
  defp get(_path, _controller, _action) do
    nil
  end
  defp post(_path, _controller, _action) do
    nil
  end
  defp put(_path, _controller, _action) do
    nil
  end
  defp patch(_path, _controller, _action) do
    nil
  end
  defp delete(_path, _controller, _action) do
    nil
  end
  defp resources(_path, _controller, _opts, _callback) do
    nil
  end
  defp scope(_path, _opts, _callback) do
    nil
  end
  defp live(_path, _module, _action) do
    nil
  end
  defp live_session(_opts, _callback) do
    nil
  end
  defp pipeline(_name, _plugs) do
    nil
  end
  defp pipe_through(_pipeline) do
    nil
  end
  defp forward(_path, _router) do
    nil
  end
  defp match(_path, _controller, _action) do
    nil
  end
  defp accepts(_types) do
    nil
  end
  defp fetch_session() do
    nil
  end
  defp fetch_live_flash() do
    nil
  end
  defp put_root_layout(_layout) do
    nil
  end
  defp protect_from_forgery() do
    nil
  end
  defp put_secure_browser_headers() do
    nil
  end
  defp plug(_module) do
    nil
  end
end