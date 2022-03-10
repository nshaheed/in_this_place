public class CREnv {
    Envelope e => blackhole;
    VideoController vc;
    1::second => dur rate;
    
    spork~ run();
    
    fun void run() {
        while(true) {
            if (vc != null) {
                e.value() => vc.setValue;
            }
            rate => now;
        }
    }
    
    fun void set(VideoController vidCon, float value, float target, dur duration, dur ctrl_rate) {
        vidCon @=> vc;
        ctrl_rate => rate;
        value => e.value;
        target => e.target;
        duration => e.duration;
    }
    
    fun void set(VideoController vidCon, float target, dur duration, dur ctrl_rate) {
        vidCon @=> vc;
        ctrl_rate => rate;
        target => e.target;
        duration => e.duration;
    }
    
    fun void set(VideoController vidCon, dur duration, dur ctrl_rate) {
        vidCon @=> vc;
        ctrl_rate => rate;
        duration => e.duration;
    }
    
    fun void value(float val) {
        val => e.value;
    }
    
    fun void target(float tar) {
        tar => e.target;
    }
    
    fun void duration(dur d) {
        d => e.duration;
    }
    
    fun dur getDuration() {
        return e.duration();
    }
    
    fun void keyOn() {
        e.keyOn();
    }
    
    fun void keyOff() {
        e.keyOff();
    }
    
    
}