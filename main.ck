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

(1.0 / 30.0)::second => dur framerate; // seconds per frame

700 => float filterCutoffMax; // set the filter cutoff max freq that the sweep will use
// 20000 => filterCutoffMax;


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

[-1.0, -2.0, -0.5] @=> float rates[];

0.25::ms => dur offset;
0.1::ms => dur delta;

// init video player controls
CREnv playerRate;
CREnv playerBlend;
CREnv playerFade;
CREnv playerPeak;
CREnv playerScale;
VideoController playerFrame;

// start at 2, address, control rate
playerRate.set("/video/player/rate", 2.0, framerate);
playerBlend.set("/video/player/blend", 0.0, framerate);
playerFade.set("/video/player/fade", 0.0, framerate);
playerPeak.set("/video/player/peak", -6.5, framerate);
playerScale.set("/video/player/scale", 0, framerate);
playerFrame.set("/video/player/frame", 0);


// two lisas for spatialization
load( me.dir() + "concertina1.wav", 25.9::second, 33::second) @=> LiSa @ floaties1;
load( me.dir() + "concertina1.wav", 25.9::second, 33::second) @=> LiSa @ floaties2;

// 10::second => now;

// Set up gverb
GVerb r => dac;

50 => r.roomsize;
0.5::second => r.revtime;
0.3 => r.dry;
0.1 => r.early;
0.1 => r.tail;


spork~ fadeIn(10::second);

0 => float rateDelta;

// 5::second => now;
// bass2();


Bright b1 => ADSR e1 => LPF f => Pan2 p => r => dac;;
// NRev r => dac;
Bright b2 => ADSR e2 => f;
Bright b3 => ADSR e3 => f;


/*
p.left => NRev r1 => dac.left;
p.right => NRev r2 => dac.right;

0.05 => r.mix => r1.mix => r2.mix;
*/

f.set(500, 1.5);
0.25 => f.gain;

// 0 => b2.gain; // phase in b2 at some point
1 => b2.gain;

-0.5 => b1.rate;
-0.25 => b2.rate;
-1.0 => b3.rate;

e1.set(5::second, 0::ms, 1, 5::second);
e2.set(20::ms, 8::ms, 0.9, 20::second);
e3.set(10::second, 8::ms, 0.9, 1::second);

spork~ controlCutoffBounds();
spork~ brightPan();
spork~ watchFilterCutoff();
spork~ controlCutoff(f);

// the score - all time advances should be handled here
e1.keyOn();

/*
20::second => now;
introBass();
bassSection1();
bassTransition();
*/
e2.keyOn();
e3.keyOn();
// bassSection2();
10::second => now;
outro();

1::week => now;

fun void controlCutoff(LPF filter) {
    Envelope e => blackhole;
    30::second => e.duration;
    
    while (true) {
        5::second => now;
        // e2.keyOn();
        e.keyOn();
        
        filterCutoffMax => float currMax;
        <<< "new cutoff max", currMax >>>;
        while (e.value() < e.target()) {
            scale(e.value(), 0, 1, 500, currMax) => filter.freq;
            10::ms => now;
        }
        
        // 1 => b2.gain;
        5::second => now;
        
        e.keyOff();
        
        while (e.value() > 0.0) {
            scale(e.value(), 0, 1, 500, currMax) => filter.freq;
            10::ms => now;
        }
    
    }
    
    10::second => now;
    
    e.keyOff();
    10::second => now;
    // filter
}

fun void brightPan() {
    SinOsc s => blackhole;
    0.04 => s.freq;
    0 => p.pan;
    
    while (true) {
        scaleCutoff(0, 0.75) * s.last() => p.pan;
        1::ms => now;
    }
}

// adjust b3's gain depending on cutoff freq.
fun void controlB3() {
    while (true) {
        scaleCutoff(0.75, 2) => b3.gain;
        5::ms => now;
    }
}
// the score for controlling cutoff bounds.
fun void controlCutoffBounds() {
    
    5::second => now;
    
    Envelope e => blackhole;
    2::minute => e.duration;
    
    e.keyOn();
    
    while(e.value() < e.target()) {
        scale(e.value(), 0, 1, 700, 20000) => filterCutoffMax;
        300::ms => now;
    }
    1::minute => now;
    e.keyOff();
    while(e.value() > 0) {
        scale(e.value(), 0, 1, 700, 20000) => filterCutoffMax;
        300::ms => now;
    }
}

