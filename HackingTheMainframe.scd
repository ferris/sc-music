//////////////////////////////////////
// Hacking The Mainframe
// MUSC 281
// (c) 2023 Ferris Linde
//////////////////////////////////////

///////////////
//SERVER SETUP
///////////////

// The best way of inventorying your connected input and output hardware and to
// see what names they give to SuperCollider, boot the server with Cmnd/Ctrl+B and
// look at what is listed under Number of Devices:
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
		// INTRO FILES
		~connectAttemptSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/connectAttempt.aiff");
		~connectSuccessSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/connectSuccess.aiff");
		~establishTCPSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/establishTCP.aiff");
		~handshakeCompleteSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/handshakeComplete.aiff");
		// melody part
		~hackMainframeSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/hackMainframe.aiff");
		~weAreInSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/weAreIn.aiff");
		~copyingDataSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/copyingData.aiff");
		~nowWeWaitSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/nowWeWait.aiff");
		// error part
		~kernelProblemSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/kernelProblem.aiff");
		~onToUsSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/onToUs.aiff");
		~traceSourceSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/traceSource.aiff");
		~exfiltrateDataSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/exfiltrateData.aiff");
		// alarm part
		~intruderDetectedSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/intruderDetected.aiff");
		~intruderAlertSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/intruderAlert.aiff");
		~transferCompleteSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/transferComplete.aiff");
		~allResourcesSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/allResources.aiff");
		~allocateBandwidthSample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/allocateBandwidth.aiff");
		~successTooEasySample = Buffer.read(s, thisProcess.nowExecutingPath.dirname +/+ "hackerVoice/successTooEasy.aiff");
	};

	////////////
	//SYNTHDEFS
	////////////

	~makeSynthDefs = {
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


		SynthDef(\chip, {
			arg amp = 0.5;
			var snd;
			snd = (LFPulse.ar(\freq.kr(440) * (2 ** LFPulse.ar(\octaveFreq.kr(3), 0.5))) - (1 / 2)).sign;
			snd = snd * Env.asr(0.0, 1, 0.0).ar(Done.freeSelf, \gate.kr(1));
			snd = snd * \amp.kr(-10.dbamp);
			snd = snd.softclip * amp;
			snd = Pan2.ar(snd, \pan.kr(0));
			OffsetOut.ar(\out.kr(0), snd);
		}).add;
	};

	////////
	//NDEFS
	////////

	~makeNdefs = {
		Ndef(\kick808).ar(2);
		Ndef(\clap).ar(2);
	};

	///////
	//MIDI
	///////

	~makeMIDI = {
		MIDIClient.init;
		MIDIIn.connectAll;
	};

	////////
	//TDEFS
	////////

	~makeTdefs = {
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

		~drumz = Task {
			Ndef(\kick808, Pdef(\kick808)).play;
			Ndef(\clap, Pdef(\clap)).play;
			8.wait;
		};

		~drumzAlt = Task {
			Ndef(\kick808, Pdef(\kick808)).play;
			Ndef(\clap, Pdef(\clap)).play;
			8.wait;
		};

		~rapidDrums = Task {
			Ndef(\kick808, Pdef(\rapidkick808)).play;
			Ndef(\clap, Pdef(\rapidclap)).play;
			8.wait;
			Ndef(\kick808, Pdef(\rapidkick808)).play;
			Ndef(\clap, Pdef(\rapidclap)).play;
			8.wait;
			Ndef(\kick808, Pdef(\rapidkick808)).play;
			Ndef(\clap, Pdef(\rapidclap)).play;
			8.wait;
			Ndef(\kick808, Pdef(\rapidkick808)).play;
			Ndef(\clap, Pdef(\rapidclap)).play;
		};

		~melody80v25 = Task {
			~mainCaller.value(71, 25, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 25, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 25, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 25, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 25, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 25, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 25, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 25, 80); 1.wait;
			~mainCaller.value(70, 0);

			~mainCaller.value(71, 25, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 25, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 25, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 25, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 25, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 25, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 25, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 25, 80); 1.wait;
			~mainCaller.value(70, 0);
		};

		~bassline68v25 = Task {
			~mainCaller.value(35, 25, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 25, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 25, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 25, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 25, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 25, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 25, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 25, 68); 1.wait;
			~mainCaller.value(35, 0);

			~mainCaller.value(35, 25, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 25, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 25, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 25, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 25, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 25, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 25, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 25, 68); 1.wait;
			~mainCaller.value(35, 0);
		};

		~melody80v50 = Task {
			~mainCaller.value(71, 50, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 50, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 50, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 50, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 50, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 50, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 50, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 50, 80); 1.wait;
			~mainCaller.value(70, 0);

			~mainCaller.value(71, 50, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 50, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 50, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 50, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 50, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 50, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 50, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 50, 80); 1.wait;
			~mainCaller.value(70, 0);
		};

		~bassline68v50 = Task {
			~mainCaller.value(35, 50, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 50, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 50, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 50, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 50, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 50, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 50, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 50, 68); 1.wait;
			~mainCaller.value(35, 0);

			~mainCaller.value(35, 50, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 50, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 50, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 50, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 50, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 50, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 50, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 50, 68); 1.wait;
			~mainCaller.value(35, 0);
		};

		~melody80v75 = Task {
			~mainCaller.value(71, 75, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 75, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 75, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 75, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 75, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 75, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 75, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 75, 80); 1.wait;
			~mainCaller.value(70, 0);

			~mainCaller.value(71, 75, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 75, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 75, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 75, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 75, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 75, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 75, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 75, 80); 1.wait;
			~mainCaller.value(70, 0);
		};

		~bassline68v75 = Task {
			~mainCaller.value(35, 75, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 75, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 75, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 75, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 75, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 75, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 75, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 75, 68); 1.wait;
			~mainCaller.value(35, 0);

			~mainCaller.value(35, 75, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 75, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 75, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 75, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 75, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 75, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 75, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 75, 68); 1.wait;
			~mainCaller.value(35, 0);
		};

		~melody80v100 = Task {
			~mainCaller.value(71, 100, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 100, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 100, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 100, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 100, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 100, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 100, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 100, 80); 1.wait;
			~mainCaller.value(70, 0);

			~mainCaller.value(71, 100, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(73, 100, 80); 1.wait;
			~mainCaller.value(73, 0); ~mainCaller.value(74, 100, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 100, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(77, 100, 80); 1.wait;
			~mainCaller.value(77, 0); ~mainCaller.value(74, 100, 80); 1.wait;
			~mainCaller.value(74, 0); ~mainCaller.value(71, 100, 80); 1.wait;
			~mainCaller.value(71, 0); ~mainCaller.value(70, 100, 80); 1.wait;
			~mainCaller.value(70, 0);
		};

		~bassline68v100 = Task {
			~mainCaller.value(35, 100, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 100, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 100, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 100, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 100, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 100, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 100, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 100, 68); 1.wait;
			~mainCaller.value(35, 0);

			~mainCaller.value(35, 100, 68); 1.wait;
			~mainCaller.value(35, 0); ~mainCaller.value(38, 100, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(46, 100, 68); 1.wait;
			~mainCaller.value(46, 0); ~mainCaller.value(47, 100, 68); 1.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(45, 100, 68); 1.wait;
			~mainCaller.value(45, 0); ~mainCaller.value(43, 100, 68); 1.wait;
			~mainCaller.value(43, 0); ~mainCaller.value(38, 100, 68); 1.wait;
			~mainCaller.value(38, 0); ~mainCaller.value(35, 100, 68); 1.wait;
			~mainCaller.value(35, 0);
		};

		~errorNotice = Task {
			~mainCaller.value(52, 50, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(53, 55, 15081); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(52, 60, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 65, 15081); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(52, 70, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(53, 75, 15081); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(52, 80, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 85, 15081); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(52, 90, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(53, 95, 15081); 2.wait;
			~mainCaller.value(53, 0); ~mainCaller.value(52, 100, 15081); 2.wait;
			~mainCaller.value(38, 100, 14695);
			~mainCaller.value(52, 0); ~mainCaller.value(47, 90, 15081); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(52, 80, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 70, 15081); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(52, 60, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 50, 15081); 2.wait;
			~mainCaller.value(47, 0); ~mainCaller.value(52, 40, 15081); 2.wait;
			~mainCaller.value(52, 0); ~mainCaller.value(47, 30, 15081); 2.wait;
			~mainCaller.value(47, 0);
			~mainCaller.value(38, 0);
		};

		~detection = Task {
			~mainCaller.value(44, 100, 14599);
			18.wait;
			~mainCaller.value(44, 0);
		};

		~alarm = Task {
			~mainCaller.value(66, 100, 1412);
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(66, 0);
			6.wait;
			~mainCaller.value(66, 100, 1412);
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 100, 3755);
			2.wait;
			~mainCaller.value(39, 0);
		};

		~chiptune = Task {
			1.do {
				[
					0, \, \, 0, 12, 7, 3, 0,
					2, \, \, 8, \, \, -5, \,
					\, \, \, -5, 7, 3, 0, -5,
					-7, \, \, -5, \, \, -4, \,
					-7, \, -5, -4, \, 0, 7, \,
					8, 7, 5, 4, 5, 7, 8, 7,
					5, \, -7, 5, \, -7, 7, \,
					-5, 7, \, -5, 2, 2, 3, 3,

					0, \, \, 0, 12, 7, 3, 0,
					2, \, \, 8, \, \, -5, \,
					\, \, \, -5, 7, 3, 0, -5,
					-7, \, \, -5, \, \, -4, \,
					-7, \, -5, -4, \, 0, 7, \,
					8, 7, 5, 4, 5, 7, 8, 7,
					5, \, -7, 5, \, -7, 7, \,
					-5, 7, \, -5, 2, 2, 3, 3,

					0, \, 0, 8, \, 8, 7, \,
					\, \, \, \, \, \, \, \,
					0, \, 0, 8, \, 8, 7, \,
					\, \, 7, 5, 3, 5, 7, \,
					-4, \, -4, 7, \, 7, 5, \,
					5, 3, \, 3, 2, \, 2, 2,
					-4, -1, 0, 2, 3, 5, 7, 3,
					8, 7, 19, 17, 15, 14, 12, 11,

					0, \, 0, 8, \, 8, 7, \,
					\, \, \, \, \, \, \, \,
					0, \, 0, 8, \, 8, 7, \,
					\, \, 7, 5, 3, 5, 7, \,
					-4, \, -4, 7, \, 7, 5, \,
					5, 3, \, 3, 2, \, 2, 2,
					-4, -1, 0, 2, 3, 5, 7, 3,
					8, 7, 19, 17, 15, 14, 12, 11,

					12, 12, 12, 12, 12, 7, 0, \,
					-4, \, \, -4, \, 0, -5, \,
					12, 12, 12, 12, 12, 7, 0, \,
					-4, \, \, -4, \, 0, -5, \,
					-7, \, -5, \, -4, \, 0, \,
					7, \, 0, \, 5, \, 0, \,
					8, \, -1, \, 7, \, -1, \,
					10, \, -1, \, 8, \, -1, \,

					12, 12, 12, 12, 12, 7, 0, \,
					-4, \, \, -4, \, 0, -5, \,
					12, 12, 12, 12, 12, 7, 0, \,
					-4, \, \, -4, \, 0, -5, \,
					-7, \, -5, \, -4, \, 0, \,
					7, \, 0, \, 5, \, 0, \,
					8, \, -1, \, 7, \, -1, \,
					10, \, -1, \, 8, \, -1, \,

					12, 12, 12, 12, 12, 7, 0, \,
					-4, \, \, -4, \, 0, -5, \,
					12, 12, 12, 11, 10, 13, 16, \,
					-4, \, \, -4, \, 0, 5, \,
					-7, \, -5, \, 5, \, 0, \,
					7, \, 7, \, 5, \, 5, \,
					-4, \, -3, \, -4, \, -3, \,
					-4, \, -3, \, -2, \, -1, 0,
				].do { |note|
					var synths, divint;
					divint = 0.25;
					if(note == \) {
						divint.wait;
					} {
						synths = [
							Synth(\chip, [freq: (56 + (12 * 2) + note).midicps, octaveFreq: 16]),
							Synth(\chip, [freq: (56 + (12 * -1) + note).midicps, octaveFreq: 8]),
						];
						(divint * 0.7).wait;
						synths[0].set(\gate, 0);
						synths[1].set(\gate, 0);
						(divint * (1 - 0.7)).wait;
					};
				};
			};
		};
	};

	////////
	//PDEFS
	////////

	~makePdefs = {
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

		Pbindef(\rapidkick808,
			\instrument, "kick808",
			\dur, Pseq([
				1/2, 1/2,
				1/2, 1/2,
				1/2, 1/2,
				1/2, 1/2,
			], 2) * 1.0,
			\amp, 0.2,
			\rel, 0.7,
			\dist, Pseries(0.1, 0.1, 16)
		);

		Pbindef(\rapidclap,
			\instrument, "clap",
			\dur, Pseq([
				Rest(7/2), 1/2,
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
			~drumz.start;
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~hackMainframeSample]);
			4.wait;
			// ~drumz.start;
			8.wait;
			~drumz.start;

			//////////////////////////////// 144 beats

			~melody80v25.start;
			~bassline68v25.start;
			8.wait;
			~drumzAlt.start;
			8.wait;

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~weAreInSample]);

			~drumz.start;
			~melody80v50.start;
			~bassline68v50.start;
			8.wait;
			~drumzAlt.start;
			8.wait;

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~copyingDataSample]);

			~rapidDrums.start;
			~melody80v75.start;
			~bassline68v75.start;
			16.wait;

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~nowWeWaitSample]);

			~melody80v100.start;
			~bassline68v100.start;
			16.wait;

			//////////////////////////////// 208 beats

			~errorNotice.start;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~kernelProblemSample]);
			12.wait;

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~onToUsSample]);
			6.wait;

			~detection.start;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~traceSourceSample]);
			6.wait;

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~exfiltrateDataSample]);
			12.wait;

			//////////////////////////////// 244 beats

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			~alarm.start;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~intruderAlertSample]);
			4.wait;

			//////////////////////////////// 280 beats

			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~allResourcesSample]);
			8.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~allocateBandwidthSample]);
			8.wait;

			~chiptune.start; // size of chiptune is ~112 beats

			115.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~transferCompleteSample]);
			4.wait;
			{ |rate=1, bufnum|
				PlayBuf.ar(1, bufnum, rate * BufRateScale.kr(bufnum), doneAction: Done.freeSelf).dup;
			}.play(args: [\bufnum, ~successTooEasySample]);

			//////////////////////////////// 415 beats
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