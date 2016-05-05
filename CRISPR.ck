// CRISPR.ck
// Eric Heep

// communication classes
HandshakeID talk;
3.5::second => now;
talk.talk.init();
2.5::second => now;

6 => int NUM_PUCKS;
16 => int NUM_LEDS;

// led class
Puck puck[NUM_PUCKS];

for (0 => int i; i < NUM_PUCKS; i++) {
    puck[i].init(i);
}

float hue[NUM_PUCKS][NUM_LEDS];
float sat[NUM_PUCKS][NUM_LEDS];
float val[NUM_PUCKS][NUM_LEDS];

0.999 => float red;
0.7 => float blue;
0.8 => float violet;

fun int convert(float value, int scale) {
    return Std.clamp(Math.floor(value * scale) $ int, 0, scale);
}

fun void updateColors() {
    while (true) {
        for (int i; i < NUM_PUCKS; i++) {
            for (int j; j < 16; j++) {
                puck[i].color(j,
                    convert(hue[i][j], 1023),  // hue
                    convert(sat[i][j], 255),   // saturation
                    convert(val[i][j], 255)  // value
                );
            }
        }
        (1.0/30.0)::second => now;
    }
}

[ 15, 14, 13, 12, 11] @=> int top[];
[ 10,  9,  8,  7,  6, 5] @=> int middle[];
[  4,  3,  2,  1,  0] @=> int bottom[];

fun void cycle() {
    while (true) {
        for (0 => int i; i < NUM_PUCKS; i++) {
            for (0 => int j; j < middle.size(); j++) {
                Math.random2f(0.8, 1.0) => hue[i][middle[j]];
                Math.random2f(0.9, 1.0) => sat[i][middle[j]];
                1.0 => val[i][middle[j]];
                (1.0/10.0)::second => now;
                0.0 => val[i][middle[j]];
            }
        }
    }
}

fun void sineRow(int row[], dur speed, float h, int color) {
    float sineInc;

    NUM_PUCKS * row.size() => int rowLength;
    Math.random2(0, rowLength -1) => int offset;

    speed => dur totalTime;

    while (speed > 1::ms) {
        // incrementer
        (sineInc + 0.1) % (2 * pi) => sineInc;

        Math.floor(((Math.sin(sineInc) + 1.0) / 2.0) * rowLength)$int => int rowLed;

        if (offset != 0) {
            (rowLed + offset) % rowLength => rowLed;
        }

        rowLed/row.size() => int puck;
        rowLed % row.size() => int led;

        //  <<< puck, led >>>;
        1.0 => val[puck][row[led]];

        speed/totalTime => float scale;

        if (color) {
            Math.pow(scale, 0.125) => sat[puck][row[led]];
        }
        else {
            0 => sat[puck][row[led]];
        }

        h => hue[puck][row[led]];
        speed => now;
        0.0 => val[puck][row[led]];

        speed - 0.15::ms => speed;
    }

    // just in case
    1::ms => speed;

    while (speed < totalTime) {
        // incrementer
        (sineInc + 0.1) % (2 * pi) => sineInc;

        Math.floor(((Math.sin(sineInc) + 1.0) / 2.0) * rowLength)$int => int rowLed;

        if (offset != 0) {
            (rowLed + offset) % rowLength => rowLed;
        }

        rowLed/row.size() => int puck;
        rowLed % row.size() => int led;

        //  <<< puck, led >>>;
        1.0 => val[puck][row[led]];

        speed/totalTime => float scale;

        if (color) {
            Math.pow(scale, 0.125) => sat[puck][row[led]];
        }
        else {
            0 => sat[puck][row[led]];
        }

        h => hue[puck][row[led]];
        speed => now;
        0.0 => val[puck][row[led]];

        speed + 0.15::ms => speed;
    }
}

fun void fadeRow(int row[], int flicker) {
    NUM_PUCKS * row.size() => int rowLength;
    Math.random2f(0.3, 1.0) => float chance;

    60::second => dur timeLength;

    for (int i; i < rowLength; i++) {
        i / row.size() => int puck;
        i % row.size() => int led;
        if (Math.random2f(0.0, 1.0) < chance) {
            if (flicker) {
                spork ~ fade(puck, led, row, Math.random2f(10, 30)::ms, timeLength, flicker);
            }
            else {
                spork ~ fade(puck, led, row, Math.random2f(10, 30)::ms, timeLength, flicker);
            }
        }
    }

    now => time start;
    while (start + timeLength > now) {
        1::samp => now;
    }
}

