package conduitbox;

import hxgnd.js.Html;
import hxgnd.Promise;
import hxgnd.Stream;
import hxgnd.Unit;

typedef Application<TPage: EnumValue> = {
    bootstrap: Void -> Promise<Unit>,
    createFrame: Stream<TPage> -> Frame<TPage>,
    renderPage: TPage -> Html -> Promise<Unit> -> Promise<Navigation<TPage>>,
    locationMapping: LocationMapping<TPage>,
    ?onPageRendered: TPage -> Void
}
