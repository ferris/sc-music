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
	};

	////////
	//NDEFS
	////////

	~makeNdefs = {
		//Copy-paste your Ndefs here
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
	};

	///////
	//TASK
	///////

	~makeTask = {
		//Here is where your main Task should go

		~main = Task {

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