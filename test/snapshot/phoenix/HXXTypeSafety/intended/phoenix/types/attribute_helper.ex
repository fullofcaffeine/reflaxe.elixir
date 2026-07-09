defmodule AttributeHelper do
  def to_html_attribute(name) do
    (case name do
      "ariaDescribedby" -> "aria-describedby"
      "ariaHidden" -> "aria-hidden"
      "ariaLabel" -> "aria-label"
      "ariaLabelledby" -> "aria-labelledby"
      "className" -> "class"
      "htmlFor" -> "for"
      "httpEquiv" -> "http-equiv"
      "tabIndex" -> "tabindex"
      s ->
        s = name
        if (StringTools.starts_with(s, "phx")) do
          "phx-#{String.downcase(StringTools.haxe_substring(s, 3, nil))}"
        else
          s = name
          if (StringTools.starts_with(s, "aria")) do
            "aria-#{String.downcase(StringTools.haxe_substring(s, 4, nil))}"
          else
            s = name
            if (StringTools.starts_with(s, "data")) do
              "data-#{String.downcase(StringTools.haxe_substring(s, 4, nil))}"
            else
              String.downcase(name)
            end
          end
        end
    end)
  end
end
