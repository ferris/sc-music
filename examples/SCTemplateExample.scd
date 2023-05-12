//////////////////////////////////////
//SuperCollider Project File Template
//MUSC 281
//(c) 2022 Benjamin D. Whiting
/////////////////////////////////////

/*
DIRECTIONS:
1. File > Save As "YourPiece'sTitle.scd" without quotes.

2. Replace the template information above with the following (without brackets or quotes):
Your Piece's Title
"(c) 2022 [YourName]"

3. Copy and paste all relevant code into the appropriate ~make Functions below.

4. Place your cursor within the code block under Server Setup and press Cmnd+Return on macOS, or Ctrl+Enter on Windows/Linux.

5. Repeat the previous step beneath where it says GUI VARIABLE SETUP.

6. Depress Start to begin piece.
*/

///////////////
//SERVER SETUP
///////////////

// The best way of inventorying your connected input and output hardware and to
// see what names they give to SuperCollider, boot the server with Cmnd/Ctrl+B and
// look at what is listed under Number of Devices:
( // CMND+RETURN/CTRL+ENTER THIS FIRST
Server.default = s = Server.local; // in case 's' ever gets accidentally overwritten

s.options.memSize_(2 pow: 21); // 4GiB
)

( //CMND+RETURN/CTRL+ENTER THIS NEXT
s.waitForBoot {
	///////////////
	//BUFFER SETUP
	///////////////

	~makeBuffers = {
		//First, allocate your buffers for recording and playing back live audio
		//using the following syntax:

		//~nameOfBuffer = Buffer.alloc(s, numSeconds * s.sampleRate, numChannels);

		//Repeat the above instruction for each buffer you wish to allocate

		//Next, load in any prerecorded sound files you wish for playback:
		//(MAKE SURE THESE FILES ARE ALL IN YOUR PROJECT DIRECTORY!!!)

		//~nameOfBuffer = Buffer.read(s, PathName(thisProcess.nowExecutingPath).parentPath ++ "NameOfFile.wav"); //You can also load in .aif(f) files
	};

	////////////
	//SYNTHDEFS
	////////////

	~makeSynthDefs = {
		//Copy-paste your SynthDefs here

		SynthDef(\shimmering_percussion, { |freq=440, atk=0.01, sus=0.2, sus1=0.3, sus2=0.2, rel=0.1, pan=0, amp=0.03, revTime=2, dry=1, wet=0.3, out|
			var freqs  = Array.fill(6, {(freq * Rand(1, 11)).round(freq) + Rand((freq * 0.05).neg, freq * 0.05)});
			var amps   = [0.8 + Rand(-0.20, 0.20), 0.9 + Rand(-0.10, 0.10), 0.5 + Rand(-0.20, 0.20), 0.6 + Rand(-0.20, 0.20), 0.3 + Rand(-0.20, 0.20), 0.2 + Rand(-0.20, 0.20)];
			var phases = Array.fill(6, {Rand(-1.0, 1.0)});
			var sig    = Klang.ar(`[freqs, amps, phases]);
			var env    = EnvGen.kr(Env.new(
				[0, 1, 0.6, 0.7, sus1, sus2, 0],
				[atk, 0.03, 0.05, 0.1, sus, rel],
				[1, -2, 1, 1, -1, -4]
			));
			var rev;

			sig = Pan2.ar(sig, pan) * env * amp;

			rev = NHHall.ar(sig, revTime);
			sig = (sig * dry) + (rev * wet);

			DetectSilence.ar(sig, doneAction: Done.freeSelf);
			Out.ar(out, sig);
		}).add;

		SynthDef(\low_metal, { |freq=55, atk=0.01, sus=1, susLevel=0.4, rel=12, pan=0, amp=0.2, revTime=2, dry=1, wet=0.2, out|
			var freqs  = Array.fill(6, {(freq * Rand(1, 11)).round(freq) + Rand((freq * 0.05).neg, freq * 0.05)});
			var amps   = [1, 0.8 + Rand(-0.10, 0.10), 0.5 + Rand(-0.20, 0.20), 0.6 + Rand(-0.20, 0.20), 0.3 + Rand(-0.20, 0.20), 0.2 + Rand(-0.20, 0.20)];
			var phases = Array.fill(6, {Rand(-1.0, 1.0)});
			var sig    = Klang.ar(`[freqs, amps, phases]);
			var env    = EnvGen.kr(Env.new(
				[0, 0.8, 0.3, 1, susLevel, susLevel, 0],
				[atk, 0.1, 0.1, 0.5, sus, rel],
				[1, -2, 1, 1, -1, -4]
			));
			var rev;

			sig = Pan2.ar(sig, pan) * env * amp;

			rev = NHHall.ar(sig, revTime);
			sig = (sig * dry) + (rev * wet);

			DetectSilence.ar(sig, doneAction: Done.freeSelf);
			Out.ar(out, sig);
		}).add;

		SynthDef(\drum, { |tension=0.01, loss=0.99972, pan=0, amp=1, revTime=2, dry=1, wet=0.2, out|
			var exciter = EnvGen.kr(Env.perc, timeScale: 0.1) * PinkNoise.ar(amp);
			var sig     = MembraneCircle.ar(exciter, tension, loss);
			var rev;

			sig = Pan2.ar(sig, pan);
			rev = NHHall.ar(sig, revTime);
			sig = (sig * dry) + (rev * wet);

			DetectSilence.ar(sig, doneAction: Done.freeSelf);
			Out.ar(out, sig);
		}).add;
	};

	////////
	//NDEFS
	////////

	~makeNdefs = {
		//Copy-paste your Ndefs here
		Ndef(\drumming).ar(2);
		Ndef(\shim1).ar(2);
		Ndef(\shim2).ar(2);
		Ndef(\shim3).ar(2);
		Ndef(\low).ar(2);

		Ndef(\rlpf, { |freq=1760, rq=0.5, amp=1|
			var in1 = \in1.ar(0.dup);
			var in2 = \in2.ar(0.dup);
			var in3 = \in3.ar(0.dup);
			var in4 = \in4.ar(0.dup);

			var sig  = Mix([in1, in2, in3, in4]);

			RLPF.ar(sig, freq, rq, amp);
		});

		Ndef(\mouseXControl, { MouseX.kr(0.1, 1) });
		Ndef(\mouseYControl, { MouseY.kr(220, 3520, 1) });
	};

	/////////////////
	//OSC RESPONDERS
	/////////////////

	~makeOSC = {
		//Copy-paste your OSCFuncs/OSCdefs here (if applicable)
	};

	///////
	//MIDI
	///////

	~makeMIDI = {
		MIDIClient.init;
		MIDIIn.connectAll;

		//Copy-paste your MIDI code here (if applicable)
	};

	////////
	//TDEFS
	////////

	~makeTdefs = {
		//Copy-paste your Tdefs (or Tasks/Routines) here (if applicable)
	};

	////////
	//PDEFS
	////////

	~makePdefs = {
		//Copy-paste your Pdefs here (if applicable)

		Pdef(\shim1, Pbind(*[
			instrument: 'shimmering_percussion',
			midinote:   Pseq([59, 71], inf),
			amp:        0.1,
			pan:        Pxrand([-0.75, -0.25, 0.25, 0.75], inf),
			delta:      1,
			dur:        3
		]));

		Pdef(\shim2, Pbind(*[
			instrument: 'shimmering_percussion',
			midinote:   Pxrand([60, 64, 66], inf),
			amp:        0.1,
			dur:        3,
			delta:      Pseq([0.25, 0.25, 0.25], inf),
			pan:        Pxrand([-1, -0.5, 0, 0.5, 1], inf)
		]));

		Pdef(\shim3, Pbind(*[
			instrument: 'shimmering_percussion',
			midinote:   Pxrand([
				71, 72, 76, 78, 81,
				83, 84, 88, 90, 93
			], inf),
			amp:        0.1,
			delta:      0.125,
			dur:        3
		]));

		Pdef(\low, Pbind(*[
			instrument: 'low_metal',
			midinote:   23,
			amp:        0.3,
			dur:        19,
			delta:      16
		]));

		Pdef(\drumming, Pbind(*[
			instrument: 'drum',
			delta:      Pwrand([
				Pseq([64.reciprocal, 64.reciprocal, 64.reciprocal, 64.reciprocal]),
				Pseq([6.reciprocal, 12.reciprocal, 6.reciprocal, 12.reciprocal, 6.reciprocal, 12.reciprocal, 6.reciprocal, 12.reciprocal]),
				Pseq([12.reciprocal, 12.reciprocal, 12.reciprocal, 2.reciprocal, 12.reciprocal, 12.reciprocal, 12.reciprocal, 6.reciprocal, 12.reciprocal])
			], [1, 4, 2].normalizeSum, inf),
			dur:        0.2,
			tension:    Pwrand([0.01, 0.016, 0.03], [0.6, 0.3, 0.1], inf),
			loss:       Pwrand([0.99972, 0.9998], [0.7, 0.3], inf),
			pan:        Pwhite(-0.5, 0.5)
		]));

		Pdef(\shim2).quant = 0.25;
	};

	///////
	//TASK
	///////

	~makeTask = {
		//Here is where your main Task should go

		~main = Task {
			Ndef(\drumming, Pdef(\drumming)).play;

			20.wait;

			Ndef(\low, Pdef(\low)).play;

			16.wait;

			Ndef(\shim2, Pdef(\shim2)).play;

			16.wait;

			Ndef(\shim1, Pdef(\shim1)).play;
			Ndef(\drumming).stop(32);

			48.wait;

			Ndef(\shim3, Pdef(\shim3)).play;

			16.wait;

			Ndef(\shim1).stop(5);
			Ndef(\shim2).stop(5);
			Ndef(\shim3).stop(5);
			Ndef(\low).stop(5);

			Ndef(\shim1) <>>.in1 Ndef(\rlpf);
			Ndef(\shim2) <>>.in2 Ndef(\rlpf);
			Ndef(\shim3) <>>.in3 Ndef(\rlpf);
			Ndef(\low)   <>>.in4 Ndef(\rlpf);

			Ndef(\rlpf).set(\rq,   Ndef(\mouseXControl));
			Ndef(\rlpf).set(\freq, Ndef(\mouseYControl));

			Ndef(\rlpf).play(fadeTime: 3);

			48.wait;

			Ndef(\rlpf).proxyspace.end(16);
		};
	};

	/////////////////
	//INITIALIZATION
	/////////////////

	s.sync; //Ensures all prior code is evaluated before moving on
	~make = {
		~makeBuffers.value;
		~makeSynthDefs.value;
		~makeNdefs.value;
		~makeOSC.value;
		~makeMIDI.value;
		~makeTdefs.value;
		~makePdefs.value;
		~makeTask.value;
	};

	~make.value;

	//////
	//GUI
	//////

	w = Window(
		name:   "Controls",
		bounds: Rect(
			left:   Window.availableBounds.width/3,
			top:    Window.availableBounds.height/3,
			width:  160,
			height: 100 + ServerMeterView.height
		)
	).front;
	w.view.decorator = d = FlowLayout(w.bounds);
	w.background_(Color.cyan);
	d.nextLine.left_(20);
	Button(w, 120@20).states_([["Start", Color.black, Color.green]]).action_({
		~main.play;
		"Start".postln;
	});
	d.nextLine.left_(20);
	Button(w, 120@20).states_([["Reset", Color.white, Color.blue]]).action_({
		{
			"Please wait.".postln;
			Ndef.clear(0.1);
			0.1.wait;
			s.volume_(0.ampdb);
			0.1.wait;
			s.quit;
			3.wait;
			s.boot;
			5.wait;
			~make.value;
			s.volume_(0);
			"Ready!".postln;
		}.fork;
	});
	d.nextLine.left_(20);
	Button(w, 120@20).states_([["PANIC", Color.white, Color.red], ["calm", Color.red, Color.white]]).action_({ |val|
		switch (val.value)
		{ 1 } {  s.mute  }
		{ 0 } { s.unmute }
	});
	d.nextLine;
	ServerMeterView(s, w, 0@0, 2, 2);

	///////////////
	//FINISH SETUP
	///////////////

	s.sync;

	"Ready".postln;
};
)