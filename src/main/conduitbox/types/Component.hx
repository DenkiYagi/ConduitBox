package conduitbox.types;

import js.html.Node;

typedef Component<TMessage, TState, TEvent> = {
    function notify(message: TMessage): Void;
    function state(): TState;
    function then(handler: TEvent -> Void): Void;
    function appendTo(appendFn: Node -> Void): Void;
}