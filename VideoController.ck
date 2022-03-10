public class VideoController {
    string address; // OSC address to contact
    float value;
    OscOut xmit;
    
    xmit.dest("localhost", 1234);
    
    fun void setValue(float val) {
        xmit.start( "/video/player/rate" );
        val => value => xmit.add;    
        xmit.send();    
    }
}