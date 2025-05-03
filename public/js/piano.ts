import { ChordDetector } from './chord-detector.js';
import eventBus from './event-bus.js';

export class Piano {
    private keys: HTMLElement[] = [];
    private activeNotes: Set<string> = new Set();
    private keyboardMapping: Record<string, string> = {}; // Maps keyboard keys to notes
    private isMouseDown: boolean = false; // Track mouse state for drag-playing

    constructor() {
        console.log('Piano constructor called');
        this.init();
        
        // Add global mouse up handler to stop playing when mouse is released outside keys
        document.addEventListener('mouseup', () => {
            this.isMouseDown = false;
        });
    }

    private init(): void {
        console.log('Piano init called');
        const whiteKeysContainer = document.getElementById('white-keys');
        const blackKeysContainer = document.getElementById('black-keys');
        
        if (!whiteKeysContainer || !blackKeysContainer) {
            console.error('Piano containers not found - cannot initialize piano keyboard');
            return;
        }
        
        // Clear any existing content
        whiteKeysContainer.innerHTML = '';
        blackKeysContainer.innerHTML = '';
        
        // Define the notes for a 25-key keyboard (Akai MPK Mini)
        // This spans from C3 to C5 (2 octaves)
        const whiteNotes = [
            { note: 'C', octave: 3 },
            { note: 'D', octave: 3 },
            { note: 'E', octave: 3 },
            { note: 'F', octave: 3 },
            { note: 'G', octave: 3 },
            { note: 'A', octave: 3 },
            { note: 'B', octave: 3 },
            { note: 'C', octave: 4 },
            { note: 'D', octave: 4 },
            { note: 'E', octave: 4 },
            { note: 'F', octave: 4 },
            { note: 'G', octave: 4 },
            { note: 'A', octave: 4 },
            { note: 'B', octave: 4 },
            { note: 'C', octave: 5 }
        ];
        
        const blackNotes = [
            { note: 'C#', octave: 3, afterWhite: 0 },
            { note: 'D#', octave: 3, afterWhite: 1 },
            { note: 'F#', octave: 3, afterWhite: 3 },
            { note: 'G#', octave: 3, afterWhite: 4 },
            { note: 'A#', octave: 3, afterWhite: 5 },
            { note: 'C#', octave: 4, afterWhite: 7 },
            { note: 'D#', octave: 4, afterWhite: 8 },
            { note: 'F#', octave: 4, afterWhite: 10 },
            { note: 'G#', octave: 4, afterWhite: 11 },
            { note: 'A#', octave: 4, afterWhite: 12 }
        ];
        
        // Computer keyboard mapping (2 rows of keys)
        const keyboardMap = [
            // Lower row - Z to M
            'z', 'x', 'c', 'v', 'b', 'n', 'm', ',', '.', '/',
            // Upper row - Q to P
            'q', 'w', 'e', 'r', 't', 'y', 'u', 'i', 'o', 'p'
        ];
        
        // Create white keys first
        whiteNotes.forEach((noteObj, index) => {
            const { note, octave } = noteObj;
            const key = document.createElement('div');
            key.className = 'key white';
            const noteName = `${note}${octave}`;
            key.dataset.note = noteName;
            key.dataset.frequency = this.noteToFrequency(note, octave).toString();
            
            // Assign keyboard key if available
            if (index < keyboardMap.length) {
                const keyboardKey = keyboardMap[index];
                key.dataset.keyboardKey = keyboardKey;
                this.keyboardMapping[keyboardKey] = noteName;
            }
            
            // Style the white key
            key.style.flex = '1';
            key.style.height = '100%';
            key.style.backgroundColor = 'white';
            key.style.border = '1px solid #ccc';
            key.style.borderRadius = '0 0 5px 5px';
            key.style.margin = '0 1px';
            key.style.cursor = 'pointer';
            key.style.display = 'flex';
            key.style.alignItems = 'flex-end';
            key.style.justifyContent = 'center';
            key.style.paddingBottom = '10px';
            key.style.boxSizing = 'border-box';
            key.style.transition = 'all 0.1s';
            key.style.userSelect = 'none';
            
            // Add note label
            key.textContent = noteName;
            
            // Add event listeners for mouse interaction
            key.addEventListener('mousedown', (e) => {
                this.isMouseDown = true;
                this.keyDown(key);
                e.preventDefault(); // Prevent text selection
            });
            
            key.addEventListener('mouseup', () => {
                this.isMouseDown = false;
                this.keyUp(key);
            });
            
            key.addEventListener('mouseleave', () => {
                if (this.isMouseDown) {
                    this.keyUp(key);
                }
            });
            
            key.addEventListener('mouseenter', () => {
                if (this.isMouseDown) {
                    this.keyDown(key);
                }
            });
            
            whiteKeysContainer.appendChild(key);
            this.keys.push(key);
            
            console.log(`Created white key: ${noteName}`);
        });
        
        // Calculate white key width (needed for black key positioning)
        const whiteKeyWidth = 100 / whiteNotes.length;
        
        // Create black keys with proper positioning
        blackNotes.forEach((noteObj) => {
            const { note, octave, afterWhite } = noteObj;
            const key = document.createElement('div');
            key.className = 'key black';
            const noteName = `${note}${octave}`;
            key.dataset.note = noteName;
            key.dataset.frequency = this.noteToFrequency(note, octave).toString();
            
            // Style the black key
            key.style.width = '24px';
            key.style.height = '100%';
            key.style.backgroundColor = 'black';
            key.style.position = 'absolute';
            key.style.zIndex = '2';
            key.style.borderRadius = '0 0 3px 3px';
            key.style.cursor = 'pointer';
            key.style.display = 'flex';
            key.style.alignItems = 'flex-end';
            key.style.justifyContent = 'center';
            key.style.paddingBottom = '5px';
            key.style.boxSizing = 'border-box';
            key.style.color = 'white';
            key.style.fontSize = '10px';
            key.style.transition = 'all 0.1s';
            key.style.boxShadow = '0 0 5px rgba(0,0,0,0.3)';
            key.style.userSelect = 'none';
            
            // Position black keys
            // Position the black key between white keys
            const leftPos = (afterWhite * whiteKeyWidth) + (whiteKeyWidth * 0.7);
            key.style.left = `${leftPos}%`;
            
            // Add note label
            key.textContent = noteName;
            
            // Add event listeners for mouse interaction
            key.addEventListener('mousedown', (e) => {
                this.isMouseDown = true;
                this.keyDown(key);
                e.preventDefault(); // Prevent text selection
            });
            
            key.addEventListener('mouseup', () => {
                this.isMouseDown = false;
                this.keyUp(key);
            });
            
            key.addEventListener('mouseleave', () => {
                if (this.isMouseDown) {
                    this.keyUp(key);
                }
            });
            
            key.addEventListener('mouseenter', () => {
                if (this.isMouseDown) {
                    this.keyDown(key);
                }
            });
            
            blackKeysContainer.appendChild(key);
            this.keys.push(key);
            
            console.log(`Created black key: ${noteName}`);
        });
        
        console.log('Created', this.keys.length, 'piano keys');
        
        // Add keyboard event listeners
        this.setupKeyboardListeners();
    }
    
