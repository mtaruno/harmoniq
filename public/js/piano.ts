import { ChordDetector } from './chord-detector.js';
import { Timeline } from './timeline.js';

// Define a more compatible interface for HTML elements with dataset
interface KeyElement extends HTMLElement {
    dataset: {
        note: string;
        frequency: string;
    };
}

export class Piano {
    private keys: HTMLElement[] = [];
    private activeNotes: Set<string> = new Set();

    constructor() {
        console.log('Piano constructor called');
        this.init();
    }

    private init(): void {
        console.log('Piano init called');
        const pianoElement = document.getElementById('piano');
        if (!pianoElement) {
            console.log('Piano element not found');
            return;
        }

        const notes: string[] = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

        // Create two octaves of keys
        for (let octave = 0; octave < 2; octave++) {
            notes.forEach((note) => {
                const key = document.createElement('div');
                key.className = `key ${note.includes('#') ? 'black' : 'white'}`;
                key.dataset.note = `${note}${octave + 4}`;
                key.dataset.frequency = this.noteToFrequency(note, octave + 4).toString();

                key.addEventListener('mousedown', () => this.keyDown(key));
                key.addEventListener('mouseup', () => this.keyUp(key));
                key.addEventListener('mouseleave', () => this.keyUp(key));

                pianoElement.appendChild(key);
                this.keys.push(key);
            });
        }
        console.log('Created', this.keys.length, 'piano keys');

        // Add keyboard event listeners
        document.addEventListener('keydown', (e: KeyboardEvent) => this.handleKeyPress(e));
        document.addEventListener('keyup', (e: KeyboardEvent) => this.handleKeyRelease(e));
    }

    private noteToFrequency(note: string, octave: number): number {
        const notes: Record<string, number> = {
            'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5,
            'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11
        };
        const noteNumber = notes[note] + (octave * 12);
        return 440 * Math.pow(2, (noteNumber - 69) / 12);
    }

    private keyDown(key: HTMLElement): void {
        const note = key.dataset.note;
        if (note && !this.activeNotes.has(note)) {
            this.activeNotes.add(note);
            key.classList.add('active');
            this.updateChordDisplay();
        }
    }

    private keyUp(key: HTMLElement): void {
        const note = key.dataset.note;
        if (note) {
            this.activeNotes.delete(note);
            key.classList.remove('active');
            this.updateChordDisplay();
        }
    }

    private handleKeyPress(e: KeyboardEvent): void {
        const keyMap: Record<string, string> = {
            'a': 'C4', 'w': 'C#4', 's': 'D4', 'e': 'D#4', 'd': 'E4',
            'f': 'F4', 't': 'F#4', 'g': 'G4', 'y': 'G#4', 'h': 'A4',
            'u': 'A#4', 'j': 'B4', 'k': 'C5'
        };

        if (keyMap[e.key]) {
            const key = this.keys.find(k => k.dataset.note === keyMap[e.key]);
            if (key) this.keyDown(key);
        }
    }

    private handleKeyRelease(e: KeyboardEvent): void {
        const keyMap: Record<string, string> = {
            'a': 'C4', 'w': 'C#4', 's': 'D4', 'e': 'D#4', 'd': 'E4',
            'f': 'F4', 't': 'F#4', 'g': 'G4', 'y': 'G#4', 'h': 'A4',
            'u': 'A#4', 'j': 'B4', 'k': 'C5'
        };

        if (keyMap[e.key]) {
            const key = this.keys.find(k => k.dataset.note === keyMap[e.key]);
            if (key) this.keyUp(key);
        }
    }

    private updateChordDisplay(): void {
        const chordDetector = new ChordDetector();
        const chord = chordDetector.detectChord(Array.from(this.activeNotes));
        const currentChordElement = document.getElementById('current-chord');
        if (currentChordElement) {
            currentChordElement.textContent = chord || 'No chord detected';
        }

        // Update timeline
        if (chord) {
            const timeline = new Timeline();
            timeline.addChord(chord);
        }
    }
} 