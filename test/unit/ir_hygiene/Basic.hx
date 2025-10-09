package test.unit.ir_hygiene;

class Basic {
    static function main() {
        // Placeholder unit compile: ensure symbol IR API is visible when enabled
        #if enable_symbol_ir
        // Sanity: create a minimal symbol and scope if types exist
        #if (macro || reflaxe_runtime)
        // No-op: this test only verifies compilation with the flag
        #end
        #end
    }
}