fun float scale(float in, float inMin, float inMax, float outMin, float outMax) {
    (in - inMin) / (inMax - inMin) => float scaled;
    return scaled * (outMax - outMin) + outMin;
}

fun void introBass() {
    [-2.0, -5] @=> float peakTargets[];
    [0.0, 6] @=> float scaleTargets[];
    [2.0, 1] @=> float rateTargets[];
    [10::second, 8.8::second] @=> dur durValues[];
    
    for (0 => int i; i < 2; i++) {
        durValues[i] => playerPeak.duration;
        peakTargets[i] => playerPeak.target;
        playerPeak.keyOn();
        
        durValues[i] => playerScale.duration;
        scaleTargets[i] => playerScale.target;
        playerScale.keyOn();
        
        spork~ bass2(25::ms, 5::second, 1600::ms);
        spork~ rateASR(0::ms, 5400::ms, 2400::ms, rateTargets[i], false);

        15::second => now;
    }
}

fun void bassSection1() {
    6 => playerScale.target;
    1::ms => playerScale.duration;
    playerScale.keyOn();
    
    -5 => playerPeak.target;
    1::ms => playerPeak.duration;
    playerPeak.keyOn();
    

    bass(false, -5, -0.5);
}

fun void bassSection2() {
    6 => playerScale.target;
    1::ms => playerScale.duration;
    playerScale.keyOn();
    
    0 => playerPeak.target;
    1::ms => playerPeak.duration;
    playerPeak.keyOn();
    

    bass(true, 0, 1);
  
}

fun void bassTransition() {
    <<< "transition bass" >>>;
    
    // set video player state
    6 => playerScale.target;
    1::ms => playerScale.duration;
    playerScale.keyOn();
    
    -5 => playerPeak.target;
    1::ms => playerPeak.duration;
    playerPeak.keyOn();

    // play audio/video
    spork~ bassTransitionVideo();
    bass2Cresc(25::ms, 5::second, 6500::ms);
}

fun void bassTransitionVideo() {
    spork~ rateASR(0::ms, 5::second, 2000::ms, 1, false);
    spork~ blendASR(1600::ms, (5-1.6)::second, 3000::ms, 0.5);
    
    1.6::second + (5-1.6)::second => now;
    0 => playerPeak.target;
    20::second => playerPeak.duration;
    playerPeak.keyOn();

}

fun void bass(int firstFloaty, float peakMin, float peakMax) {
    0 => int counter;

    while (counter < 4) {
        Math.randomf() => float chance;
        <<< "chance", chance >>>;

        1 => chance;
        if (chance > 0.4) {
            <<< "bass", counter >>>;
            spork~ bass2(25::ms, 4::second, 1400::ms);

            Math.randomf() => float chance;

            // scale chance of activating floaties by filter cutoff
            float floatChance;
            if (f.freq() < 2000) {
                0 => floatChance;
            } else {
                scale(f.freq(), 2000, 20000, 0.2, 0.9) => floatChance;
            }

            if (chance < floatChance || firstFloaty) {
                spork~ launchFloaties(peakMin, peakMax);
            }

            false => int negate;
            spork~ rateASR(0::ms, 5400::ms, 2400::ms, 1, negate);

            0.3 => float blendVal;
            7000::ms => dur blendRelease;

            // don't want to adjust blend while things the fade in is happening
            // spork~ blendASR(1600::ms, 4::second, blendRelease, blendVal);
            spork~ blendASR(2000::ms, (4000-2000)::ms, blendRelease, blendVal);

            15::second => now;
        } else {
            <<< "long bass", counter >>>;
            spork~ bass2(25::ms, 5::second, 1600::ms);
            spork~ rateASR(0::ms, 5::second, 2000::ms, 1, false);

            // don't want to adjust blend while things the fade in is happening
            spork~ blendASR(1600::ms, (5-1.6)::second, 3000::ms, 0.5);

            // scale chance of activating floaties by filter cutoff
            scaleCutoff(0.75, 1) => float floatChance;
            if (Math.randomf() < floatChance) {
                spork~ launchFloaties(peakMin, peakMax);
            }

            20::second => now;
        }
        1 +=> counter;
    }
}

