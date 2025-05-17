/**
 * EventBus - A centralized event management system for Harmoniq
 * 
 * This module provides a way for components to communicate without direct dependencies.
 * Components can publish events and subscribe to events from other components.
 */

// Define event types
export interface ChordEvent {
    chord: string;
    timestamp: string;
    source: 'piano' | 'timeline' | 'midi';
}

export interface NoteEvent {
    note: string;
    active: boolean;
    source: 'piano' | 'keyboard' | 'midi';
}

export interface TimelineEvent {
    action: 'play' | 'stop' | 'clear' | 'save' | 'load';
    data?: any;
}

export interface MIDIEvent {
    status: 'connected' | 'disconnected' | 'error';
    device?: string;
    message?: string;
}

// Define event names as constants to avoid typos
export const EVENTS = {
    CHORD_DETECTED: 'harmoniq:chord-detected',
    CHORD_PLAYED: 'harmoniq:chord-played',
    NOTE_ACTIVATED: 'harmoniq:note-activated',
    NOTE_DEACTIVATED: 'harmoniq:note-deactivated',
    TIMELINE_ACTION: 'harmoniq:timeline-action',
    MIDI_STATUS: 'harmoniq:midi-status'
};

// EventBus class
export class EventBus {
    private static instance: EventBus;

    private constructor() {
        console.log('EventBus initialized');
    }

    // Singleton pattern
    public static getInstance(): EventBus {
        if (!EventBus.instance) {
            EventBus.instance = new EventBus();
        }
        return EventBus.instance;
    }

    // Publish a chord event
    public publishChordDetected(chord: string, source: 'piano' | 'timeline' | 'midi' = 'piano'): void {
        console.log(`Publishing chord detected: ${chord} from ${source}`);
        const event: ChordEvent = {
            chord,
            timestamp: new Date().toLocaleTimeString(),
            source
        };
        
        document.dispatchEvent(new CustomEvent(EVENTS.CHORD_DETECTED, { detail: event }));
    }

    // Publish a chord played event
    public publishChordPlayed(chord: string, source: 'piano' | 'timeline' | 'midi' = 'timeline'): void {
        console.log(`Publishing chord played: ${chord} from ${source}`);
        const event: ChordEvent = {
            chord,
            timestamp: new Date().toLocaleTimeString(),
            source
        };
        
        document.dispatchEvent(new CustomEvent(EVENTS.CHORD_PLAYED, { detail: event }));
    }

    // Publish a note event
    public publishNoteEvent(note: string, active: boolean, source: 'piano' | 'keyboard' | 'midi'): void {
        console.log(`Publishing note ${active ? 'activated' : 'deactivated'}: ${note} from ${source}`);
        const event: NoteEvent = {
            note,
            active,
            source
        };
        
        const eventName = active ? EVENTS.NOTE_ACTIVATED : EVENTS.NOTE_DEACTIVATED;
        document.dispatchEvent(new CustomEvent(eventName, { detail: event }));
    }

    // Publish a timeline action
    public publishTimelineAction(action: 'play' | 'stop' | 'clear' | 'save' | 'load', data?: any): void {
        console.log(`Publishing timeline action: ${action}`, data);
        const event: TimelineEvent = {
            action,
            data
        };
        
        document.dispatchEvent(new CustomEvent(EVENTS.TIMELINE_ACTION, { detail: event }));
    }

    // Publish MIDI status
    public publishMIDIStatus(status: 'connected' | 'disconnected' | 'error', device?: string, message?: string): void {
        console.log(`Publishing MIDI status: ${status}`, device, message);
        const event: MIDIEvent = {
            status,
            device,
            message
        };
        
        document.dispatchEvent(new CustomEvent(EVENTS.MIDI_STATUS, { detail: event }));
    }

    // Subscribe to chord detected events
    public subscribeToChordDetected(callback: (event: ChordEvent) => void): void {
        document.addEventListener(EVENTS.CHORD_DETECTED, ((e: CustomEvent) => {
            callback(e.detail);
        }) as EventListener);
    }

    // Subscribe to chord played events
    public subscribeToChordPlayed(callback: (event: ChordEvent) => void): void {
        document.addEventListener(EVENTS.CHORD_PLAYED, ((e: CustomEvent) => {
            callback(e.detail);
        }) as EventListener);
    }

    // Subscribe to note events
    public subscribeToNoteActivated(callback: (event: NoteEvent) => void): void {
        document.addEventListener(EVENTS.NOTE_ACTIVATED, ((e: CustomEvent) => {
            callback(e.detail);
        }) as EventListener);
    }

    public subscribeToNoteDeactivated(callback: (event: NoteEvent) => void): void {
        document.addEventListener(EVENTS.NOTE_DEACTIVATED, ((e: CustomEvent) => {
            callback(e.detail);
        }) as EventListener);
    }

    // Subscribe to timeline actions
    public subscribeToTimelineAction(callback: (event: TimelineEvent) => void): void {
        document.addEventListener(EVENTS.TIMELINE_ACTION, ((e: CustomEvent) => {
            callback(e.detail);
        }) as EventListener);
    }

    // Subscribe to MIDI status
    public subscribeToMIDIStatus(callback: (event: MIDIEvent) => void): void {
        document.addEventListener(EVENTS.MIDI_STATUS, ((e: CustomEvent) => {
            callback(e.detail);
        }) as EventListener);
    }
}

// Export a singleton instance
export default EventBus.getInstance();
