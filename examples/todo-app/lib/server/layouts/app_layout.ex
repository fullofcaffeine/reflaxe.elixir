defmodule AppLayout do
  def render(assigns) do
    temp_result = (:nil <> :nil <> :nil.string(:nil) <> "\n                    </div>\n                    \n                </main>\n                \n                <!-- Footer -->\n                <footer class=\"bg-white/80 dark:bg-gray-800/80 backdrop-blur-sm border-t border-gray-200 dark:border-gray-700 mt-auto\">\n                    <div class=\"max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-6\">\n                        <div class=\"flex justify-between items-center\">\n                            <div class=\"text-sm text-gray-500 dark:text-gray-400\">\n                                Built with ❤️ using Haxe and Phoenix LiveView\n                            </div>\n                            <div class=\"flex space-x-6 text-sm text-gray-500 dark:text-gray-400\">\n                                <a href=\"/about\" class=\"hover:text-gray-700 dark:hover:text-gray-300 transition-colors\">About</a>\n                                <a href=\"/help\" class=\"hover:text-gray-700 dark:hover:text-gray-300 transition-colors\">Help</a>\n                                <a href=\"https://github.com/reflaxe/elixir\" class=\"hover:text-gray-700 dark:hover:text-gray-300 transition-colors\">GitHub</a>\n                            </div>\n                        </div>\n                    </div>\n                </footer>\n                \n            </div>\n        ")
    tempResult
  end
  defp get_user_display_name(user) do
    if (user != nil && Map.get(user, :name) != nil), do: user.name
    "User"
  end
  defp get_page_title(title) do
    if (title != nil), do: title
    "Todo Dashboard"
  end
  defp get_last_updated(timestamp) do
    if (timestamp != nil), do: timestamp
    "now"
  end
  defp get_initials(name) do
    if (name == nil || name == ""), do: "U"
    parts = name.split(" ")
    if (length(parts) >= 2), do: :nil.char_at(0).to_upper_case() <> :nil.char_at(0).to_upper_case()
    name.char_at(0).to_upper_case()
  end
  defp format_timestamp(timestamp) do
    timestamp
  end
end