package conduitbox;

import js.support.Stream;
import conduitbox.types.Location;

typedef ApplicationContext = {
    var location(default, null): Stream<Location>;
}