//----------------------------------------------------------------------------
// This is starting as OSC controls to send to 
// PraxisLIVE to control there.
//----------------------------------------------------------------------------

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

0.05 => float delta;
1 => float currVal;

// infinite time loop
while( true )
{
    // start the message...
    xmit.start( "/video/player.rate" );
    
    // add int argument
    // Math.random2( 30, 80 ) => xmit.add;
    // add float argument
    // math.random2f( .4, 4 ) => xmit.add;
    
    if (currVal > 4 || currVal < 1) {
        -1 *=> delta;
    }
    
    delta +=> currVal;
    currVal => xmit.add;
    
    // send it
    <<< currVal >>>;
    xmit.send();

    // advance time
    0.24::second => now;
}
