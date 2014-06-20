package conduitbox.types;

import js.html.Element;
import js.support.Stream;

typedef PageContent<TPage: EnumValue> = {
    var navigation(default, null): Stream<PageNavigation<TPage>>;
    function invalidate(container: Element): Void;
    function dispose(): Void;
}
