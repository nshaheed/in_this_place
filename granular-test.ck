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

// one-stop function for creating a LiSa, loaded with the specified audio file
26::second => dur start;
28::second => dur end;
load( me.dir() + "concertina1.wav", start, end) @=> LiSa @ lisa;
// connect
lisa => NRev r => dac;
KSChord object;
0.05 => r.mix;

0.2 => lisa.gain;

// buffer length
1::second => dur bufferlen;

lisa.maxVoices(60);

// kschord stuff
object.feedback( .5 );
0.15 => object.gain;
object.tune(36, 40, 48, 48);

// [-0.5, 0.75, -1, 0.6] 
[-1.0] @=> float rates[];

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


5::second => now;

spork~ bass();

// create grains, rotate record and play bufs as needed
// shouldn't click as long as the grainlen < bufferlen
while( true )
{
    // new rate and duration
    Math.random2f(0.5, 0.5) => float newrate;
    Math.random2f(209, 400)::ms => dur newdur;
    
    rates[Math.random2(0, rates.cap()-1)] => newrate;
    0.5 *=> newrate;

    // spork a grain!
    spork ~ getgrain(lisa, newdur, 40::ms, 40::ms, newrate);
    // freq
    // freqmod.last() * 400. + 800. => s.freq;
    // advance time
    
    // if (offset > 30::ms || offset < 0.5::ms) 1::ms => duration;
    
    // <<< offset / ms >>>;
    offset => now;
    // delta +=> offset;
}

fun void bass() {
    load( me.dir() + "concertina1.wav", start, end) @=> LiSa @ lisabass;
    lisabass => r;
    
    3 => lisabass.gain;

    while (true) {
        10::second => now;
        <<< "bass" >>>;
        spork~ getgrain(lisabass, 3::second, 40::ms, 800::ms, 0.0625);
        spork~ controlRate();
    }
}

fun void controlRate() {
    // start the message...
    xmit.start( "/video/player.rate" );
    
    1 => xmit.add;
    
    xmit.send();

    3::second => now;
    
    xmit.start( "/video/player.rate" );
    
    2 => xmit.add;
    
    xmit.send();

}

/*
// party on...
0.5 => lisa.rate; // rate!
1 => lisa.loop; // loop it!
1 => lisa.bi; // bi-directional loop!
1 => lisa.play; // play!

// commence party
while( true ) 1::second => now;
*/  

    
// sporkee: a grain!
fun void getgrain( LiSa lisa, dur grainlen, dur rampup, dur rampdown, float rate )
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
