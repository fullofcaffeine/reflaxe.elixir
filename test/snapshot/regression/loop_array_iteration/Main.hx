package;

/**
 * Test for loop variable substitution with array iteration
 * When iterating over arrays, loop variables should be preserved
 */
class Main {
    static function main() {
        var names = ["Alice", "Bob", "Charlie"];
        
        // Iterate over array with index
        for (i in 0...names.length) {
            trace('Person ' + i + ': ' + names[i]);
        }
        
        // Iterate over array values
        for (name in names) {
            trace('Hello, ' + name + '!');
        }
        
        // Nested iteration
        var grid = [[1, 2], [3, 4], [5, 6]];
        for (row in 0...grid.length) {
            for (col in 0...grid[row].length) {
                trace('Grid[' + row + '][' + col + '] = ' + grid[row][col]);
            }
        }
    }
}