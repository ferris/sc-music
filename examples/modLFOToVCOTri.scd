// ramp up to quick pulses then back down to slow
// gonna want another lfo controlling lfpulse lfo controlling amp of lftriangle

s.options.sampleRate=48000;
s.boot;

{SinOsc.ar(261.6, 0, 0.2).dup}.play;

(
x = {
	|freq=261.63, width=0.2, amp=0.2|

	//var lfo = LFPulse.kr(lfoFreq, 0, width, amp);
	var lfoFreq = LFTri.kr(0.1).range(0.4, 4);
	var lfo = LFPulse.kr(lfoFreq, 0, width, amp);

	LFTri.ar(freq, 0, lfo).dup;
}.play;
)

// 1.linlin(-1, 1, 0.1, 1);
