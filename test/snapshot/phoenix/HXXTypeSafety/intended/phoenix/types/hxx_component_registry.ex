defmodule HXXComponentRegistry do
  defp __haxe_static_get__(key, init) do
    static_key = {:__haxe_static__, HXXComponentRegistry, key}
    (case Process.get(static_key) do
      {:set, value} -> value
      nil ->
        value = init
        _ = Process.put(static_key, {:set, value})
        value
    end)
  end
  defp __haxe_static_put__(key, value) do
    static_key = {:__haxe_static__, HXXComponentRegistry, key}
    _ = Process.put(static_key, {:set, value})
    value
  end
  def html_elements() do
    __haxe_static_get__(:html_elements, (fn ->
        g = %{}
        value = %{:name => "input", :attribute_type => "InputAttributes", :allowed_attributes => get_input_attributes(), :void_element => true}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "input", value])
        value = %{:name => "button", :attribute_type => "ButtonAttributes", :allowed_attributes => get_button_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "button", value])
        value = %{:name => "form", :attribute_type => "FormAttributes", :allowed_attributes => get_form_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "form", value])
        value = %{:name => "select", :attribute_type => "SelectAttributes", :allowed_attributes => get_select_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "select", value])
        value = %{:name => "option", :attribute_type => "OptionAttributes", :allowed_attributes => get_option_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "option", value])
        value = %{:name => "textarea", :attribute_type => "TextAreaAttributes", :allowed_attributes => get_text_area_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "textarea", value])
        value = %{:name => "label", :attribute_type => "LabelAttributes", :allowed_attributes => get_label_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "label", value])
        value = %{:name => "a", :attribute_type => "AnchorAttributes", :allowed_attributes => get_anchor_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "a", value])
        value = %{:name => "p", :attribute_type => "ParagraphAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "p", value])
        value = %{:name => "div", :attribute_type => "DivAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "div", value])
        value = %{:name => "span", :attribute_type => "SpanAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "span", value])
        value = %{:name => "h1", :attribute_type => "HeadingAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "h1", value])
        value = %{:name => "h2", :attribute_type => "HeadingAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "h2", value])
        value = %{:name => "h3", :attribute_type => "HeadingAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "h3", value])
        value = %{:name => "h4", :attribute_type => "HeadingAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "h4", value])
        value = %{:name => "h5", :attribute_type => "HeadingAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "h5", value])
        value = %{:name => "h6", :attribute_type => "HeadingAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "h6", value])
        value = %{:name => "img", :attribute_type => "ImageAttributes", :allowed_attributes => get_image_attributes(), :void_element => true}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "img", value])
        value = %{:name => "video", :attribute_type => "VideoAttributes", :allowed_attributes => get_video_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "video", value])
        value = %{:name => "audio", :attribute_type => "AudioAttributes", :allowed_attributes => get_audio_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "audio", value])
        value = %{:name => "ul", :attribute_type => "ListAttributes", :allowed_attributes => get_list_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "ul", value])
        value = %{:name => "ol", :attribute_type => "ListAttributes", :allowed_attributes => get_list_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "ol", value])
        value = %{:name => "li", :attribute_type => "ListItemAttributes", :allowed_attributes => get_list_item_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "li", value])
        value = %{:name => "table", :attribute_type => "TableAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "table", value])
        value = %{:name => "tr", :attribute_type => "TableRowAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "tr", value])
        value = %{:name => "td", :attribute_type => "TableCellAttributes", :allowed_attributes => get_table_cell_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "td", value])
        value = %{:name => "th", :attribute_type => "TableCellAttributes", :allowed_attributes => get_table_cell_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "th", value])
        value = %{:name => "meta", :attribute_type => "MetaAttributes", :allowed_attributes => get_meta_attributes(), :void_element => true}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "meta", value])
        value = %{:name => "link", :attribute_type => "LinkAttributes", :allowed_attributes => get_link_attributes(), :void_element => true}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "link", value])
        value = %{:name => "script", :attribute_type => "ScriptAttributes", :allowed_attributes => get_script_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "script", value])
        value = %{:name => "style", :attribute_type => "StyleAttributes", :allowed_attributes => get_style_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "style", value])
        value = %{:name => "article", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "article", value])
        value = %{:name => "section", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "section", value])
        value = %{:name => "nav", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "nav", value])
        value = %{:name => "aside", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "aside", value])
        value = %{:name => "header", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "header", value])
        value = %{:name => "footer", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "footer", value])
        value = %{:name => "main", :attribute_type => "SemanticAttributes", :allowed_attributes => get_global_attributes(), :void_element => false}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "main", value])
        value = %{:name => "br", :attribute_type => "GlobalAttributes", :allowed_attributes => get_global_attributes(), :void_element => true}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "br", value])
        value = %{:name => "hr", :attribute_type => "GlobalAttributes", :allowed_attributes => get_global_attributes(), :void_element => true}
        _ = apply(Map.get(g, :__reflaxe_class__) || Map.get(g, :__struct__), :set, [g, "hr", value])
        g
      end).())
  end
  def html_elements(value) do
    __haxe_static_put__(:html_elements, value)
  end
  def phoenix_components() do
    __haxe_static_get__(:phoenix_components, %{})
  end
  def phoenix_components(value) do
    __haxe_static_put__(:phoenix_components, value)
  end
  def get_element_type(element_name) do
    this1 = HXXComponentRegistry.html_elements()
    key = String.downcase(element_name)
    _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :get, [this1, key])
  end
  def list_html_elements() do
    out = []
    this1 = HXXComponentRegistry.html_elements()
    k = _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :keys, [this1])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out}, fn _, {acc_out} ->
      try do
        if (k.has_next.()) do
          k = k.next.()
          acc_out = acc_out ++ [k]
          {:cont, {acc_out}}
        else
          {:halt, {acc_out}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_out}}
        :throw, :continue ->
          {:cont, {acc_out}}
      end
    end)
    out = Enum.sort(out, fn a, b ->
      (fn a, b ->
  if (a < b) do
    -1
  else
    if (a > b), do: 1, else: 0
  end
end).(a, b) < 0
    end)
    out
  end
  def is_registered_element(element_name) do
    (fn ->
  this1 = HXXComponentRegistry.html_elements()
  key = String.downcase(element_name)
  _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :exists, [this1, key])
