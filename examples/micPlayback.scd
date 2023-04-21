// Allocate a buffer for recording voide input, with a length of 5 seconds
~voiceBuf = Buffer.alloc(s, 5 * s.sampleRate, 1);


(
// Define a synth named 'record' for recording the voice input to the buffer
{ |bufnum|
	// Create an envelope generator with a 0.1s attack, 4.8s sustain, and 0.1s release
	var env = EnvGen.kr(Env([0, 1, 1, 0], [0.1, 4.8, 0.1]), doneAction: Done.freeSelf);
	// Get the audio input
	var sig = SoundIn.ar;
	// Record the aduio input multiplied by the envelope into the buffer
	RecordBuf.ar(sig * env, bufnum, loop: 0);
	// Output silent audio while recording
	Silent.ar;
}.asSynthDef(name: 'record').add;
)


// Create a 'record' synth instance, passing the buffer number as an argument
Synth(\record, [\bufnum, ~voiceBuf]);


(
// Define a synth named 'playback' for playing back the recorded buffer with modulation
{
	// Create a low-frequency oscillator for modulating the playback rate
	var lfo = LFNoise1.kr(0.5, 2);

	// Play the buffer with modulation from the LFO, loop playback, and free the synth when done
	PlayBuf.ar(1, ~voiceBuf, lfo, loop: 1, doneAction: Done.freeSelf).dup;
}.asSynthDef(name: 'playback', fadeTime: 0.01).add;
)


// Create a 'playback' synth instance
x = Synth(\playback);

// Set the playback rate of the 'playback' synth instance to 0.5
x.set(\rate, 0.5);
