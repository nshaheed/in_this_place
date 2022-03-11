public class VideoController {
    string address; // OSC address to contact
    float value;
    OscOut xmit;
    
    xmit.dest("localhost", 1234);
    
    fun void setValue(float val) {
        xmit.start(address);
        val => value => xmit.add;
        xmit.send();
    }
    
    fun void set(string addr, float val) {
        addr => address;
        setValue(val);
    }
}