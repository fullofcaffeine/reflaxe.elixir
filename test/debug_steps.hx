package test;

#if (macro || reflaxe_runtime)

import reflaxe.elixir.macro.HXXMacro;

class DebugSteps {
    public static function main() {
        var input = '<div lv:if="show_content">Content</div>';
        trace('Original: ${input}');
        
        // Test each step individually
        var step1 = HXXMacro.convertLiveViewDirectives(input);
        trace('After directive conversion: ${step1}');
        
        var step2 = input.replace("className=", "class=");
        trace('After className: ${step2}');
        
        var step3 = HXXMacro.convertBindings(step1);
        trace('After bindings: ${step3}');
    }
}

#end