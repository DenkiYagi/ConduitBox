package conduitbox;

enum Navigation<TPage: EnumValue> {
    Navigate(page: TPage);
    Reload;
    Foward;
    Back;
}