package conduitbox.types;

import hxgnd.Promise;
import hxgnd.Unit;
import hxgnd.Option;
import conduitbox.ApplicationContext;

typedef Application<TPage: EnumValue> = {
    function bootstrap(): Promise<Unit>;
    function frame(context: ApplicationContext): PageFrame<TPage>;
    function content(page: TPage): PageContent<TPage>;
    function toLocation(page: TPage): Location;
    function fromLocation(location: Location): Option<TPage>;
}