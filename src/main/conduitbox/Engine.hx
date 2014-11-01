package conduitbox;

import conduitbox.Application;
import conduitbox.Frame;
import conduitbox.Navigation;
import hxgnd.js.JQuery;
import hxgnd.Promise;
import hxgnd.PromiseBroker;
import hxgnd.StreamBroker;
import hxgnd.Unit;
import hxgnd.Option;
import js.Browser;
import js.html.AnchorElement;
import js.html.Event;
import js.html.EventTarget;

class Engine {
    public static var currentLocation(get, null): Location;
    public static var currentUrl(get, null): String;

    public static function start<TPage: EnumValue>(app: Application<TPage>): Void {
        new AppController(app);
    }

    static function get_currentLocation() {
        return LocationTools.currentLocation();
    }

    static function get_currentUrl() {
        return LocationTools.currentUrl();
    }
}

private class AppController<TPage: EnumValue> {
    var app: Application<TPage>;
    var frame: Frame<TPage>;
    var onPageChangeBroker: StreamBroker<TPage>;
    var currentPage: RenderedPage<TPage>; //mutable

    public function new(app: Application<TPage>) {
        this.app = app;
        this.onPageChangeBroker = new StreamBroker();

        switch (getRedirectUrl()) {
            case Some(x):
                Browser.location.replace(x);
            case None:
                app.bootstrap().then(function onStartup(_) {
                    this.frame = app.createFrame(onPageChangeBroker.stream);
                    frame.navigation.then(onPageNavigation);
                    renderPage(switch (app.locationMapping) {
                        case Single(x): x;
                        case Mapping(mapper): mapper.toPage(LocationTools.currentLocation());
                    });
                });
        }
    }

    function getRedirectUrl() {
        return switch (app.locationMapping) {
            case Mapping(mapper):
                var location = LocationTools.currentLocation();
                var ereg = new EReg("([^;]+);jsessionid=(?:\\w+)$", "");
                if (ereg.match(location.path)) {
                    Option.Some(LocationTools.toUrl({
                        path: ereg.matched(1),
                        query: location.query,
                        hash: location.hash
                    }));
                } else {
                    Option.None;
                }
            case _:
            Option.None;
        }
    }

    function setLocationHanlder(mapping: LocationMapping<TPage>) {
        switch (mapping) {
            case Mapping(mapper):
                setNavigationAnchorHanlder(mapper);
                setHistoryHanlder(mapper);
            case _:
                // nop
        }
    }

    function setNavigationAnchorHanlder(mapper: LocationMapper<TPage>) {
        JQuery._("body").on("click", "a[data-navigation]", function (event: Event) {
            var elem = cast(event.target, AnchorElement);
            if (elem.protocol == Browser.location.protocol && elem.host == Browser.location.host) {
                event.preventDefault();
                navigate(mapper.toPage(LocationTools.toLocation(elem)));
            }
        });
    }

    function setHistoryHanlder(mapper: LocationMapper<TPage>) {
        History.Adapter.bind(Browser.window, "statechange", function () {
            renderPage(mapper.toPage(LocationTools.currentLocation()));
        });
    }

    function navigate(page: TPage) {
        switch (app.locationMapping) {
            case Single(_):
                renderPage(page);
            case Mapping(mapper):
                // Mappingの場合は、history.statechangeで画面遷移を行う
                var location = mapper.toLocation(page);
                History.pushState({ }, null, LocationTools.toUrl(location));
                // TODO History.pushState("{param=1}", null, "url"));みたいにしないと、IE8/9が対応できない
        }
    }

    function renderPage(page: TPage) {
        var isInit = currentPage == null;

        if (!isInit) {
            currentPage.onClosedBroker.fulfill(Unit._);
            currentPage.navigation.cancel();

            frame.slot.off();
            frame.slot.find("*").off();
            frame.slot.empty();
        }

        currentPage = {
            var onClosed = new PromiseBroker();
            var navigation = app.renderPage(page, frame.slot, onClosed.promise);
            navigation.then(onPageNavigation);
            { page: page, navigation: navigation, onClosedBroker: onClosed };
        }

        if (!isInit) onPageChangeBroker.update(page);
        if (app.onPageRendered != null) {
            try {
                app.onPageRendered(page);
            } catch (err: Dynamic) {
                trace(err);
            }
        }
    }

    function onPageNavigation(navigation) {
        try {
            switch (navigation) {
                case Navigation.Navigate(x): //!
                    navigate(x);
                case Navigation.Reload:
                    if (currentPage != null) renderPage(currentPage.page);
                case Navigation.Foward:
                    switch (app.locationMapping) {
                        case Mapping(_):
                            History.forward();
                        case Single(_):
                            trace("unsuppoted navigation");
                    }
                case Navigation.Back:
                    switch (app.locationMapping) {
                        case Mapping(_):
                            History.back();
                        case Single(_):
                            trace("unsuppoted navigation");
                    }
            }
        } catch (error: Dynamic) {
            // TODO エラー通知
            trace(error);
        }
    }
}

private class LocationTools {
    public static function currentLocation(): Location {
        trace(Browser.location);
        return toLocation(Browser.location);
    }

    public static function currentUrl(): String {
        return toUrl(toLocation(Browser.location));
    }

    public static function toLocation(x: {pathname: String, search: String, hash: String}): Location {
        function toQueryMap(search: String) {
            var map = new Map();
            if (search.length > 0) {
                for (item in search.substring(1).split("&")) {
                    var tokens = item.split("=");
                    var key = StringTools.urlDecode(tokens[0]);
                    var val = (tokens[1] == null) ? "" : StringTools.urlDecode(tokens[1]);
                    map[key] = val;
                }
            }
            return map;
        }
        return {
            path: x.pathname,
            query: toQueryMap(x.search),
            hash: x.hash
        };
    }

    public static function toUrl(location: Location): String {
        function toQuery(query: Null<Map<String, String>>) {
            var entries = [];
            if (query != null) {
                for (k in query.keys()) {
                    entries.push('${StringTools.htmlEscape(k)}=${StringTools.htmlEscape(query.get(k))}');
                }
            }
            return Lambda.empty(entries) ? "" : '?${entries.join("&")}';
        }

        function toHash(hash: Null<String>) {
            return (hash == null || hash == "") ? "": '#$hash';
        }

        return '${location.path}${toQuery(location.query)}${toHash(location.hash)}';
    }
}

private typedef RenderedPage<TPage: EnumValue> = {
    var page(default, null): TPage;
    var navigation(default, null): Promise<Navigation<TPage>>;
    var onClosedBroker(default, null): PromiseBroker<Unit>;
}

@:native("History")
private extern class History {
    static function pushState(data: Null<Dynamic>, title: Null<String>, url: String): Bool;
    static function getState(): HistoryState;
    static function forward(): Void;
    static function back(): Void;

    static var Adapter: {
        function bind(element: EventTarget, name: String, handler: Void -> Void): Void;
    };
}

private typedef HistoryState = {
    var data(default, null): Dynamic;
}