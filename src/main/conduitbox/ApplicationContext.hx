package conduitbox;

import hxgnd.Stream;

typedef ApplicationContext<TPage: EnumValue> = {
    var pageChanged(default, null): Stream<TPage>;
}