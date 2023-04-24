s.options.memSize_(2 pow: 21); // 4 GB
s.boot;

(
b = Buffer.alloc(s, s.sampleRate * 600);
~audioFile = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "samples/PlayDigitalGuitar.wav");
)

(
Ndef(\pitchshift, { |ratio=0.5, amp=1.2| PitchShift.ar(\in.ar([0, 1]), pitchRatio: ratio, mul: amp) });

Ndef(\reverb, { |dry=1, wet=0.2, revTime=2, amp=0.33|
	var sig = \in.ar([0, 1]);

	sig = (sig * dry) + (wet * NHHall.ar(sig, revTime));

	sig * amp;
});

Ndef(\dist, { |hpf_freq=600, lpf_freq=3200, eq_freq=120, rq=0.7, db=8, hpf_amp=5, lpf_amp=0.5, smoothing=1, amp=0.51, amt=0.5|
	var hpf, lpf, eq;
	var chain, chainsmooth, smooth;

	var clean       = Array.newClear(2);
	var sig_in      = \in.ar([0, 1]);
	var coefficient = 2 * amt / (1 - amt);
	var rampTime    = 150;
	var sigAmp      = 1.5;
	var distAmp     = 0.4;
	var select, sig;

	hpf = HPF.ar(sig_in[0], hpf_freq, hpf_amp);
	lpf = LPF.ar((1 + coefficient) * hpf / (1 + (coefficient * hpf.abs)), [lpf_freq, (lpf_freq+100)], lpf_amp);
	eq  = Mix(MidEQ.ar(lpf, eq_freq, rq, db)); // Mixed because lpf creates a 2nd channel of signal through expansion

	chain       = FFT(LocalBuf(2048), eq);
	chainsmooth = PV_MagSmooth(chain, smoothing);
	chain       = PV_MagSubtract(chain, chainsmooth, 1);
	smooth      = IFFT(chain);

	clean[0] = HPF.ar(smooth, 220);

	hpf = HPF.ar(sig_in[1], hpf_freq, hpf_amp);
	lpf = LPF.ar((1 + coefficient) * hpf / (1 + (coefficient * hpf.abs)), [lpf_freq, (lpf_freq+100)], lpf_amp);
	eq  = Mix(MidEQ.ar(lpf, eq_freq, rq, db));

	chain       = FFT(LocalBuf(2048), eq);
	chainsmooth = PV_MagSmooth(chain, smoothing);
	chain       = PV_MagSubtract(chain, chainsmooth, 1);
	smooth      = IFFT(chain);

	clean[1] = HPF.ar(smooth, 220);

	clean * amp;
});

Ndef(\ratio, { |val=0.25| DC.kr(val) });

// Orignal Ndef for simple processing
Ndef(\simpleFX, { |amp=0.75|
	var sig = \in.ar([0, 1]);
	var filtered = LPF.ar(sig, XLine.kr(5000, 300, 5));
	filtered * amp;
});

Ndef(\chorus, { |depth=0.01, rate=2, mix=0.5, dry=1.0, amp=1.0|
    var inSig  = \in.ar([0, 1]);
    var chorus = [
        Pan2.ar(DelayC.ar(inSig[0], 1, SinOsc.kr(rate * 0.25 + Rand(-0.1, 0.1), mul: depth, add: depth)), -1),
        Pan2.ar(DelayC.ar(inSig[0], 1, SinOsc.kr(rate * 0.5 + Rand(-0.1, 0.1), mul: depth, add: depth)), 1),
        Pan2.ar(DelayC.ar(inSig[1], 1, SinOsc.kr(rate * 0.75 + Rand(-0.1, 0.1), mul: depth, add: depth)), -1),
        Pan2.ar(DelayC.ar(inSig[1], 1, SinOsc.kr(rate + Rand(-0.1, 0.1), mul: depth, add: depth)), 1)
    ];

    var chorusMix = Mix.new(chorus) * mix;
    var output = inSig * dry + chorusMix;
    output * amp;
});



// Playback of buffered audio through Ndefs
Ndef(\bufferPlayback, {
	var buf = PlayBuf.ar(2, ~audioFile, loop: 1);
	buf;
});

Ndef(\mouseX, { MouseX.kr(0.5, 20).linexp(0.5, 20, 0.5, 20) });
Ndef(\mouseY1, { MouseY.kr(0, 0.4) });
Ndef(\mouseY2, { MouseY.kr(1, 0.7) });
// Mouse control for parameters
Ndef(\chorus).set('rate', Ndef(\mouseX));
Ndef(\reverb).set('wet', Ndef(\mouseY1));
Ndef(\reverb).set('dry', Ndef(\mouseY2));

// Route the final audio output to hardware outputs
// Ndef(\bufferPlayback).play;
Ndef(\bufferPlayback) <>> Ndef(\chorus) <>> Ndef(\dist) <>> Ndef(\reverb);
Ndef(\reverb).play;
)

