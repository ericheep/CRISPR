// master.ck
// Eric Heep

// communication classes
Machine.add(me.dir() + "/Handshake.ck");
Machine.add(me.dir() + "/HandshakeID.ck");
Machine.add(me.dir() + "/Puck.ck");

// main program
3.0::second => now;
Machine.add(me.dir() + "/Analyze.ck");
Machine.add(me.dir() + "/CRISPR.ck");
