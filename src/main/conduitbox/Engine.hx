package conduitbox;

import hxgnd.js.Html;
import hxgnd.PromiseBroker;
import hxgnd.Stream;
import hxgnd.StreamBroker;
import hxgnd.Unit;
import conduitbox.Application;
import conduitbox.internal.LocationTools;
import conduitbox.PageFrame;
import conduitbox.PageNavigation;
import js.Browser;
import js.html.EventTarget;

using hxgnd.OptionTools;

class Engine<TPage: EnumValue> {
    var application: Application<TPage>;
    var frame: PageFrame<TPage>;
    var navigation: StreamBroker<TPage>;
    var pageChanged: Stream<TPage>;

    //mutable
    var currentPage: CurrentPage<TPage>;

    public function new(app: Application<TPage>) {
        this.navigation = new StreamBroker();
        this.application = app;
        this.pageChanged = navigation.stream;

        app.bootstrap().then(function onStartup(_) {
            var startPage = switch (app.locationMapping) {
                case Single(x): x;
                case Mapping(mapper): mapper.from(LocationTools.currentLocation());
            }

            var ctx = { pageChanged: pageChanged };
            this.frame = app.createFrame(ctx);

            renderPage(startPage);
            frame.navigation.then(onNavigate);

            switch (app.locationMapping) {
                case Mapping(mapper):
                    History.Adapter.bind(Browser.window, "statechange", function onStateChange() {
                        var data: { ?ignore: Bool } = History.getState().data;
                        if (data.ignore != true) renderPage(mapper.from(LocationTools.currentLocation()));
                    });
                case _:
            }
        });
    }

    function renderPage(page: TPage) {
        try {
            if (currentPage != null) {
                currentPage.closedBroker.fulfill(Unit._);
                currentPage.slot.off();
                currentPage.slot.find("*").off();
                currentPage.slot.remove();
            }

            var slot = frame.createSlot();

            var broker = new PromiseBroker();
            var render = application.createRenderer(page);
            var nav = render(slot, broker.promise);
            nav.then(onNavigate);

            currentPage = {
                page: page,
                slot: slot,
                closedBroker: broker
            };

            navigation.update(page);
            if (application.onPageLoaded != null) {
                try {
                    application.onPageLoaded(page);
                } catch (error: Dynamic) {
                    trace(error);
                }
            }
        }
    }

    function onNavigate(navigation) {
        try {
            switch (navigation) {
                case PageNavigation.Navigate(x): //!
                    renderPage(x);
                    switch (application.locationMapping) {
                        case Mapping(mapper):
                            var location = mapper.to(x);
                            // TODO History.pushState("{param=1}", null, "url"));みたいにしないと、IE8/9が対応できない
                            History.pushState({ignore: true}, null, LocationTools.toUrl(location));
                        case Single(_):
                    }
                case PageNavigation.Reload:
                    if (currentPage != null) renderPage(currentPage.page);
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

    public static function start<TPage: EnumValue>(app: Application<TPage>): Void {
        new Engine(app);
    }
}

private typedef CurrentPage<TPage: EnumValue> = {
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