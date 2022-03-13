// mic-in to audio out

// the patch
// adc => ABSaturaor sat => GVerb gverb => Gain g => dac;
// adc => Echo d => ABSaturator sat => GVerb g => dac;

//20 => sat.drive;

// 1::second => d.max;

// 0::second => d.delay;
// 4 => sat.dcOffset;

adc => KSChord object => GVerb g => dac;

0.5 => g.gain;
object.feedback( .96 );

object.tune( 12, 12, 16, 19 );


// infinite time-loop
while( true )
{
    // advance time
    100::ms => now;
}
