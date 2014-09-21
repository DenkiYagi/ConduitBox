package conduitbox;

import conduitbox.Application;
import conduitbox.LocationTools;
import conduitbox.PageFrame;
import conduitbox.PageNavigation;
import hxgnd.js.Html;
import hxgnd.js.JQuery;
import hxgnd.PromiseBroker;
import hxgnd.StreamBroker;
import hxgnd.Unit;
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
    var application: Application<TPage>;
    var frame: PageFrame<TPage>;
    var navigation: StreamBroker<TPage>;
    var currentPage: RenderedPage<TPage>; //mutable

    public function new(app: Application<TPage>) {
        this.navigation = new StreamBroker();
        this.application = app;

        setLocationHanlder(app.locationMapping);

        app.bootstrap().then(function onStartup(_) {
            var ctx = { pageChanged: navigation.stream };
            this.frame = app.createFrame(ctx);
            frame.navigation.then(onPageNavigation);

            currentPage = renderPage(switch (app.locationMapping) {
                case Single(x): x;
                case Mapping(mapper): mapper.from(LocationTools.currentLocation());
            });
        });
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
                navigate(mapper.from(LocationTools.toLocation(elem)));
            }
        });
    }

    function setHistoryHanlder(mapper: LocationMapper<TPage>) {
        History.Adapter.bind(Browser.window, "statechange", function () {
            replacePage(mapper.from(LocationTools.currentLocation()));
        });
    }

    function navigate(page: TPage) {
        switch (application.locationMapping) {
            case Single(_):
                replacePage(page);
            case Mapping(mapper):
                var location = mapper.to(page);
                // TODO History.pushState("{param=1}", null, "url"));みたいにしないと、IE8/9が対応できない
                History.pushState({ }, null, LocationTools.toUrl(location));
        }
    }

    function replacePage(page: TPage) {
        destroyPage(currentPage);
        currentPage = renderPage(page);

        navigation.update(page);
        if (application.onPageLoaded != null) {
            try {
                application.onPageLoaded(page);
            } catch (err: Dynamic) {
                trace(err);
            }
        }
    }

    function renderPage(page: TPage) {
        var slot = frame.createSlot();
        var broker = new PromiseBroker();
        var nav = application.renderPage(page, slot, broker.promise); //TODO navはpromiseで良い
        nav.then(onPageNavigation);

        return {
            page: page,
            slot: slot,
            closedBroker: broker
        };
    }

    function destroyPage(page: RenderedPage<TPage>) {
        if (page != null) {
            page.closedBroker.fulfill(Unit._);
            page.slot.off();
            page.slot.find("*").off();
            page.slot.remove();
        }
    }

    function onPageNavigation(navigation) {
        try {
            switch (navigation) {
                case PageNavigation.Navigate(x): //!
                    navigate(x);
                case PageNavigation.Reload:
                    if (currentPage != null) replacePage(currentPage.page);
                case PageNavigation.Foward:
                    switch (application.locationMapping) {
                        case Mapping(_):
                            History.forward();
                        case Single(_):
                            trace("unsuppoted navigation");
                    }
                case PageNavigation.Back:
                    switch (application.locationMapping) {
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

private typedef RenderedPage<TPage: EnumValue> = {
    var page(default, null): TPage;
    var slot(default, null): Html;
    var closedBroker(default, null): PromiseBroker<Unit>;
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