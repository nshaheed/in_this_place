//-----------------------------------------------------------------------------
// name: LiSa-load.ck
// desc: function for loading an audio file into LiSa
//
// author: Dan Trueman, original example (2007): was LiSa-SndBuf.ck
//         Ge Wang, modified example (2021): rolled function, added twilight
//                  sound (see twilight-granular-kb-interp.ck for more info)
//                  and bi-directional loop
//-----------------------------------------------------------------------------
// this example shows how to open a soundfile and use it in LiSa. someday LiSa
// may be able to open soundfiles directly, but don't hold your breath. 
//
// note that unlike SndBuf, LiSa wants a dur (not an int) to specify the index
// of the sample location
//-----------------------------------------------------------------------------
Machine.add(me.dir() + "/ks-chord.ck");

(1.0 / 48.0)::second => dur framerate; // seconds per frame

// each one of these needs to scale the playback rate chagne based off of its base rate
// otherwise they go out of tune, which is actualy kinda cool. Maybe this could be an arc?
// progression: some amount of time with proper shepherd, then start moving out of sync.
class Bright extends Chugraph {
    1 => float rate;
    // 0 => float speed;
    // -0.00005 => float speed;
    -0.0000005 => float speed;
    // -0.00000005 => float speed;
    
    26::second => dur start;
    28::second => dur end;

    load( me.dir() + "concertina1.wav", start, end) @=> LiSa @ lisa;
    lisa => outlet;
    
    // 0.05 => r.mix;

    0.2 => lisa.gain;

    // buffer length
    1::second => dur bufferlen;

    lisa.maxVoices(60);
    
    5::ms => dur offset;
    
    209 => float minDur;
    
    spork~ run();
    
    // sporkee: a grain!
    fun void getgrain(dur grainlen, dur rampup, dur rampdown, float rate)
    {
        // get an available voice
        // lisa[which].getVoice() => int newvoice;
        lisa.getVoice() => int newvoice;
        
        // make sure we got a valid voice   
        if (newvoice < 0) return;

        // set play rate
        lisa.rate(newvoice, rate);
        // set play position
        lisa.playPos(newvoice, Math.random2f(0,1) * bufferlen);
        // set ramp up duration
        lisa.rampUp(newvoice, rampup);
        // wait for grain length (minus the ramp-up and -down)
        (grainlen - (rampup + rampdown)) => now;
        // set ramp down duration
        lisa.rampDown(newvoice, rampdown);
        // for ramp down duration
        rampdown => now;
    }
    
    fun void setVoices(int n) {
        lisa.maxVoices(n);
    }
    
    fun void run() {
        while(true) {
            // new duration
            Math.random2f(minDur, 5000)::ms => dur newdur;
            
            
            // rates[Math.random2(0, rates.cap()-1)] => newrate;
            
           // rateDelta +=> newrate;
           // 0.5 *=> newrate;

            spork ~ getgrain(newdur, 40::ms, 40::ms, rate);
            // freq
            // freqmod.last() * 400. + 800. => s.freq;
            // advance time
            
            // if (offset > 30::ms || offset < 0.5::ms) 1::ms => duration;
            offset => now;
            // <<< offset / ms >>>;            
            // -0.00000005 +=> rateDelta;
            // speed +=> rateDelta;
            // delta +=> offset;
        }
    }
}

class Shepherd extends Chugraph {
    // mean for normal intensity curve
    -1.0 => float MU;
    // standard deviation for normal intensity curve
    2 => float SIGMA;
    // normalize to 1.0 at x==MU
    1 / Math.gauss(MU, MU, SIGMA) => float SCALE;
    // increment per unit time (use negative for descending)
    0.000001 => float INC;
    // 0.00008 => float INC;
    // unit time (change interval)
    // 1::ms => dur T;
    framerate / 4 => dur T;

    // starting pitches (in MIDI note numbers, octaves apart)
    [ -3.0, -2.0, -1.0, 0] 
    // [-1.0] 
    @=> float pitches[];
    // number of tones
    pitches.size() => int N;
    // bank of tones
    Bright tones[N];
    // overall gain
    Gain internalGain => LPF f => outlet; 
    1.0/N => internalGain.gain;
    f.set(5000, 1);
    
    
    // connect to dac
    for( int i; i < N; i++ ) { tones[i] => internalGain; }
    
    for ( int i; i < N; i++ ) { -0 +=> pitches[i]; }

    // infinite time loop
    spork~ loop();
    fun void loop() {
        while( true ) {
                for( int i; i < N; i++ )
                {
                    // set frequency from pitch
                    Math.pow(2, pitches[i]) => float rate => tones[i].rate;
                    
                    
                    // compute loundess for each tone
                    Math.gauss( pitches[i], MU, SIGMA ) * SCALE => float intensity;
                    
                    // <<< i, rate, intensity >>>;
                    // map intensity to amplitude
                    intensity*96 => Math.dbtorms => tones[i].gain;
                    // increment pitch
                    INC +=> pitches[i];
                    // wrap (for positive INC)
                    if( pitches[i] > 1.0 ) -3.0 => pitches[i];
                    // wrap (for negative INC)
                    else if( pitches[i] < -3.0 ) 1.0 => pitches[i];
                }
                
                // advance time
                T => now;
            }
        }
}

