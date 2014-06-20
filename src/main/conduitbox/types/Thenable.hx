package conduitbox.types;

typedef Thenable<T> = {
    function then(x: T): Void;
}