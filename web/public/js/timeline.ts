import eventBus from './event-bus.js';

interface ChordWithTime {
    chord: string;
    timestamp: string;
    id?: string; // Unique identifier for each chord entry
}

interface TimelineOptions {
    maxChords?: number;
    storageKey?: string;
}

export class Timeline {
    private static instance: Timeline;
    private timelineElement: HTMLElement | null;
    private chords: ChordWithTime[] = [];
    private maxChords: number = 20; // Maximum number of chords to display
    private storageKey: string = 'harmoniq_chord_history';
    private isPlaying: boolean = false;
    private currentPlaybackIndex: number = 0;
    private playbackInterval: number | null = null;

    constructor(options?: TimelineOptions) {
        console.log('Timeline constructor called');

        // Apply options if provided
        if (options) {
            if (options.maxChords) this.maxChords = options.maxChords;
            if (options.storageKey) this.storageKey = options.storageKey;
        }

        // Use the correct HTML ID from index.html
        this.timelineElement = document.getElementById('timeline');
        console.log('Timeline element found:', !!this.timelineElement);

        // Initialize the timeline with a header and controls if it doesn't already exist
        if (this.timelineElement) {
            console.log('Setting up timeline content');

            // Check if the timeline already has content
            const hasContent = this.timelineElement.querySelector('.timeline-header');

            if (!hasContent) {
                console.log('Timeline element is empty, initializing content');
                this.timelineElement.innerHTML = `
                    <div class="timeline-header">
                        <h3>Chord History</h3>
                        <div class="timeline-controls">
                            <button id="play-timeline" class="btn btn-play" title="Play chord progression">▶ Play</button>
                            <button id="save-timeline" class="btn btn-save" title="Save chord progression">💾 Save</button>
                            <button id="clear-timeline" class="btn btn-clear" title="Clear history">🗑️ Clear</button>
                        </div>
                    </div>
                    <div id="chord-list"></div>
                    <div id="saved-progressions" class="saved-progressions">
                        <h4>Saved Progressions</h4>
                        <div id="saved-list"></div>
                    </div>
                `;
            } else {
                console.log('Timeline element already has content');
            }

            // Add event listeners for buttons
            const clearButton = this.timelineElement.querySelector('#clear-timeline');
            if (clearButton) {
                console.log('Adding event listener to clear button');
                clearButton.addEventListener('click', () => {
                    console.log('Clear button clicked');
                    eventBus.publishTimelineAction('clear');
                });
            } else {
                console.error('Clear button not found');
            }

            const playButton = this.timelineElement.querySelector('#play-timeline');
            if (playButton) {
                console.log('Adding event listener to play button');
                playButton.addEventListener('click', () => {
                    console.log('Play button clicked');
                    const action = this.isPlaying ? 'stop' : 'play';
                    eventBus.publishTimelineAction(action);
                });
            } else {
                console.error('Play button not found');
            }

            const saveButton = this.timelineElement.querySelector('#save-timeline');
            if (saveButton) {
                console.log('Adding event listener to save button');
                saveButton.addEventListener('click', () => {
                    console.log('Save button clicked');
                    eventBus.publishTimelineAction('save');
                });
            } else {
                console.error('Save button not found');
            }
        }

        // Load chords from localStorage
        this.loadFromStorage();

        // Subscribe to events
        this.subscribeToEvents();
    }

    // Subscribe to events from the EventBus
    private subscribeToEvents(): void {
        console.log('Timeline subscribing to events');

        // Subscribe to chord detected events
        eventBus.subscribeToChordDetected((event) => {
            console.log('Timeline received chord detected event:', event);
            this.addChord(event.chord);
        });

        // Subscribe to timeline action events
        eventBus.subscribeToTimelineAction((event) => {
            console.log('Timeline received action event:', event);

            switch (event.action) {
                case 'play':
                    this.startPlayback();
                    break;
                case 'stop':
                    this.stopPlayback();
                    break;
                case 'clear':
                    this.clear();
                    break;
                case 'save':
                    this.saveProgression();
                    break;
                case 'load':
                    if (event.data && event.data.id) {
                        this.loadProgression(event.data.id);
                    }
                    break;
            }
        });
    }

