//////////////////////////////////////
//SuperCollider Project File Template
//MUSC 281
//(c) 2022 Benjamin D. Whiting
//////////////////////////////////////

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

//The best way of inventorying your connected input and output hardware and to
//see what names they give to SuperCollider, boot the server with Cmnd/Ctrl+B and
//look at what is listed under Number of Devices:
( //CMND+RETURN/CTRL+ENTER THIS FIRST
Server.default = s = Server.local; //in case 's' ever gets accidentally overwritten

s.options.memSize_(2 pow: 20); //2GiB
)

( //CMND+RETURN/CTRL+ENTER THIS NEXT
/////////////////////
//GUI VARIABLE SETUP
/////////////////////

s.waitForBoot {
	~mainCaller = ("./FMDS.scd").loadRelative.wrapAt(-1);

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

		// INTRO FILES
		~connectAttemptSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/connectAttempt.aiff");
		~connectSuccessSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/connectSuccess.aiff");
		~establishTCPSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/establishTCP.aiff");
		~handshakeCompleteSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/handshakeComplete.aiff");
		// idk what to call this yet TODO TODO TODO
		~hackMainframeSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/hackMainframe.aiff");
		~weAreInSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/weAreIn.aiff");
		~copyingDataSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/copyingData.aiff");
		~nowWeWaitSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/nowWeWait.aiff");
		~kernelProblemSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/kernelProblem.aiff");
		~onToUsSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/onToUs.aiff");
		~traceSourceSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/traceSource.aiff");
		~exfiltrateDataSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/exfiltrateData.aiff");
		~intruderDetectedSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/intruderDetected.aiff");
		~intruderAlertSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/intruderAlert.aiff");
		~transferCompleteSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/transferComplete.aiff");
		~successTooEasySample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/successTooEasy.aiff");
	};

	////////////
	//SYNTHDEFS
	////////////

	~makeSynthDefs = {
		//Copy-paste your SynthDefs here
		SynthDef("clap", {
			arg out = 0, amp = 0.1, pan = 0;
			var env1, env2, snd, noise1, noise2;

			env1 = Env.new(
				levels: [0, 1, 0, 1, 0, 1, 0, 1, 0],
				times: [0.001, 0.013, 0, 0.01, 0, 0.01, 0, 0.03],
				curve: [0, -3, 0, -3, 0, -3, 0, -4]
			).ar;
			env2 = Env.new(
				levels: [0, 1, 0],
				times: [0.02, 0.3],
				curve: [0, -4]
			).ar(doneAction: 2);

			noise1 = WhiteNoise.ar(env1);
			noise1 = HPF.ar(noise1, 600);
			noise1 = BPF.ar(noise1, 2000, 3);

			noise2 = WhiteNoise.ar(env2);
			noise2 = HPF.ar(noise2, 1000);
			noise2 = BPF.ar(noise2, 1200, 0.7, 0.7);

			snd = noise1 + noise2;
			snd = snd * 2;
			snd = snd.softclip * amp;

			Out.ar(out, Pan2.ar(snd, pan));
		}).add;


		SynthDef("kick808", {arg out = 0, freq1 = 240, freq2 = 60, amp = 0.1, ringTime = 10, att = 0.001, rel = 1, dist = 0.5, pan = 0;
			var snd, env;
			snd = Ringz.ar(
				in: Impulse.ar(0), // single impulse
				freq: XLine.ar(freq1, freq2, 0.1),
				decaytime: ringTime);
			env = Env.perc(att, rel, amp).kr(doneAction: 2);
			snd = (1.0 - dist) * snd + (dist * (snd.distort));
			snd = snd * env;
			Out.ar(out, Pan2.ar(snd, pan));
		}).add;

	};

	////////
	//NDEFS
	////////

	~makeNdefs = {
		// add ndefs here
		Ndef(\kick808).ar(2);
		Ndef(\clap).ar(2);
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

		~firstIntro128 = Task { // 8 beat, wait for 4 after (12 total)
			"Starting 1st Intro 128".postln;
			~mainCaller.value(52, 100, 128); 8.wait;
			~mainCaller.value(52, 0);
			"Done with 1st Intro 128".postln;
		};

		~firstIntro100 = Task { // 8 beats
			"Starting 1st Intro 100".postln;
			~mainCaller.value(89, 100, 100); 2.wait;
			~mainCaller.value(89, 0); ~mainCaller.value(86, 100, 100); 2.wait;
			~mainCaller.value(86, 0); ~mainCaller.value(83, 100, 100); 2.wait;
			~mainCaller.value(83, 0); ~mainCaller.value(76, 100, 100); 2.wait;
			~mainCaller.value(76, 0);
			"Done with 1st Intro 100".postln;
		};

		~secondIntro128 = Task { // 32 beats
			"Starting 2nd Intro 128".postln;
			~mainCaller.value(52, 100, 128); 4.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 100, 128); 4.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(53, 100, 128); 4.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(50, 100, 128); 4.wait;
			~mainCaller.value(50, 0); ~mainCaller.value(52, 100, 128); 4.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 100, 128); 4.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(53, 100, 128); 4.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(50, 100, 128); 4.wait;
			~mainCaller.value(50, 0);
			"Done with 2nd Intro 128".postln;
		};

		~thirdIntro = Task { // 32 beats
			"Starting 3rd Intro 128/8503".postln;
			~mainCaller.value(52, 100, 128); 2.wait;
			~mainCaller.value(76, 50, 8503); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 100, 128); 2.wait;
			~mainCaller.value(76, 0); ~mainCaller.value(71, 50, 8503); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(53, 100, 128); 2.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 50, 8503); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(50, 100, 128); 2.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 50, 8503); 2.wait;
			~mainCaller.value(50, 0);
			// halfway
			~mainCaller.value(52, 100, 128); 2.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(76, 50, 8503); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 100, 128); 2.wait;
			~mainCaller.value(76, 0); ~mainCaller.value(71, 50, 8503); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(53, 100, 128); 2.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 50, 8503); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(50, 100, 128); 2.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 50, 8503); 2.wait;
			~mainCaller.value(50, 0); 2.wait;
			~mainCaller.value(74, 0);
			"Done with 3rd Intro 128/8503".postln;
		};

		~fourthIntro = Task { // 34 beats
			"Starting 4th Intro 15415/8503".postln;
			~mainCaller.value(52, 100, 15415); 2.wait;
			~mainCaller.value(76, 50, 8503); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 100, 15415); 2.wait;
			~mainCaller.value(76, 0); ~mainCaller.value(71, 50, 8503); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(53, 100, 15415); 2.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 50, 8503); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(50, 100, 15415); 2.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 50, 8503); 2.wait;
			~mainCaller.value(50, 0);
			// halfway
			~mainCaller.value(52, 100, 15415); 2.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(76, 50, 8503); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 100, 15415); 2.wait;
			~mainCaller.value(76, 0); ~mainCaller.value(71, 50, 8503); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(53, 100, 15415); 2.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 50, 8503); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(50, 100, 15415); 2.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 50, 8503); 2.wait;
			~mainCaller.value(50, 0); 2.wait;
			~mainCaller.value(74, 0);
			"Done with 4th Intro 15415/8053".postln;
		};

		~drumKicks = Task {
			Ndef(\kick808, Pdef(\kick808)).play;
			Ndef(\clap, Pdef(\clap)).play;
			8.wait;
			Ndef(\kick808, Pdef(\kick808)).play;
			Ndef(\clap, Pdef(\clap)).play;
			8.wait;
		};
	};

	////////
	//PDEFS
	////////

	~makePdefs = {
		//Copy-paste your Pdefs here (if applicable)

		Pbindef(\kick808,
			\instrument, "kick808",
			\dur, Pseq([
				3/4, 1/4,
				1/2, 1/2,
				Rest(1),
				1/4, Rest(3/4)
			], 2) * 1.0,
			\amp, 0.2,
			\rel, 0.7,
			\dist, Pseries(0.1, 0.1, 16)
		);

		Pbindef(\clap,
			\instrument, "clap",
			\dur, Pseq([
				Rest(5/2), 1/2,
				Rest(1/2), 1/2
			], 2) * 1.0,
			\amp, 0.2,
			\rel, 0.7,
			\dist, Pseries(0.1, 0.1, 16)
		);
	};

	///////
	//TASK
	///////

	TempoClock.default.tempo = 2;

	~makeTask = {
		// Here is where your main Task should go
		// Need it to be at least 360 beats total
		~main = Task {
			~firstIntro128.start;
			8.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~connectAttemptSample]);
			4.wait;

			//////////////////////////////// 12 beats

			~firstIntro128.start;
			12.wait;
			~firstIntro128.start;
			~firstIntro100.start;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~connectSuccessSample]);
			12.wait;
			~firstIntro128.start;
			~firstIntro100.start;
			12.wait;

			//////////////////////////////// 48 beats

			~secondIntro128.start;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~establishTCPSample]);
			32.wait;


			//////////////////////////////// 80 beats

			~thirdIntro.start;
			16.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~handshakeCompleteSample]);
			16.wait;

			//////////////////////////////// 112 beats

			~fourthIntro.start;
			16.wait;
			~drumKicks.start;
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~hackMainframeSample]);
			4.wait;
			~drumKicks.start;
			8.wait;
			~drumKicks.start;
			2.wait;

			//////////////////////////////// 146 beats

			6.wait;
			~drumKicks.start;
			8.wait;

			//////////////////////////////// ??? beats
			//////////////////////////////// 360 beats
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