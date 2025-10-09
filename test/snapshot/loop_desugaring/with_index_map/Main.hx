class Main {
    static function main() {
        var arr = [10, 20, 30];
        var out = [];
        var i = 0;
        while (i < arr.length) {
            out.push(arr[i] + i);
            i++;
        }
        trace(out);
    }
}

