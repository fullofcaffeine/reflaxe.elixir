package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.macro.HXXMacro;

class Debug {
    public static function main() {
        trace("Testing HXX transformation...");
        
        var conditionalJSX = '<div lv:if="show_content">Content</div>';
        var result = HXXMacro.transformAdvanced(conditionalJSX);
        
        trace('Input: ${conditionalJSX}');
        trace('Output: ${result}');
        trace('Contains :if={@show_content}: ${result.contains(':if={@show_content}')}');
    }
}

#end