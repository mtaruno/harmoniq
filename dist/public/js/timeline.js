"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.Timeline = void 0;
class Timeline {
    constructor() {
        this.chords = [];
        this.maxChords = 20; // Maximum number of chords to display
        this.timelineElement = document.getElementById('chord-timeline');
    }
    addChord(chord) {
        // Add timestamp to chord
        const chordWithTime = {
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
    updateDisplay() {
        if (!this.timelineElement)
            return;
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
    clear() {
        this.chords = [];
        this.updateDisplay();
    }
}
exports.Timeline = Timeline;
//# sourceMappingURL=timeline.js.map