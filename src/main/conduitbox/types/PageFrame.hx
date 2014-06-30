package conduitbox.types;

import js.html.Node;
import hxgnd.Stream;

typedef PageFrame<TPage: EnumValue> = {
    var navigation(default, null): Stream<PageNavigation<TPage>>;
    function render(page: PageContent<TPage>): Void;
}