fun void fade(int puck, int led, int row[], dur speed, dur timeLength, int flicker) {
    float sineInc;

    now => time start;
    while (start + timeLength > now) {
        (sineInc + 0.01) % (2 * pi) => sineInc;
        Math.sin(sineInc) => val[puck][row[led]];
        if (flicker) {
            Math.random2f(0.8, 1.0) => sat[puck][row[led]];
        }
        speed => now;
    }
}

fun void drunkRow(int row[], float h) {
    2 => int stepLimit;
    int rowLed, dir, step;

    NUM_PUCKS * row.size() => int rowLength;
    60::second => dur timeLength;

    Math.random2(0, rowLength - 1) => rowLed;

    now => time start;
    while (start + timeLength > now) {
        Math.random2(0, stepLimit) => step;

        if (Math.random2(0, 1)) {
            1 => dir;
        }
        else {
            -1 => dir;
        }

        dir * step => step;

        rowLed + step => rowLed;
        if (rowLed < 0) {
            rowLed + rowLength => rowLed;
        }
        else {
            rowLed % rowLength => rowLed;
        }

        rowLed / row.size() => int puck;
        rowLed % row.size() => int led;

        1.0 => val[puck][row[led]];
        1.0 => sat[puck][row[led]];
        h => hue[puck][row[led]];
        Math.random2(400, 500)::ms => now;
        0.0 => val[puck][row[led]];
    }
}

// row stuff -------------------------------------------
fun void sinePhase(int color) {
    spork ~ sineRow(bottom, 126::ms, red, color);
    spork ~ sineRow(middle, 127::ms, red, color);
    spork ~ sineRow(top, 128::ms, red, color);
    spork ~ sineRow(bottom, 129::ms, Math.random2f(blue, violet), color);
    spork ~ sineRow(middle, 130::ms, Math.random2f(blue, violet), color);
    sineRow(top, 131::ms, Math.random2f(blue, violet), color);
}

fun void fadePhase(int flicker) {
    spork ~ fadeRow(bottom, flicker);
    spork ~ fadeRow(middle, flicker);
    fadeRow(top, flicker);
}

fun void drunkPhase() {
    spork ~ drunkRow(bottom, Math.random2f(blue, violet));
    spork ~ drunkRow(middle, Math.random2f(blue, violet));
    spork ~ drunkRow(top, Math.random2f(blue, violet));
    spork ~ drunkRow(bottom, red);
    spork ~ drunkRow(middle, red);
    drunkRow(top, red);
}

spork ~ updateColors();

fun void chaosPhase() {
    0.25 => float chance;
    repeat(200) {
        for (0 => int i; i < NUM_PUCKS; i++) {
            for (0 => int j; j < NUM_LEDS; j++) {
                if (Math.random2f(0.0, 1.0) < chance) {
                    1.0 => val[i][j];
                }
                else {
                    0.0 => val[i][j];
                }
            }
        }
        10::ms => now;
    }
}

fun void clear() {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            0.0 => val[i][j];
            0.0 => sat[i][j];
            0.0 => hue[i][j];
        }
    }
}

fun void clear() {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            0.0 => val[i][j];
            0.0 => sat[i][j];
            0.0 => hue[i][j];
        }
    }
}

fun void valAll(float v) {
    for (0 => int i; i < NUM_PUCKS; i++) {
        for (0 => int j; j < NUM_LEDS; j++) {
            v => val[i][j];
        }
    }
}

// big stuff --------------------------------------------
while (true) {
    fadePhase(0);
    valAll(Math.random2f(0.5, 0.7));
    drunkPhase();
    15::second => now;
    sinePhase(0);
    chaosPhase();
    fadePhase(1);
    chaosPhase();
    valAll(Math.random2f(0.5, 0.7));
    15::second => now;
    chaosPhase();
    15::second => now;
    sinePhase(1);
}
