import { Piano } from './piano.js';
export declare class MIDIVisualizer {
    private midiAccess;
    private piano;
    constructor(piano: Piano);
    private initializeMIDI;
    private setupMIDIListeners;
    private setupInputDevice;
    private handleMIDIMessage;
    private midiNoteToNoteName;
}