/*
Shepherd s => dac;
0 => s.INC;
*/

// [-0.5, 0.75, -1, 0.6] 
[-1.0, -2.0, -0.5] @=> float rates[];

0.25::ms => dur offset;
0.1::ms => dur delta;

// OSC STUFF

// destination host name
"localhost" => string hostname;
// destination port number
1234 => int port;

// check command line
if( me.args() ) me.arg(0) => hostname;
if( me.args() > 1 ) me.arg(1) => Std.atoi => port;

// sender object
OscOut xmit;

// aim the transmitter at destination
xmit.dest( hostname, port );

// init
xmit.start( "/video/player.rate" );
2 => xmit.add;
xmit.send();

setBlend(0);
setFrame(0);
fadeIn(5::second);

0 => float rateDelta;

// 5::second => now;

spork~ bass();


Bright b1 => LPF f => NRev r => dac;
Bright b2 => f => r => dac;

0.05 => r.mix;

f.set(500, 1.5);
0.25 => f.gain;

0 => b2.gain; // phase in b2 at some point

-0.5 => b1.rate;
-0.25 => b2.rate;


controlCutoff(f);

while(true) {
    for (0 => int i; i < 50; i++) {
        74 * i + 50 => b1.minDur;
        74 * i + 50 => b2.minDur;
        74 * i + 1000 => f.freq;
        0.02 * i => setBlend;
        150::ms => now;
    }
    for (50 => int i; i > 0; i--) {
        74 * i + 50 => b1.minDur;
        74 * i + 50 => b2.minDur;
        74 * i + 1000 => f.freq;
        0.02 * i => setBlend;
        150::ms => now;
    }

}



1::week => now;

fun void controlCutoff(LPF filter) {
    Envelope e => blackhole;
    30::second => e.duration;
    // filter.freq() => e.value;
    // 20000 => e.target;
    
    <<< filter.freq() >>>;
    <<< e.value() >>>;
    <<< e.target() >>>;
    <<< e.rate() >>>;
    
    while (true) {
        5::second => now;
        e.keyOn();
        while (e.value() < e.target()) {
            // e.value() * 19000 + 500 => filter.freq;
            scale(e.value(), 0, 1, 500, 20000) => filter.freq;
            
            // <<< filter.freq() >>>;
            10::ms => now;
        }
        
        5::second => now;
        
        e.keyOff();
        
        while (e.value() > 0.0) {
            scale(e.value(), 0, 1, 500, 20000) => filter.freq;
            // <<< filter.freq() >>>;
            10::ms => now;
        }
    
    }
    
    10::second => now;
    
    e.keyOff();
    10::second => now;
    // filter
}

fun float scale(float in, float inMin, float inMax, float outMin, float outMax) {
    (in - inMin) / (inMax - inMin) => float scaled;
    return scaled * (outMax - outMin) + outMin;
}

fun void bass() {
    41::second => dur start;
    49::second => dur end;

    //28::second => start;
    //30::second => end;

    load( me.dir() + "concertina_bass2.wav", start, end) @=> LiSa @ lisabass;
    lisabass => Dyno d => NRev r => dac;
    
    0.1 => r.mix;
    
    d.compress();
    
    0.4 => lisabass.gain;

    // 20::second => now;
    1::second => now;

    while (true) {
        Math.randomf() => float chance;
        
        if (chance > 0.3) {
            <<< "bass", chance >>>;
            spork~ getgrain(lisabass, 3::second, 100::ms, 800::ms, 1);
            spork~ controlRate(3::second);
            spork~ blendASR(400::ms, 2::second, 800::ms, 0.3);

            10::second => now;
        } else {
            <<< "long bass" >>>;
            spork~ getgrain(lisabass, 5::second, 400::ms, 1600::ms, 2);
            spork~ controlRate(5::second);
            spork~ blendASR(1600::ms, 3.5::second, 2000::ms, 0.5);
            
            if (Math.random2f(0,1) > 0.5) {
                spork~ launchFloaties();
            }

            20::second => now;
        }
        // 10::second => now;
    }
}

fun void bass2() {
    TriOsc t => NRev r => dac;
    0.1 => r.mix;
    
    0.4 => t.gain;
    
    12 => Std.mtof => t.freq;
    
    
    30::second => now;
}



fun void controlRate(dur len) {
    // start the message...
    xmit.start( "/video/player/rate" );
    
    1 => xmit.add;
    
    xmit.send();

    len => now;
    
    xmit.start( "/video/player/rate" );
    
    2 => xmit.add;
    
    xmit.send();

}

