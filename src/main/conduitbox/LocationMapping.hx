package conduitbox;

enum LocationMapping<TPage: EnumValue> {
    Single(start: TPage);
    Mapping(mapper: LocationMapper<TPage>);
}