    // Singleton pattern
    public static getInstance(): Timeline {
        console.log('Timeline.getInstance called');
        if (!Timeline.instance) {
            console.log('Creating new Timeline instance');
            Timeline.instance = new Timeline();

            // Ensure the timeline is properly initialized
            setTimeout(() => {
                if (Timeline.instance && Timeline.instance.chords.length === 0) {
                    console.log('Timeline initialized but empty, checking DOM elements');
                    const timelineElement = document.getElementById('timeline');
                    const chordList = timelineElement?.querySelector('#chord-list');

                    if (timelineElement) {
                        console.log('Timeline element exists in DOM');
                        timelineElement.style.display = 'block';
                        timelineElement.style.border = '2px solid blue';
                    } else {
                        console.error('Timeline element not found in DOM after initialization');
                    }

                    if (chordList) {
                        console.log('Chord list element exists in DOM');
                    } else {
                        console.error('Chord list element not found in DOM after initialization');
                    }
                }
            }, 500);
        } else {
            console.log('Returning existing Timeline instance');
        }
        return Timeline.instance;
    }

    // Generate a unique ID for chord entries
    private generateId(): string {
        return Date.now().toString(36) + Math.random().toString(36).substring(2);
    }

    // Load chord history from localStorage
    private loadFromStorage(): void {
        console.log('Loading chords from localStorage');
        try {
            const savedChords = localStorage.getItem(this.storageKey);
            if (savedChords) {
                console.log('Found saved chords in localStorage');
                this.chords = JSON.parse(savedChords);
                console.log(`Loaded ${this.chords.length} chords from storage`);
                this.updateDisplay();
            } else {
                console.log('No saved chords found in localStorage');
            }
        } catch (error) {
            console.error('Error loading chord history from storage:', error);
        }
    }

    // Save chord history to localStorage
    private saveToStorage(): void {
        console.log(`Saving ${this.chords.length} chords to localStorage`);
        try {
            const jsonData = JSON.stringify(this.chords);
            localStorage.setItem(this.storageKey, jsonData);
            console.log('Chords saved to localStorage successfully');
        } catch (error) {
            console.error('Error saving chord history to storage:', error);
        }
    }

    // Add a chord to the timeline
    public addChord(chord: string): void {
        console.log(`Adding chord to timeline: ${chord}`);

        // Add timestamp and ID to chord
        const chordWithTime: ChordWithTime = {
            chord: chord,
            timestamp: new Date().toLocaleTimeString(),
            id: this.generateId()
        };

        this.chords.push(chordWithTime);
        console.log(`Timeline now has ${this.chords.length} chords`);

        // Keep only the last maxChords
        if (this.chords.length > this.maxChords) {
            this.chords.shift();
        }

        // Save to localStorage
        this.saveToStorage();

        // Update the display
        this.updateDisplay();

        // Debug check if timeline element exists
        if (!this.timelineElement) {
            console.error('Timeline element not found when adding chord');
        } else {
            console.log('Timeline element exists when adding chord');
            // Force the timeline to be visible
            this.timelineElement.style.display = 'block';
            this.timelineElement.style.border = '2px solid red';
            this.timelineElement.style.minHeight = '200px';
        }
    }

