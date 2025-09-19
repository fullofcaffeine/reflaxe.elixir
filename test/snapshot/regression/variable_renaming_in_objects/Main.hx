typedef ColumnOptions = {
    ?nullable: Bool,
    ?primaryKey: Bool
}

typedef Column = {
    name: String,
    type: String,
    options: ColumnOptions
}

typedef Struct = {
    columns: Array<Column>
}

class TableBuilder {
    var columns: Array<Column>;

    public function new() {
        this.columns = [];
    }

    public function addColumn(struct: Struct, name: String, type: String, options: ColumnOptions): Struct {
        // This simulates the TableBuilder issue where columns field shadows the parameter
        var newColumns = struct.columns.concat([{name: name, type: type, options: options}]);
        return {columns: newColumns};
    }
}

class Main {
    static function main() {
        var builder = new TableBuilder();
        var struct = {columns: []};
        builder.addColumn(struct, "test", "string", {nullable: true});
    }
}