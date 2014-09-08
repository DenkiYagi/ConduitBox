package conduitbox;

import hxgnd.js.JqHtml;
import js.html.Node;
import hxgnd.Stream;

typedef PageFrame<TPage: EnumValue> = {
    var navigation(default, null): Stream<PageNavigation<TPage>>;
    function createSlot(): JqHtml;
}
