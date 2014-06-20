package conduitbox.types;

enum PageNavigation<TPage: EnumValue> {
    Navigate(page: TPage);
    Reload;
    Foward;
    Back;
}