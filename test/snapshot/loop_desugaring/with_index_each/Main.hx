class Main {
    static function main() {
        var arr = [1, 2, 3];
        var i = 0;
        while (i < arr.length) {
            // Index is used; body references arr[i] and i
            trace('Item ' + arr[i] + ' @ ' + i);
            i++;
        }
    }
}

