(
Ndef(\amSynth, { |amp = 0.1 |
	var mouseX = MouseX.kr(40, 3560, 1);
	var mouseY = MouseY.kr(1, 33);
	var lfo = SinOsc.kr(mouseY);
	var vco = SinOsc.ar(mouseX * lfo);

	vco.dup * amp;
});
)

Ndef(\amSynth).play;

(
Ndef(\amSynth, { |amp=0.1|
	var lfo = SinOsc.kr(\lfoFreq.kr(1));
	var vco = SinOsc.ar(\vcoFreq.kr(40) * lfo);

	vco.dup * amp;
})
)


Ndef(\lfoFreq, { MouseX.kr(1, 33) });
Ndef(\vcoFreq, { MouseY.kr(40, 3560, 1) });

Ndef(\amSynth).play;

Ndef(\amSynth).set(\lfoFreq, Ndef(\lfoFreq));
Ndef(\amSynth).set(\vcoFreq, Ndef(\lfoFreq));

Ndef(\amSynth).fadeTime_(5);

(
Ndef(\amSynth).xset(\lfoFreq, 20);
Ndef(\amSynth).xset(\vcoFreq, 44400);
)
