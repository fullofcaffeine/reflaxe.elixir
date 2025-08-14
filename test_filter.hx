class Main {
    static function main() {
        var numbers = [1, 2, 3, 4, 5];
        var evens = numbers.filter(n -> n % 2 == 0);
        trace(evens);
    }
}