    // Update the timeline display
    private updateDisplay(): void {
        console.log('Updating timeline display');
        const chordList = this.timelineElement?.querySelector('#chord-list');
        if (!chordList) {
            console.error('Chord list element not found');
            return;
        }

        console.log(`Updating display with ${this.chords.length} chords`);
        chordList.innerHTML = '';

        if (this.chords.length === 0) {
            chordList.innerHTML = '<div class="empty-message">No chords played yet</div>';

            // Disable play and save buttons when no chords
            const playButton = this.timelineElement?.querySelector('#play-timeline') as HTMLButtonElement;
            const saveButton = this.timelineElement?.querySelector('#save-timeline') as HTMLButtonElement;

            if (playButton) playButton.disabled = true;
            if (saveButton) saveButton.disabled = true;

            return;
        } else {
            // Enable buttons when chords exist
            const playButton = this.timelineElement?.querySelector('#play-timeline') as HTMLButtonElement;
            const saveButton = this.timelineElement?.querySelector('#save-timeline') as HTMLButtonElement;

            if (playButton) playButton.disabled = false;
            if (saveButton) saveButton.disabled = false;
        }

        // Create chord elements
        this.chords.forEach(({ chord, timestamp, id }, index) => {
            const chordElement = document.createElement('div');
            chordElement.className = 'timeline-chord';
            if (id) chordElement.dataset.id = id;

            // Add a special class for the most recent chord
            if (index === this.chords.length - 1) {
                chordElement.classList.add('latest');
            }

            // Add a class for the currently playing chord during playback
            if (this.isPlaying && index === this.currentPlaybackIndex) {
                chordElement.classList.add('playing');
            }

            chordElement.innerHTML = `
                <div class="chord-name">${chord}</div>
                <div class="chord-time">${timestamp}</div>
                <div class="chord-actions">
                    <button class="btn-small play-chord" title="Play this chord">▶</button>
                    <button class="btn-small remove-chord" title="Remove this chord">×</button>
                </div>
            `;

            // Add event listeners for chord actions
            const playChordBtn = chordElement.querySelector('.play-chord');
            if (playChordBtn) {
                playChordBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    this.playChord(chord);
                });
            }

            const removeChordBtn = chordElement.querySelector('.remove-chord');
            if (removeChordBtn) {
                removeChordBtn.addEventListener('click', (e) => {
                    e.stopPropagation();
                    if (id) this.removeChord(id);
                });
            }

            chordList.appendChild(chordElement);
        });

        // Update saved progressions list
        this.updateSavedProgressions();
    }

    // Remove a specific chord by ID
    private removeChord(id: string): void {
        this.chords = this.chords.filter(chord => chord.id !== id);
        this.saveToStorage();
        this.updateDisplay();
    }

    // Clear all chords
    public clear(): void {
        this.chords = [];
        this.saveToStorage();
        this.updateDisplay();

        // Stop playback if it's running
        this.stopPlayback();
    }

    // Play a single chord (highlight it on the piano)
    private playChord(chordName: string): void {
        // This is a placeholder - in a real implementation, you would:
        // 1. Parse the chord name to get the notes
        // 2. Highlight those notes on the piano
        // 3. Play the corresponding sounds (if sound is implemented)
        console.log(`Playing chord: ${chordName}`);

        // Publish chord played event
        eventBus.publishChordPlayed(chordName, 'timeline');

        // For now, just highlight the chord in the UI
        const currentChordElement = document.getElementById('current-chord');
        if (currentChordElement) {
            const originalText = currentChordElement.textContent;
            currentChordElement.textContent = chordName;
            currentChordElement.classList.add('playing');

            // Reset after a short delay
            setTimeout(() => {
                currentChordElement.textContent = originalText;
                currentChordElement.classList.remove('playing');
            }, 1000);
        }
    }

    // Toggle playback of the chord progression
    public togglePlayback(): void {
        if (this.isPlaying) {
            this.stopPlayback();
        } else {
            this.startPlayback();
        }
    }

    // Start playing the chord progression
    private startPlayback(): void {
        if (this.chords.length === 0) return;

        this.isPlaying = true;
        this.currentPlaybackIndex = 0;

        // Update button text
        const playButton = this.timelineElement?.querySelector('#play-timeline');
        if (playButton) {
            playButton.textContent = '⏹ Stop';
            playButton.classList.add('playing');
        }

        // Play the first chord immediately
        this.playChord(this.chords[this.currentPlaybackIndex].chord);

        // Set up interval to play subsequent chords
        this.playbackInterval = window.setInterval(() => {
            this.currentPlaybackIndex++;

            // If we've reached the end, stop playback
            if (this.currentPlaybackIndex >= this.chords.length) {
                this.stopPlayback();
                return;
            }

            // Play the current chord
            this.playChord(this.chords[this.currentPlaybackIndex].chord);

            // Update the display to highlight the current chord
            this.updateDisplay();
        }, 1500); // Play each chord for 1.5 seconds
    }

    // Stop playback
    private stopPlayback(): void {
        if (this.playbackInterval) {
            clearInterval(this.playbackInterval);
            this.playbackInterval = null;
        }

        this.isPlaying = false;
        this.currentPlaybackIndex = 0;

        // Update button text
        const playButton = this.timelineElement?.querySelector('#play-timeline');
        if (playButton) {
            playButton.textContent = '▶ Play';
            playButton.classList.remove('playing');
        }

        // Update display to remove highlighting
        this.updateDisplay();
    }

    // Save the current chord progression
    public saveProgression(): void {
        if (this.chords.length === 0) return;

        // Prompt for a name
        const name = prompt('Enter a name for this chord progression:');
        if (!name) return; // User cancelled

        try {
            // Get existing saved progressions
            let savedProgressions: any[] = [];
            const saved = localStorage.getItem('harmoniq_saved_progressions');
            if (saved) {
                savedProgressions = JSON.parse(saved);
            }

            // Add the new progression
            savedProgressions.push({
                id: this.generateId(),
                name: name,
                date: new Date().toLocaleDateString(),
                chords: this.chords.map(c => c.chord) // Just save the chord names
            });

            // Save back to localStorage
            localStorage.setItem('harmoniq_saved_progressions', JSON.stringify(savedProgressions));

            // Update the display
            this.updateSavedProgressions();

            alert(`Progression "${name}" saved successfully!`);
        } catch (error) {
            console.error('Error saving progression:', error);
            alert('Failed to save progression. Please try again.');
        }
    }

    // Update the saved progressions list
    private updateSavedProgressions(): void {
        const savedList = this.timelineElement?.querySelector('#saved-list');
        if (!savedList) return;

        try {
            // Get saved progressions
            const saved = localStorage.getItem('harmoniq_saved_progressions');
            if (!saved) {
                savedList.innerHTML = '<div class="empty-message">No saved progressions</div>';
                return;
            }

            const savedProgressions = JSON.parse(saved);
            if (savedProgressions.length === 0) {
                savedList.innerHTML = '<div class="empty-message">No saved progressions</div>';
                return;
            }

            // Clear the list
            savedList.innerHTML = '';

            // Add each saved progression
            savedProgressions.forEach((prog: any) => {
                const progElement = document.createElement('div');
                progElement.className = 'saved-progression';
                progElement.dataset.id = prog.id;

                progElement.innerHTML = `
                    <div class="progression-header">
                        <div class="progression-name">${prog.name}</div>
                        <div class="progression-date">${prog.date}</div>
                    </div>
                    <div class="progression-chords">${prog.chords.join(' → ')}</div>
                    <div class="progression-actions">
                        <button class="btn-small load-progression" title="Load this progression">Load</button>
                        <button class="btn-small delete-progression" title="Delete this progression">Delete</button>
                    </div>
                `;

                // Add event listeners
                const loadBtn = progElement.querySelector('.load-progression');
                if (loadBtn) {
                    loadBtn.addEventListener('click', () => this.loadProgression(prog.id));
                }

                const deleteBtn = progElement.querySelector('.delete-progression');
                if (deleteBtn) {
                    deleteBtn.addEventListener('click', () => this.deleteProgression(prog.id));
                }

                savedList.appendChild(progElement);
            });
        } catch (error) {
            console.error('Error updating saved progressions:', error);
            savedList.innerHTML = '<div class="error-message">Error loading saved progressions</div>';
        }
    }

    // Load a saved progression
    private loadProgression(id: string): void {
        try {
            // Get saved progressions
            const saved = localStorage.getItem('harmoniq_saved_progressions');
            if (!saved) return;

            const savedProgressions = JSON.parse(saved);
            const progression = savedProgressions.find((p: any) => p.id === id);

            if (!progression) {
                console.error('Progression not found:', id);
                return;
            }

            // Confirm before replacing current chords
            if (this.chords.length > 0) {
                if (!confirm('This will replace your current chord history. Continue?')) {
                    return;
                }
            }

            // Clear current chords
            this.chords = [];

            // Add each chord from the saved progression
            progression.chords.forEach((chordName: string) => {
                this.chords.push({
                    chord: chordName,
                    timestamp: new Date().toLocaleTimeString(),
                    id: this.generateId()
                });
            });

            // Save to storage and update display
            this.saveToStorage();
            this.updateDisplay();

            alert(`Loaded progression "${progression.name}"`);
        } catch (error) {
            console.error('Error loading progression:', error);
            alert('Failed to load progression. Please try again.');
        }
    }

    // Delete a saved progression
    private deleteProgression(id: string): void {
        try {
            // Confirm deletion
            if (!confirm('Are you sure you want to delete this progression?')) {
                return;
            }

            // Get saved progressions
            const saved = localStorage.getItem('harmoniq_saved_progressions');
            if (!saved) return;

            let savedProgressions: any[] = JSON.parse(saved);

            // Remove the progression with the given ID
            savedProgressions = savedProgressions.filter((p: any) => p.id !== id);

            // Save back to localStorage
            localStorage.setItem('harmoniq_saved_progressions', JSON.stringify(savedProgressions));

            // Update the display
            this.updateSavedProgressions();

            alert('Progression deleted successfully');
        } catch (error) {
            console.error('Error deleting progression:', error);
            alert('Failed to delete progression. Please try again.');
        }
    }
}