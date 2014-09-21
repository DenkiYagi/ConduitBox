package conduitbox;

import hxgnd.js.Html;
import hxgnd.Stream;

typedef Frame<TPage: EnumValue> = {
    var slot(default, null): Html;
    var navigation(default, null): Stream<Navigation<TPage>>;
}
