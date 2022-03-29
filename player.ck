public class Player {
    // seconds per frame
    (1.0 / 30.0)::second => dur framerate; 

    // init video player controls
    CREnv rate;
    CREnv blend;
    CREnv fade;
    CREnv peak;
    CREnv scale;
    VideoController frame;

    // start at 2, address, control rate
    rate.set("/video/player/rate", 2.0, framerate);
    blend.set("/video/player/blend", 0.0, framerate);
    fade.set("/video/player/fade", 0.0, framerate);
    peak.set("/video/player/peak", -6.5, framerate);
    scale.set("/video/player/scale", 0, framerate);
    frame.set("/video/player/frame", 0);
}