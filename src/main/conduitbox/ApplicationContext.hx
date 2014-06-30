package conduitbox;

import hxgnd.Stream;
import conduitbox.types.Location;

typedef ApplicationContext = {
    var location(default, null): Stream<Location>;
}