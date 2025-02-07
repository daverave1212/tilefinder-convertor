package scripts;

import com.stencyl.Engine;
import U.*;

class ChapterJourney {
    public var name: String;
    public var generationFlag: String;
    public var defaultNodeAnimation: String = 'Forest';                 // The default animation for nodes (e.g. Forest, Road, Ship, etc); setup in Chapters
    public var backgroundImagePath: String;                             // Path to the background image
    public var nTiers: Int = -1;
    public var preventMessageScreen = false;
    public var isSpecial = false;                                       // If true, will always be skipped in a normal run

    public var nodesPerTier: Int -> Int;                                // During generation, Tier Number -> Number of Nodes
    public var setupShops: Array<Array<MapNode>> -> Void;               // For setting up the shops; initially, all nodes are battlefield encounters
    public var onEveryNode: MapNode -> Int -> Array<MapNode> -> Void;   // After generation,  The Node -> Tier Number -> Tier

    var onJourneyEnd: (Void -> Void) -> Void;                           // When the journey ends, before transitioning to the next journey

    public function new(options: Dynamic) {
        assertCorrectOptions(options);
        name = options.name;
        defaultNodeAnimation = nullOr(options.defaultNodeAnimation, 'Forest');
        generationFlag = options.generationFlag;
        backgroundImagePath = nullOr(options.backgroundImagePath, 'Images/Backgrounds/MapBeach.png');
        nTiers = nullOr(options.nTiers, -1);
        nodesPerTier = options.nodesPerTier;
        setupShops = options.setupShops;
        onEveryNode = options.onEveryNode;
        onJourneyEnd = options.onJourneyEnd;
        preventMessageScreen = if (options.preventMessageScreen != null) options.preventMessageScreen else false;
        if (options.isSpecial != null) isSpecial = options.isSpecial;
    }

    public function doOnJourneyEndAndThen(andThen: Void -> Void) {
        trace('Journey ${name} has onJourneyEnd? ${onJourneyEnd != null}');
        if (onJourneyEnd != null) {
            trace('  Aight doing it.');
            onJourneyEnd(() -> {
                andThen();
            });
        } else {
            trace('  Ok nothing to do. And then...');
            andThen();
        }
    }


    function assertCorrectOptions(options: Dynamic) {
        if (options.generationFlag == 'TUTORIAL') return;
        if (options.nodesPerTier == null) throwAndLogError('Null nodesPerTier given to journey ${name}');
        if (options.setupShops == null) throwAndLogError('Null setupShops given to journey ${name}');
        if (options.onEveryNode == null) throwAndLogError('Null onEveryNode given to journey ${name}');
    }
}