package conduitbox;

typedef LocationMapper<TPage: EnumValue> = {
    toPage: Location -> TPage,
    toLocation: TPage -> Location
};