fun void blendASR(dur atk, dur sustain, dur release, float gain) {
    ADSR e => blackhole;
    e.set(atk, 0::ms, 1.0, release);
    
    e.keyOn();
    
    while(e.value() < e.target()) {
        e.value() * gain => setBlend;
        framerate => now;
    }
    e.value() * gain => setBlend;

    
    sustain => now;
    
    e.keyOff();
    while(e.value() > 0.0) {
        e.value() * gain => setBlend;
        framerate => now;
    }
}

fun void setBlend(float val) {
    xmit.start( "/video/player/blend" );
    val=> xmit.add;
    xmit.send();
}

fun void setFrame(int frame) {
    xmit.start( "/video/player/frame" );
    
    frame => xmit.add;
    
    xmit.send();
}

fun void fadeIn(dur d) {
    // now + d => time until;
    
    xmit.start("/video/player/fade");
    
    1 => xmit.add;
    
    xmit.send();

    
    /*
    // TODO
    while(now < until) {
        xmit.start( "/video/player/fade" );
    
        frame => xmit.add;
    
        xmit.send();
    }
    */
}

 
fun void launchFloaties() {
    load( me.dir() + "concertina1.wav", 25.9::second, 33::second) @=> LiSa @ floaties1;
    load( me.dir() + "concertina1.wav", 25.9::second, 33::second) @=> LiSa @ floaties2;
    
    <<< "floaties" >>>;
    
    // Need for stereo reverb
    NRev rl => dac;
    NRev rr => dac;
   
    0.25 => rl.mix => rr.mix;
    
    floaties1 => Pan2 p1;
    floaties2 => Pan2 p2;
    
    p1.left => rl;
    p2.left => rl;
    p1.right => rr;
    p2.right => rr;
    
    -0.75 => p1.pan;
    0.75 => p2.pan;
    
    
    Math.random2(4,8) => int count;
    // 1 => count;
    for (0 => int i; i < count; i++ ) {
        
        [0.5, 1.0, 2.0] @=> rates;
        rates[Math.random2(0,rates.cap()-1)] => float rate;
        
        if(Math.random2f(0,1) > 0.5) {
            -1 *=> rate;
        }
        
        if (i % 2 == 0) {
            spork~ getgrain2(floaties1, 3::second, 1000::ms, 1000::ms, 1 * rate);
        } else {
            spork~ getgrain2(floaties2, 3::second, 1000::ms, 1000::ms, 1 * rate);
        }
        
        framerate * 6 * Std.fabs(rate) => now;
    }
    
    5::second => now;

}
    
// sporkee: a grain!
fun void getgrain( LiSa lisa, dur grainlen, dur rampup, dur rampdown, float rate )
{
    5::second => dur bufferlen;
    // get an available voice
    // lisa[which].getVoice() => int newvoice;
    lisa.getVoice() => int newvoice;
    
    // make sure we got a valid voice   
    if (newvoice < 0) return;
        

    // set play rate
    lisa.rate(newvoice, rate);
    // set play position
    lisa.playPos(newvoice, Math.random2f(0,1) * bufferlen);
    // set ramp up duration
    lisa.rampUp(newvoice, rampup);
    // wait for grain length (minus the ramp-up and -down)
    (grainlen - (rampup + rampdown)) => now;
    // set ramp down duration
    lisa.rampDown(newvoice, rampdown);
    // for ramp down duration
    rampdown => now;
}

// sporkee: a grain!
fun void getgrain2( LiSa lisa, dur grainlen, dur rampup, dur rampdown, float rate )
{
    5::second => dur bufferlen;
    1 => lisa.loop;
    1 => lisa.bi;
    // get an available voice
    // lisa[which].getVoice() => int newvoice;
    lisa.getVoice() => int newvoice;
    
    // make sure we got a valid voice   
    if (newvoice < 0) return;

    // set play rate
    lisa.rate(newvoice, rate);
    
    Math.random2f(0,1) => float pos;
    // set play position
    lisa.playPos(newvoice, pos * bufferlen);
    // set ramp up duration
    lisa.rampUp(newvoice, rampup);
    // wait for grain length (minus the ramp-up and -down)
    (grainlen - (rampup + rampdown)) => now;
    // set ramp down duration
    lisa.rampDown(newvoice, rampdown);
    // for ramp down duration
    rampdown => now;
}


// create a new LiSa pre-loaded with the specified file
fun LiSa load( string filename, dur start, dur end )
{
    // sound buffer
    SndBuf buffy;
    // load it
    filename => buffy.read;
    
    end - start => dur totalDur;

    // instantiate new LiSa (will be returned)
    LiSa lisa;
    // set duration
    totalDur => lisa.duration;

    // transfer values from SndBuf to LiSa
    for( 0 => int i; i < totalDur / samp; i++ )
    {
        // args are sample value and sample index
        // (dur must be integral in samples)
        i + (start / samp) $ int => int currSamp;
        lisa.valueAt( buffy.valueAt(currSamp), i::samp );        
    }

    // set default LiSa parameters; actual usage parameters intended
    // to be set to taste by the user after this function returns
    lisa.play( false );
    lisa.loop( false );

    return lisa;
}
