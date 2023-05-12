( // init
s.options.memSize_(2 pow: 21); // 4 GB
s.boot;
~mainCaller = ("./FMDS.scd").loadRelative.wrapAt(-1);
)
(
MIDIClient.init;
MIDIIn.connectAll;
)
(
// fun ones:25, 26, 36, 37, 40, 42, 43, 56, 60, 61, 64, 68, 72, 73, 78, 80, 83
// 86, 105, 106. 108, 115, 116, 118, 121, 122,
// var presetz = Array.fill(128, 1447);

MIDIdef.noteOn(\FMDS, {arg vel, note;
	// ~mainCaller.value(note, vel, (presetz[0] * 128) + presetz[1]);
	[note, vel].postln;
	~mainCaller.value(note, vel, 1412);
}).add;

// 80 for melody and 68 for bass

// 25? 68? 73? 80? 108? 116?
// 26,36, 68 FOR BASS?
// 83, 122 for later

// 13168? 14902?

// 15414 drum
// 15415 siren
// 15958 chime ring

// 1581 kick
//NOTES:: 47,49,50,47,53,50,47,46


// 26/56/86/100/108
// 64/73/78/105/122

/*MIDIdef.cc(\FMDSCC, {arg ...args;
	presetz[args[1]] = args[0];
},(0..1)).add;*/

MIDIdef.noteOff(\FMDSoff, {arg vel, note;
	~mainCaller.value(note, 0);
}).add;
)
