export class MIDIVisualizer {
    constructor(piano) {
        this.midiAccess = null;
        console.log('MIDIVisualizer constructor called');
        this.piano = piano;
        this.initializeMIDI();
    }
    async initializeMIDI() {
        try {
            if (!navigator.requestMIDIAccess) {
                console.error('Web MIDI API is not supported in this browser');
                return;
            }
            this.midiAccess = await navigator.requestMIDIAccess();
            console.log('MIDI access granted');
            this.setupMIDIListeners();
        }
        catch (error) {
            console.error('Error accessing MIDI devices:', error);
        }
    }
    setupMIDIListeners() {
        if (!this.midiAccess)
            return;
        this.midiAccess.addEventListener('statechange', (event) => {
            const port = event.port;
            if (port && port.type === 'input' && port.state === 'connected') {
                this.setupInputDevice(port);
            }
        });
        // Set up existing input devices
        this.midiAccess.inputs.forEach((input) => {
            if (input.state === 'connected') {
                this.setupInputDevice(input);
            }
        });
    }
    setupInputDevice(input) {
        input.addEventListener('midimessage', (event) => {
            if (event.data) {
                const data = Array.from(event.data);
                this.handleMIDIMessage(data);
            }
        });
    }
    handleMIDIMessage(data) {
        const [status, note, velocity] = data;
        const isNoteOn = status === 144; // MIDI note on message
        const isNoteOff = status === 128; // MIDI note off message
        if (isNoteOn || isNoteOff) {
            const noteName = this.midiNoteToNoteName(note);
            if (noteName) {
                const keyElement = document.querySelector(`[data-note="${noteName}"]`);
                if (keyElement instanceof HTMLElement) {
                    if (isNoteOn && velocity > 0) {
                        this.piano['keyDown'](keyElement);
                    }
                    else {
                        this.piano['keyUp'](keyElement);
                    }
                }
            }
        }
    }
    midiNoteToNoteName(midiNote) {
        const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        const octave = Math.floor(midiNote / 12) - 1;
        const noteIndex = midiNote % 12;
        return `${noteNames[noteIndex]}${octave}`;
    }
}
//# sourceMappingURL=midi-visualizer.js.map