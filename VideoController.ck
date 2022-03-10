public class VideoController {
    string address; // OSC address to contact
    float value;
    
    fun void setValue(float val) {
        xmit.start( "/video/player/rate" );
        val => xmit.add;    
        xmit.send();    
    }
}
