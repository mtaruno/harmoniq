interface ChordWithTime {
    chord: string;
    timestamp: string;
}

export class Timeline {
    private timelineElement: HTMLElement | null;
    private chords: ChordWithTime[] = [];
    private maxChords: number = 20; // Maximum number of chords to display

    constructor() {
        this.timelineElement = document.getElementById('chord-timeline');
    }

    public addChord(chord: string): void {
        // Add timestamp to chord
        const chordWithTime: ChordWithTime = {
            chord: chord,
            timestamp: new Date().toLocaleTimeString()
        };

        this.chords.push(chordWithTime);

        // Keep only the last maxChords
        if (this.chords.length > this.maxChords) {
            this.chords.shift();
        }

        this.updateDisplay();
    }

    private updateDisplay(): void {
        if (!this.timelineElement) return;

        this.timelineElement.innerHTML = '';

        this.chords.forEach(({ chord, timestamp }) => {
            const chordElement = document.createElement('div');
            chordElement.className = 'timeline-chord';
            chordElement.innerHTML = `
                <div class="chord-name">${chord}</div>
                <div class="chord-time">${timestamp}</div>
            `;
            this.timelineElement?.appendChild(chordElement);
        });
    }

    public clear(): void {
        this.chords = [];
        this.updateDisplay();
    }
} 