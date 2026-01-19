defmodule Main do
  def main() do
    _ = test_attribute_conversion()
    _ = test_snake_case_support()
    _ = test_type_validation()
    _ = test_phoenix_directives()
    _ = test_complex_templates()
    _ = test_error_messages()
  end
  defp test_attribute_conversion() do
    div1 = "<div class=\"container\">Content</div>"
    label1 = "<label for=\"email\">Email:</label>"
    div2 = "<div data-test-id=\"main-content\">Test</div>"
    button1 = "<button aria-label=\"Submit form\">Submit</button>"
    button2 = "<button phx-click=\"handle_click\">Click me</button>"
    complex = "<div class=\"card\" dataUserId=\"123\" phxHook=\"ScrollLock\">Card</div>"
    "#{div1}#{label1}#{div2}#{button1}#{button2}#{complex}"
  end
  defp test_snake_case_support() do
    button1 = "<button phx_click=\"handle_click\">Click me</button>"
    div1 = "<div data_test_id=\"main-content\">Test</div>"
    button2 = "<button aria_label=\"Submit form\">Submit</button>"
    mixed = "\n            <div class=\"container\" data_user_id=\"123\">\n                <button phx-click=\"save\" aria_label=\"Save button\">Save</button>\n                <button phx_change=\"validate\" ariaHidden=\"true\">Validate</button>\n            </div>\n        "
    kebab = "<div id=\"kebab-hook\" data-test-id=\"test\" phx-hook=\"MyHook\">Kebab</div>"
    complex = "\n            <input phx_change=\"validate_email\"\n                   phx_debounce=\"300\"\n                   data_field_name=\"user_email\"\n                   aria_describedby=\"email_help\" />\n        "
    "#{button1}#{div1}#{button2}#{mixed}#{kebab}#{complex}"
  end
  defp test_type_validation() do
    input_elem = "<input type=\"text\" name=\"email\" placeholder=\"Enter email\" required phxChange=\"validate_email\" />"
    button_elem = "<button type=\"submit\" phxClick=\"submit_form\">Submit</button>"
    form_elem = "<form action=\"/users\" method=\"post\" phxSubmit=\"save_user\" phxChange=\"validate\"></form>"
    select_elem = "\n            <select name=\"country\" required>\n                <option value=\"us\">United States</option>\n                <option value=\"ca\">Canada</option>\n                <option value=\"mx\">Mexico</option>\n            </select>\n        "
    "#{input_elem}#{button_elem}#{form_elem}#{select_elem}"
  end
  defp test_phoenix_directives() do
    live_div = "\n            <div phx-click=\"clicked\"\n                 phxChange=\"changed\"\n                 phxSubmit=\"submitted\"\n                 phxFocus=\"focused\"\n                 phxBlur=\"blurred\"\n                 phxKeydown=\"key_pressed\"\n                 phxKeyup=\"key_released\"\n                 phxMouseenter=\"mouse_entered\"\n                 phxMouseleave=\"mouse_left\"\n                 phxHook=\"MyHook\"\n                 phxDebounce=\"300\"\n                 phxThrottle=\"500\"\n                 phxUpdate=\"stream\"\n                 phxTrackStatic=\"true\">\n                Interactive element\n            </div>\n        "
    live_link = "\n            <a href=\"/users\" phxLink=\"patch\" phxLinkState=\"push\">\n                View Users\n            </a>\n        "
    "#{live_div}#{live_link}"
  end
  defp test_complex_templates() do
    _ = nil
    _ = nil
    _ = nil
    _ = nil
    todo_item = "\n            <div class=\"todo-item\" dataItemId={todo.id}>\n                <input type=\"checkbox\" \n                       checked={todo.completed}\n                       phxClick=\"toggle_todo\"\n                       phxValue={todo.id} />\n                <span class={if todo.completed, do: \"completed\", else: \"\"}><%= todo.title %></span>\n                <button class=\"delete-btn\" \n                        phxClick=\"delete_todo\"\n                        phxValue={todo.id}\n                        ariaLabel=\"Delete todo\">\n                    ×\n                </button>\n            </div>\n        "
    user_form = "\n            <form phx-submit=\"save_user\" phxChange=\"validate\">\n                <div class=\"form-group\">\n                    <label for=\"name\">Name:</label>\n                    <input type=\"text\" \n                           id=\"name\"\n                           name=\"user[name]\"\n                           value={user.name}\n                           placeholder=\"Enter your name\"\n                           required />\n                    <span class=\"error\"><%= errors.name %></span>\n                </div>\n                \n                <div class=\"form-group\">\n                    <label for=\"email\">Email:</label>\n                    <input type=\"email\"\n                           id=\"email\"\n                           name=\"user[email]\"\n                           value={user.email}\n                           placeholder=\"user@example.com\"\n                           required />\n                    <span class=\"error\"><%= errors.email %></span>\n                </div>\n                \n                <button type=\"submit\" disabled={!valid}>\n                    Save User\n                </button>\n            </form>\n        "
    data_table = "\n            <table class=\"data-table\">\n                <thead>\n                    <tr>\n                        <th>ID</th>\n                        <th>Name</th>\n                        <th>Status</th>\n                        <th>Actions</th>\n                    </tr>\n                </thead>\n                <tbody>\n                    <% for user <- users do %>\n                        <tr key={user.id}>\n                            <td><%= user.id %></td>\n                            <td><%= user.name %></td>\n                            <td class={if user.active, do: \"active\", else: \"inactive\"}>\n                                <%= if user.active, do: \"Active\", else: \"Inactive\" %>\n                            </td>\n                            <td>\n                                <button phx-click=\"edit_user\" phxValue={user.id}>Edit</button>\n                                <button phx-click=\"delete_user\" phxValue={user.id}>Delete</button>\n                            </td>\n                        </tr>\n                    <% end %>\n                </tbody>\n            </table>\n        "
    "#{todo_item}#{user_form}#{data_table}"
  end
  defp test_error_messages() do
    phoenix_component = "<.button type=\"primary\">Click me</.button>"
    complex_element = "\n            <div id=\"main\"\n                 className=\"container mx-auto\"\n                 style=\"padding: 20px;\"\n                 role=\"main\"\n                 ariaLabel=\"Main content\"\n                 tabIndex=\"0\"\n                 dataTestId=\"main-container\"\n                 phxClick=\"container_clicked\"\n                 phxHook=\"ScrollTracker\">\n                Complex element with many attributes\n            </div>\n        "
    "#{phoenix_component}#{complex_element}"
  end
end