end).() or (fn ->
  this1 = HXXComponentRegistry.phoenix_components()
  _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :exists, [this1, element_name])
end).()
  end
  def validate_attribute(element_name, attribute_name) do
    this = HXXComponentRegistry.html_elements()
    key = String.downcase(element_name)
    element = _ = apply(Map.get(this, :__reflaxe_class__) || Map.get(this, :__struct__), :get, [this, key])
    if (Kernel.is_nil(element)) do
      this = HXXComponentRegistry.phoenix_components()
      component = _ = apply(Map.get(this, :__reflaxe_class__) || Map.get(this, :__struct__), :get, [this, element_name])
      if (not Kernel.is_nil(component)), do: validate_component_attribute(component, attribute_name), else: false
      (fn ->
  this = element.allowedAttributes
  
                case Enum.find_index(_this, fn item -> item == attribute_name end) do
                    nil -> -1
                    idx -> idx
                end
            
end).() != -1
    else
      (fn ->
  this = element.allowedAttributes
  
                case Enum.find_index(_this, fn item -> item == attribute_name end) do
                    nil -> -1
                    idx -> idx
                end
            
end).() != -1
    end
  end
  def get_allowed_attributes(element_name) do
    this1 = HXXComponentRegistry.html_elements()
    key = String.downcase(element_name)
    element = _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :get, [this1, key])
    if (not Kernel.is_nil(element)) do
      element.allowedAttributes
    else
      this1 = HXXComponentRegistry.phoenix_components()
      component = _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :get, [this1, element_name])
      if (not Kernel.is_nil(component)) do
        Enum.map(component.attributes, fn a -> a.name end)
      else
        []
      end
    end
  end
  def register_component(component) do
    this1 = HXXComponentRegistry.phoenix_components()
    key = component.name
    _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :set, [this1, key, component])
  end
  def list_phoenix_components() do
    out = []
    this1 = HXXComponentRegistry.phoenix_components()
    k = _ = apply(Map.get(this1, :__reflaxe_class__) || Map.get(this1, :__struct__), :keys, [this1])
    Enum.reduce_while(Stream.iterate(0, fn n -> n + 1 end), {out}, fn _, {acc_out} ->
      try do
        if (k.has_next.()) do
          k = k.next.()
          acc_out = acc_out ++ [k]
          {:cont, {acc_out}}
        else
          {:halt, {acc_out}}
        end
      catch
        :throw, {:break, break_state} ->
          {:halt, break_state}
        :throw, {:continue, continue_state} ->
          {:cont, continue_state}
        :throw, :break ->
          {:halt, {acc_out}}
        :throw, :continue ->
          {:cont, {acc_out}}
      end
    end)
    out = Enum.sort(out, fn a, b ->
      (fn a, b ->
  if (a < b) do
    -1
  else
    if (a > b), do: 1, else: 0
  end
end).(a, b) < 0
    end)
    out
  end
  def to_html_attribute(name) do
    (case name do
      "acceptCharset" -> "accept-charset"
      "accessKey" -> "accesskey"
      "autoComplete" -> "autocomplete"
      "autoFocus" -> "autofocus"
      "autoPlay" -> "autoplay"
      "className" -> "class"
      "colSpan" -> "colspan"
      "contentEditable" -> "contenteditable"
      "contextMenu" -> "contextmenu"
      "crossOrigin" -> "crossorigin"
      "dateTime" -> "datetime"
      "encType" -> "enctype"
      "formAction" -> "formaction"
      "formEncType" -> "formenctype"
      "formMethod" -> "formmethod"
      "formNoValidate" -> "formnovalidate"
      "formTarget" -> "formtarget"
      "frameBorder" -> "frameborder"
      "htmlFor" -> "for"
      "httpEquiv" -> "http-equiv"
      "itemProp" -> "itemprop"
      "marginHeight" -> "marginheight"
      "marginWidth" -> "marginwidth"
      "maxLength" -> "maxlength"
      "minLength" -> "minlength"
      "noValidate" -> "novalidate"
      "readOnly" -> "readonly"
      "rowSpan" -> "rowspan"
      "srcDoc" -> "srcdoc"
      "srcLang" -> "srclang"
      "srcSet" -> "srcset"
      "tabIndex" -> "tabindex"
      "useMap" -> "usemap"
      s ->
        s = name
        cond_value = (case :binary.match(s, "-") do
          {pos, _} -> pos
          :nomatch -> -1
        end)
        if (cond_value != -1) do
          s
        else
          s = name
          if (StringTools.starts_with(s, "phx_")) do
            Enum.join((fn ->
              if ("_" == "") do
                String.graphemes(s)
              else
                String.split(s, "_")
              end
            end).(), "-")
          else
            s = name
            cond_value = (case :binary.match(s, "_") do
  {pos, _} -> pos
  :nomatch -> -1
end) == -1
            if (StringTools.starts_with(s, "phx") and cond_value) do
              "phx-#{camel_to_kebab(String.slice(s, 3..-1//1))}"
            else
              s = name
              if (StringTools.starts_with(s, "aria_")) do
                Enum.join((fn ->
                  if ("_" == "") do
                    String.graphemes(s)
                  else
                    String.split(s, "_")
                  end
                end).(), "-")
              else
                s = name
                cond_value = (case :binary.match(s, "_") do
  {pos, _} -> pos
  :nomatch -> -1
end) == -1
                if (StringTools.starts_with(s, "aria") and cond_value) do
                  "aria-#{camel_to_kebab(String.slice(s, 4..-1//1))}"
                else
                  s = name
                  if (StringTools.starts_with(s, "data_")) do
                    Enum.join((fn ->
                      if ("_" == "") do
                        String.graphemes(s)
                      else
                        String.split(s, "_")
                      end
                    end).(), "-")
                  else
                    s = name
                    cond_value = (case :binary.match(s, "_") do
  {pos, _} -> pos
  :nomatch -> -1
end) == -1
                    if (StringTools.starts_with(s, "data") and cond_value) do
                      "data-#{camel_to_kebab(String.slice(s, 4..-1//1))}"
                    else
                      s = name
                      cond_value = (case :binary.match(s, "_") do
                        {pos, _} -> pos
                        :nomatch -> -1
                      end)
                      if (cond_value != -1) do
                        Enum.join((fn ->
                          if ("_" == "") do
                            String.graphemes(s)
                          else
                            String.split(s, "_")
                          end
                        end).(), "-")
                      else
                        s = name
                        if (s == String.downcase(s)), do: s, else: camel_to_kebab(name)
                      end
                    end
                  end
                end
              end
            end
          end
        end
    end)
  end
  defp camel_to_kebab(str) do
    result = ""
    _g = 0
    str_length = String.length(str)
    result = Enum.reduce(0..(str_length - 1)//1, result, fn i, result_acc ->
      char = if (i < 0) do
        ""
      else
        String.at(str, i) || ""
      end
      if (char == String.upcase(char) and i > 0) do
        result_acc <> "-" <> String.downcase(char)
      else
        result_acc <> String.downcase(char)
      end
    end)
    result
  end
  defp validate_component_attribute(component, attribute_name) do
    _g = 0
    component_attributes = component.attributes
    (case Enum.reduce_while(component_attributes, :__reflaxe_no_return__, fn attr, _ ->
  if (attr.name == attribute_name), do: {:halt, {:__reflaxe_return__, true}}, else: {:cont, :__reflaxe_no_return__}
end) do
      {:__reflaxe_return__, reflaxe_return_value} -> reflaxe_return_value
      _ ->
        (fn ->
  
                case Enum.find_index(_this, fn item -> item == attribute_name end) do
                    nil -> -1
                    idx -> idx
                end
            
end).() != -1
    end)
  end
  defp get_global_attributes() do
    ["id", "className", "style", "title", "role", "ariaLabel", "ariaLabelledby", "ariaDescribedby", "ariaHidden", "tabIndex", "phxClick", "phxChange", "phxSubmit", "phxBlur", "phxFocus", "phxKeydown", "phxKeyup", "phxMouseenter", "phxMouseleave", "phxHook", "phxTarget", "phxDebounce", "phxThrottle", "phxUpdate", "phxTrackStatic", "phxShow", "data*"]
  end
  defp get_input_attributes() do
    get_global_attributes() ++ ["type", "name", "value", "placeholder", "required", "disabled", "readonly", "autofocus", "autocomplete", "pattern", "min", "max", "minLength", "maxLength", "step", "form", "accept", "multiple", "list"]
  end
  defp get_button_attributes() do
    get_global_attributes() ++ ["type", "name", "value", "disabled", "form", "formAction", "formMethod", "formTarget", "formNoValidate"]
  end
  defp get_form_attributes() do
    get_global_attributes() ++ ["action", "method", "enctype", "target", "noValidate", "autocomplete", "phxSubmit", "phxChange", "phxTriggerAction"]
  end
  defp get_select_attributes() do
    get_global_attributes() ++ ["name", "multiple", "size", "required", "disabled", "form"]
  end
  defp get_option_attributes() do
    get_global_attributes() ++ ["value", "label", "selected", "disabled"]
  end
  defp get_text_area_attributes() do
    get_global_attributes() ++ ["name", "rows", "cols", "placeholder", "required", "disabled", "readonly", "maxLength", "minLength", "wrap", "form"]
  end
  defp get_label_attributes() do
    get_global_attributes() ++ ["htmlFor", "form"]
  end
  defp get_anchor_attributes() do
    get_global_attributes() ++ ["href", "target", "rel", "download", "hreflang", "type", "referrerPolicy", "phxLink", "phxLinkState"]
  end
  defp get_image_attributes() do
    get_global_attributes() ++ ["src", "alt", "width", "height", "loading", "decoding", "crossorigin", "srcset", "sizes", "usemap", "ismap"]
  end
  defp get_video_attributes() do
    get_global_attributes() ++ ["src", "poster", "width", "height", "autoplay", "controls", "loop", "muted", "preload", "crossorigin"]
  end
  defp get_audio_attributes() do
    get_global_attributes() ++ ["src", "autoplay", "controls", "loop", "muted", "preload", "crossorigin"]
  end
  defp get_list_attributes() do
    get_global_attributes() ++ ["reversed", "start", "type"]
  end
  defp get_list_item_attributes() do
    get_global_attributes() ++ ["value"]
  end
  defp get_table_cell_attributes() do
    get_global_attributes() ++ ["colspan", "rowspan", "headers", "scope"]
  end
  defp get_meta_attributes() do
    ["name", "content", "httpEquiv", "charset", "property"]
  end
  defp get_link_attributes() do
    ["href", "rel", "type", "media", "sizes", "crossorigin", "integrity", "referrerPolicy", "as"]
  end
  defp get_script_attributes() do
    get_global_attributes() ++ ["src", "type", "async", "defer", "crossorigin", "integrity", "noModule", "referrerPolicy"]
  end
  defp get_style_attributes() do
    get_global_attributes() ++ ["media", "nonce"]
  end
end