fun void bass2(dur atk, dur sustain, dur release) {
    Blit t1 => ADSR e => Gain g => GVerb r => dac;
    Blit t2 => e;
    Blit t3 => Envelope e2 => e;
    // 0.1 => r.mix;
    
    50 => r.roomsize;
    0.5::second => r.revtime;
    0.3 => r.dry;
    0.1 => r.early;
    0.1 => r.tail;
    
    Math.random2(2,4) => t1.harmonics => t2.harmonics;
    Math.random2(3,5) => t3.harmonics;
    
    (sustain-1::second)/2 => e2.duration;
    
    <<< "bass2:", t1.harmonics(), "harmonics" >>>;
    
    2 => g.gain;
    
    0.4 => float gainScale;
    1 * gainScale => t1.gain;
    0.5 * gainScale => t2.gain;
    0.25 * gainScale => t3.gain;
 
    
    36 => Std.mtof => t1.freq;
    48.05 => Std.mtof => t2.freq;
    60.05 => Std.mtof => t3.freq;
    
    e.set(atk, 100::ms, 0.5, release);
    
    e.keyOn();
    atk + 100::ms => now;
    
    1::second => now;
    e2.keyOn();    
    (sustain-1::second)/2 => now;
    
    e2.keyOff();
    (sustain-1::second)/2 => now;
    
    e.keyOff();
    release => now;
    2::second => now;
}

fun void bass2Cresc(dur atk, dur sustain, dur release) {
    Blit t1 => ADSR e => Gain g => GVerb r => dac;
    Blit t2 => e;
    Blit t3 => Envelope e2 => g;
    Blit t4 => Envelope e3 => g;
    // 0.1 => r.mix;
    
    50 => r.roomsize;
    0.5::second => r.revtime;
    0.3 => r.dry;
    0.1 => r.early;
    0.1 => r.tail;
    
    Math.random2(2,4) => t1.harmonics => t2.harmonics;
    Math.random2(5,5) => t3.harmonics => t4.harmonics;
    
    0.5 => t3.phase;
    
    sustain => e2.duration => e3.duration;
    
    <<< "bass2cresc:", t1.harmonics(), "harmonics" >>>;
    
    2.2 => g.gain;
    
    0.4 => float gainScale;
    1 * gainScale => t1.gain;
    0.5 * gainScale => t2.gain;
    0.25 * gainScale => t3.gain;
    0.5 * gainScale => t4.gain;
 
    
    36 => Std.mtof => t1.freq;
    48.05 => Std.mtof => t2.freq;
    60.05 => Std.mtof => t3.freq;
    67.05 => Std.mtof => t4.freq;
    
    e.set(atk, 100::ms, 0.5, release);
    
    e.keyOn();
    atk + 100::ms => now;
    
    1::second => now;
    0.5 => e2.target;
    e2.keyOn();    
    sustain => now;
    e.keyOff();

    0.7 => float ratio;
    release * ratio => e2.duration => e3.duration;
    <<< "keyoff" >>>;
    //e2.keyOn();
    sustain =>now;
    0.5 => e2.target => e3.target;
    e2.keyOn();
    e3.keyOn();
    release * ratio => now;
    
    2 => e3.target;
    release * (1-ratio) => e2.duration => e3.duration;
    e2.keyOn();
    e3.keyOn();
    release * (1-ratio) => now;
    
    // 2::second => now;
    
    0.15::second => now;
    
    2::ms => e2.duration;
    2::ms => e3.duration;
    0.25 => e3.target;
    
    e2.keyOff();
    e3.keyOn();
    2::ms => now;
    
    e3.keyOff();
    release * 1.75 => e3.duration;

}

// controlling the outro
fun void outro() {
    <<< "outro" >>>;

    6 => playerScale.target;
    1::ms => playerScale.duration;
    playerScale.keyOn();

    0 => playerPeak.target;
    1::ms => playerPeak.duration;
    playerPeak.keyOn();

    1::ms => now;

    e1.keyOff();
    e2.keyOff();

    -2 => playerPeak.target;
    10::second => playerPeak.duration;
    playerPeak.keyOn();

    0 => playerScale.target;
    10::second => playerScale.duration;
    playerScale.keyOn();

    15::second => now;

    -2 => playerPeak.target;
    10::second => playerPeak.duration;
    playerPeak.keyOn();

    -6 => playerPeak.target;
    10::second => playerPeak.duration;
    playerPeak.keyOn();


    45::second => now;
    e3.keyOff();
    fadeOut(2::second);
}

fun void watchFilterCutoff() {
    while(true) {
        <<< "[cutoff]", f.freq() >>>;
        1::second => now;
    }
}

