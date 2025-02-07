
package scripts;

import com.stencyl.Engine;

class GameChapter {
    public var name: String;
    public var bannerAnimation: String;
    public var journeys: Array<ChapterJourney>;
    public var onStart: (Void -> Void) -> Void;     // callback -> Void
    public function new(options: {
        name: String,
        bannerAnimation: String,
        journeys: Array<ChapterJourney>,
        ?onStart: (Void -> Void) -> Void             // Will first execute this function, then the given callback
    }) {
        name = options.name;
        bannerAnimation = options.bannerAnimation;
        journeys = options.journeys;
        if (options.onStart != null) onStart = options.onStart;
    }

    public function doOnStartEventAndThen(andThen: Void -> Void) {
        if (onStart != null) {
            onStart(andThen);
        } else {
            andThen();
        }
    }
}