    private setupKeyboardListeners(): void {
        document.addEventListener('keydown', (e: KeyboardEvent) => {
            // Ignore if in an input field
            if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) {
                return;
            }
            
            const note = this.keyboardMapping[e.key.toLowerCase()];
            if (note) {
                const key = this.keys.find(k => k.dataset.note === note);
                if (key && !this.activeNotes.has(note)) {
                    this.keyDown(key);
                    e.preventDefault(); // Prevent default browser behavior
                }
            }
        });
        
        document.addEventListener('keyup', (e: KeyboardEvent) => {
            const note = this.keyboardMapping[e.key.toLowerCase()];
            if (note) {
                const key = this.keys.find(k => k.dataset.note === note);
                if (key) {
                    this.keyUp(key);
                }
            }
        });
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

            // Apply active styling directly
            if (key.classList.contains('white')) {
                key.style.backgroundColor = '#4CAF50';
                key.style.boxShadow = 'inset 0 0 10px rgba(0,0,0,0.2)';
                key.style.transform = 'translateY(2px)';
            } else {
                key.style.backgroundColor = '#2196F3';
                key.style.boxShadow = 'inset 0 0 10px rgba(0,0,0,0.4)';
                key.style.transform = 'translateY(2px)';
            }

            // Also add the class for compatibility
            key.classList.add('active');

            // Publish note activated event
            eventBus.publishNoteEvent(note, true, 'piano');

            this.updateChordDisplay();
        }
    }

    private keyUp(key: HTMLElement): void {
        const note = key.dataset.note;
        if (note) {
            this.activeNotes.delete(note);

            // Reset styling directly
            if (key.classList.contains('white')) {
                key.style.backgroundColor = 'white';
                key.style.boxShadow = 'none';
                key.style.transform = 'translateY(0)';
            } else {
                key.style.backgroundColor = 'black';
                key.style.boxShadow = 'none';
                key.style.transform = 'translateY(0)';
            }

            // Also remove the class for compatibility
            key.classList.remove('active');

            // Publish note deactivated event
            eventBus.publishNoteEvent(note, false, 'piano');

            this.updateChordDisplay();
        }
    }

    private updateChordDisplay(): void {
        const chordDetector = new ChordDetector();
        const chord = chordDetector.detectChord(Array.from(this.activeNotes));
        const currentChordElement = document.getElementById('current-chord');
        if (currentChordElement) {
            currentChordElement.textContent = chord || 'No chord detected';
            
            // Add a visual indicator when a chord is detected
            if (chord) {
                currentChordElement.classList.add('playing');
                setTimeout(() => {
                    currentChordElement.classList.remove('playing');
                }, 500);
            }
        }

        // Publish chord detected event
        if (chord) {
            eventBus.publishChordDetected(chord, 'piano');
        }
    }
}
