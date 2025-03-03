

#include <klang.h>
using namespace klang::optimised;
	
// inverted mapping 0..1 to 1..0	
signal invert(signal x){ return 1 - x; }

// logarithmic mapping 0..1 to 0..1
signal nonlinear(signal x){ return pow(10, 2 * (x - 1)); }

// square mapping 0..1 to 0..1
signal squared(signal x){ return x * x; }

// maps -1..1 to 0.1x to 10x (0 = 1x)
signal bipolar(signal x){ return pow(10, x); }

// Oscillator Section
struct OSC : Generator {
	Saw osc1;
	// TODO: add more oscillators
	Saw osc2;
	Square osc3;
	
	// TODO: add mixer controls
	param gain[3] = {0};
	
	// TODO: add a detune function
	
	void set(param f, param gain1, param gain2, param gain3, param detune){
		gain[0] = gain1;
		gain[1] = gain2;
		gain[2] = gain3;
		osc1(f, 0);
		osc2(f - detune, 0);
		osc3(f + detune, 0);
	}

	void process() {
		(osc1 * gain[0] + osc2 * gain[1] + osc3 * gain[2]) * 0.333 >> out;
	}
};

// Filter Section
struct FLT : Modifier {
	LPF lpf;
	HPF hpf;
	BPF bpf;

	int filterType = 0;
	param f = 0;
	param Q = 1;

	void set(param freq, param res){
		f = freq;
		Q = res;
	}
	
	void setFilterType(int fType){
		filterType = fType;
		lpf.reset();
		hpf.reset();
		bpf.reset();
	}
	
	void process() {
		// TODO: apply the filter
		switch(filterType){
			case 0: // lpf
				in >> lpf(f, Q) >> out;
				break;
			case 1: // hpf
				in >> hpf(f, Q) >> out;
				break;
			case 2: // bpf
				in >> bpf(f, Q) >> out;
				break;
		}
	}
};

// Amplifier Section
struct AMP : Modifier {
	ADSR env;

	void process() {
		in * env >> out;
	}
};

// Mod Envelope Section
struct MOD : Generator {
	ADSR env;

	void process() {
		// TODO: allow amount to be controlled
		bipolar(env) >> out;
	}
};

// 	TODO: add LFO section

struct Modular : Synth {

	struct ModularNote : public Note {
		OSC osc;
		FLT flt;
		AMP amp;
		MOD mod;

		event on(Pitch pitch, Amplitude velocity) {
			const param f = pitch -> Frequency;
			const param detune = f * 0.01f * controls[3];
			osc.set(pitch -> Frequency, controls[0], controls[1], controls[2], detune);
			amp.env(controls[4], controls[5], controls[6], controls[7]);
			
			// TODO: configure sections
			flt.setFilterType(controls[12]); 
			
		}

		event off(Amplitude velocity) {
			amp.env.release();
		}

		void process() {
			// TODO: add modulation

			param f = controls[13];
			param Q = controls[14];

			osc >> flt(f, Q) >> amp >> out;
			
			if (amp.env.finished())
				stop();
		}
	};

	Modular() {
		controls = {
			{ "OSC",	Slider("1", 0, 1, 1, { 28, 52, 40, 60 } ), 
						Slider("2", 0, 1, 1, { 73, 52, 40, 60 } ),
						Slider("3", 0, 1, 1, { 118, 52, 40, 60 } ), 
						Dial("Detune", 0, 1, 0, { 163, 52, 40, 60 } ), },			
				
			{ "AMP",	Slider("A", 0, 1, 0.5, { 230, 52, 10, 60 } ), 
						Slider("D", 0, 1, 0.5, { 245, 52, 10, 60 } ), 
						Slider("S", 0, 1, 1.0, { 260, 52, 10, 60 } ), 
						Slider("R", 0, 1, 0.5, { 275, 52, 10, 60 } ), },
						
			{ "MOD",	Slider("A", 0, 1, 0.5, { 312, 52, 10, 60 } ), 
						Slider("D", 0, 1, 0.5, { 327, 52, 10, 60 } ), 
						Slider("S", 0, 1, 1.0, { 342, 52, 10, 60 } ), 
						Slider("R", 0, 1, 0.5, { 357, 52, 10, 60 } ), },

			{ "FLT", 	Menu("", { 178, 208, 71, 20 }, "LPF", "HPF", "BPF" ),
						Dial("f", 100, 10000, 10000, { 28, 168, 40, 60 } ),
						Dial("Q", 0.1, 10, 1, { 78, 168, 40, 60 } ),
						Dial("Drive", 1, 24, 1, { 128, 168, 40, 60 } ),
						Dial("LFO", -1, 1, 0, { 185, 173, 25, 30 } ),
						Dial("MOD", -1, 1, 0, { 220, 173, 25, 30 } ) },
			
			{ "LFO", { 269, 131 },
						Dial("Rate", .1, 10, 1, { 7, 0, 40, 60 } ),
						Dial("Depth", 0, 1, 0, { 58, 0, 40, 60 } ),
			},
		};
		notes.add<ModularNote>(32);
	}
};
