package conduitbox;

import hxgnd.js.Html;
import hxgnd.Promise;
import hxgnd.Stream;
import hxgnd.Unit;

typedef PageRenderer<TPage: EnumValue> = Html -> Promise<Unit> -> Stream<PageNavigation<TPage>>;
