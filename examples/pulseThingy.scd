(
~sin = { |lfoFreq=0.5, width=0.2, revTime=2, amp=0.2|
	var pulse = LFPulse.kr(lfoFreq, 0, width);
	var freq = LFNoise0.kr(lfoFreq).exprange(160, 3520);
	var sig = SinOsc.ar(freq, 0, pulse);
	var pan = LFNoise0.kr(lfoFreq, 0.5);

	sig = Pan2.ar(sig, pan);

	sig = sig + NHHall.ar(sig, revTime); // + mixes

	sig * amp; // * affects levels

}.play;
)

~sin.set(\freq, 2, \width, 0.05);

(
{
	var sig = RLPF.ar(WhiteNoise.ar, MouseX.kr(1e2,2e4,1), 0.2, 0.2);
}.play;
)
