package;

import ecto.TableBuilder;

typedef ColumnOptions = {
    ?nullable: Bool,
    ?primaryKey: Bool
}

typedef Column = {
    name: String,
    type: String,
    options: ColumnOptions
}

typedef TableStruct = {
    columns: Array<Column>
}

class Main {
    static function main() {
        var builder = new TableBuilder();
        var table: TableStruct = {columns: []};
        table = builder.addColumn(table, "id", "integer", {primaryKey: true});
        table = builder.addColumn(table, "name", "string", {nullable: false});
    }
}