fun void rateASR(dur atk, dur sustain, dur release, float rate, int negate) {
    1 => float direction;
    if (playerRate.getValue() < 0) -1 => direction;

    if (negate) -1 * direction => direction;

    Math.fabs(rate) => float magnitude;

    // set direction before attack.
    direction * playerRate.getValue() => playerRate.value;

    magnitude * direction => playerRate.target;
    atk => playerRate.duration;

    playerRate.keyOn();
    atk + sustain => now;

    direction * 2 => playerRate.target;
    release => playerRate.duration;

    playerRate.keyOn();
    release => now;
}

fun void blendASR(dur atk, dur sustain, dur release, float gain) {
    4.0 / 5 => float ratio;
    gain * ratio => playerBlend.target;
    atk => playerBlend.duration;

    playerBlend.keyOn();

    atk => now;

    gain => playerBlend.target;
    sustain / 2 => playerBlend.duration;
    playerBlend.keyOn();

    sustain / 2 => now;
    
    gain * ratio => playerBlend.target;
    sustain / 2 => playerBlend.duration;
    playerBlend.keyOn();

    sustain / 2 => now;
    
    0 => playerBlend.target;
    release => playerBlend.duration;
    playerBlend.keyOn();
    
    release => now;
}

fun void fadeIn(dur d) {    
    d => playerFade.duration;
    1 => playerFade.target;           
    playerFade.keyOn();
    d => now;
}

fun void fadeOut(dur d) {
    d => playerFade.duration;
    playerFade.keyOff();
    d => now;
}
 
fun void launchFloaties(float peakMin, float peakMax) {
    // Need for stereo reverb
    NRev rl => dac;
    NRev rr => dac;

    0.25 => rl.mix => rr.mix;


    floaties1 => Pan2 p1; // => r;
    floaties2 => Pan2 p2; // => r;
    
    rl => Gain fakeGain => blackhole;
    rr => fakeGain;


    p1.left => rl;
    p2.left => rl;
    p1.right => rr;
    p2.right => rr;


    -0.5 => p1.pan;
    0.5 => p2.pan;

    0.75 => floaties1.gain => floaties2.gain;

    // scale floaty range with the filter cutoff
    // scaleCutoff(2,6) => float minFloat;
    // scaleCutoff(3,10) => float maxFloat;
    
    // random value between 0 and 1 to scale to current range
    // Math.randomf() => float amount;
    
    // 30 => float minFloat;
    // 40 => float maxFloat;
    
    scaleCutoff(0,1) => float scaler;
    Math.pow(scaler, 4) => scaler; // make scaling exponential
    scale(scaler, 0, 1, 2, 30) => float minFloat;
    scale(scaler, 0, 1, 3, 40) => float maxFloat;


    Math.round(minFloat) $ int => int min;
    Math.round(maxFloat) $ int => int max;

    Math.random2(min, max) => int count;
    <<< "floaties", count, min, max >>>;
    
    spork~ setEdge(fakeGain, peakMin, peakMax);

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
        
        6::framerate * Std.fabs(rate) => now;
    }
    5::second => now;

}

fun void setEdge(Gain input, float peakMin, float peakMax) {
    input => FFT fft =^ RMS rms => blackhole;
    // set parameters
    (framerate / samp) $ int => fft.size;
    // set hann window
    Windowing.hann((framerate / samp) $ int) => fft.window;
    
    while(true) {
        // getPeak(input, framerate) => float peak;
        // scale(input.last(), 0, 1, 
        
        // upchuck: take fft then rms
        rms.upchuck() @=> UAnaBlob blob;
        // print out RMS
        /// <<< blob.fval(0) >>>;
        blob.fval(0) => float peak;
        
        
        scale(peak, 0, 0.001, peakMin, peakMax) => float scaledPeak => playerPeak.target;
        // <<< "peak", peak, scaledPeak >>>;
        6::framerate => playerPeak.duration;
        playerScale.keyOn();
        6::framerate => now;
    }
}

fun float getPeak(Gain input, dur d) {
    now + d => time later;
    0 => float peak;
    
    
    while (now < later) {
        Math.max(peak, Std.fabs(input.last())) => peak;
        samp => now;
    }
    
    return peak;
}
    
// this way I can keep the frequency bounds in one spot.
fun float scaleCutoff(float min, float max) {
    return scale(f.freq(), 500, 20000, min, max);
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
