s.options.memSize_(2 pow: 20);
s.boot;

b = Buffer.alloc(s, s.sampleRate * 600);

(
Ndef(\pitchshift, { |ratio=0.5, amp=1.2| PitchShift.ar(\in.ar([0, 1]), pitchRatio: ratio, mul: amp) });

Ndef(\dist, { |hpf_freq=600, lpf_freq=3200, eq_freq=120, rq=0.7, db=8, hpf_amp=5, lpf_amp=0.5, smoothing=1, amp=0.51, amt=0.97|
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
	eq  = Mix(MidEQ.ar(lpf, eq_freq, rq, db)); //Mixed because lpf creates a 2nd channel of signal through expansion

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

Ndef(\counterpoint, { |polyAmp=1, amp=3|
	var sig      = Mix(\in.ar([0, 1]));
	var writePos = Phasor.ar(0, 1, 0, BufFrames.ir(b));
	var readPos1 = writePos * Ndef(\ratio).kr;
	var readPos2 = writePos * Ndef(\ratio).kr * 2;
	var readPos3 = writePos * Ndef(\ratio).kr * 3;
	var readPos4 = writePos * Ndef(\ratio).kr * 4;
	var readPos5 = writePos * Ndef(\ratio).kr * 5;
	var polyAmp1, polyAmp2, polyAmp3, polyAmp4, polyAmp5;
	var contra1, contra2, contra3, contra4, contra5;

	BufWr.ar(sig, b, writePos);

	polyAmp1 = polyAmp * 2;
	polyAmp2 = polyAmp * 1.5;
	polyAmp3 = polyAmp * 1.25;
	polyAmp4 = polyAmp * 1.125;
	polyAmp5 = polyAmp * 1;

	contra1 = BufRd.ar(1, b, readPos1) * polyAmp1;
	contra2 = BufRd.ar(1, b, readPos2) * polyAmp2;
	contra3 = BufRd.ar(1, b, readPos3) * polyAmp3;
	contra4 = BufRd.ar(1, b, readPos4) * polyAmp4;
	contra5 = BufRd.ar(1, b, readPos5) * polyAmp5;

	sig = Mix([
		Pan2.ar(contra1, Rand(-1, 1)),
		Pan2.ar(contra2, Rand(-1, 1)),
		Pan2.ar(contra3, Rand(-1, 1)),
		Pan2.ar(contra4, Rand(-1, 1)),
		Pan2.ar(contra5, Rand(-1, 1))
	]);

	sig = sig[0]; //Needed to flatten the array

	sig * amp;
});

Ndef(\reverb1, { |delayTime=2, damp=0.2, size=1, diff=0.707, fb=0.5, modDepth=0.1, modFreq=2, sigAmp=1, amp=0.5|
	var sig = \in.ar([0, 1]);
	var delay;

	delay = Greyhole.ar(
		in:        sig,
		delayTime: delayTime,
		damp:      damp,
		size:      size,
		diff:      diff,
		feedback:  fb,
		modDepth:  modDepth,
		modFreq:   modFreq
	);

	(sig * sigAmp) + delay * amp;
});

Ndef(\reverb2, { |dry=1, wet=0.2, revTime=2, amp=1|
	var sig = \in.ar([0, 1]);

	sig = (sig * dry) + (wet * NHHall.ar(sig, revTime));

	sig * amp;
});
)
