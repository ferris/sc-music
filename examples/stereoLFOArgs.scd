s.boot;

{SinOsc.ar(440, 0, 0.2).dup}.play;

(
x = {
	|freq1=440, freq2=440, width1=0.2, width2=0.2, lfoF1=0.5, lfoF2=0.5, amp1=0.1, amp2=0.1|

	var lfoR = LFPulse.kr(lfoF1, 0, width1, amp1);
	var lfoL = LFPulse.kr(lfoF2, 0.5, width2, amp2);

	[
		SinOsc.ar(freq1, 0, lfoR),
		SinOsc.ar(freq2, 0, lfoL)
	]
}.play;
)

x.set(\freq1, 880);
x.set(\freq2, 220, \amp2, 0.2);
x.set(\lfoF1, 0.8, \lfoF2, 0.5);
x.set(\lfoF1, 6, \lfoF2, 4);
