export class ChordDetector {
    private chordPatterns: Record<string, number[]> = {
        'maj': [0, 4, 7],
        'min': [0, 3, 7],
        'dim': [0, 3, 6],
        'aug': [0, 4, 8],
        'maj7': [0, 4, 7, 11],
        'min7': [0, 3, 7, 10],
        'dom7': [0, 4, 7, 10],
        'maj6': [0, 4, 7, 9],
        'min6': [0, 3, 7, 9]
    };

    public detectChord(notes: string[]): string | null {
        if (notes.length < 3) return null;

        // Convert notes to numbers (C4 = 0, C#4 = 1, etc.)
        const noteNumbers = notes.map(note => this.noteToNumber(note));

        // Sort and normalize to start from 0
        const sortedNotes = noteNumbers.sort((a, b) => a - b);
        const root = sortedNotes[0];
        const normalizedNotes = sortedNotes.map(note => (note - root + 12) % 12);

        // Check against known chord patterns
        for (const [chordType, pattern] of Object.entries(this.chordPatterns)) {
            if (this.matchesPattern(normalizedNotes, pattern)) {
                const rootNote = this.numberToNote(root);
                return `${rootNote}${chordType}`;
            }
        }

        return null;
    }

    private noteToNumber(note: string): number {
        const notes: Record<string, number> = {
            'C': 0, 'C#': 1, 'D': 2, 'D#': 3, 'E': 4, 'F': 5,
            'F#': 6, 'G': 7, 'G#': 8, 'A': 9, 'A#': 10, 'B': 11
        };
        const noteName = note.slice(0, -1);
        const octave = parseInt(note.slice(-1));
        return notes[noteName] + (octave * 12);
    }

    private numberToNote(number: number): string {
        const notes: string[] = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];
        const octave = Math.floor(number / 12);
        const noteIndex = number % 12;
        return notes[noteIndex] + octave;
    }

    private matchesPattern(notes: number[], pattern: number[]): boolean {
        if (notes.length !== pattern.length) return false;

        // Check if all notes in the pattern are present
        return pattern.every(interval => notes.includes(interval));
    }
} 