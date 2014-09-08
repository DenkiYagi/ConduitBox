package conduitbox;

import hxgnd.Promise;
import hxgnd.Unit;
import hxgnd.Option;
import conduitbox.ApplicationContext;

typedef Application<TPage: EnumValue> = {
    bootstrap: Void -> Promise<Unit>,
    createFrame: ApplicationContext<TPage> -> PageFrame<TPage>,
    createRenderer: TPage -> PageRenderer<TPage>,
    locationMapping: LocationMapping<TPage>,
    ?onPageLoaded: TPage -> Void
}

enum LocationMapping<TPage: EnumValue> {
    Single(start: TPage);
    Mapping(mapper: LocationMapper<TPage>);
}

typedef LocationMapper<TPage: EnumValue> = { from: Location -> TPage, to: TPage -> Location };