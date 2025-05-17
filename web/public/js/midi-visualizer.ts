import { Piano } from './piano.js';
import eventBus from './event-bus.js';

interface MIDIDeviceInfo {
    id: string;
    name: string;
    manufacturer: string;
    state: string;
    type: string;
    connection: string;
}

export class MIDIVisualizer {
    private midiAccess: MIDIAccess | null = null;
    private piano: Piano;
    private midiStatusElement: HTMLElement | null;
    private midiDevicesListElement: HTMLElement | null;
    private connectedDevices: Map<string, MIDIDeviceInfo> = new Map();
    private activeDevice: string | null = null;

    constructor(piano: Piano) {
        console.log('MIDIVisualizer constructor called');
        this.piano = piano;
        this.midiStatusElement = document.getElementById('midi-status');
        this.midiDevicesListElement = document.getElementById('midi-devices-list');

        // Make MIDI elements visible
        this.showMIDIElements();

        this.initializeMIDI();
    }

    // Show MIDI UI elements
    private showMIDIElements(): void {
        console.log('Showing MIDI UI elements');

        // Show MIDI status indicator
        if (this.midiStatusElement) {
            this.midiStatusElement.style.display = 'block';
        }

        // Show MIDI devices container
        const devicesContainer = document.getElementById('midi-devices-container');
        if (devicesContainer) {
            devicesContainer.style.display = 'block';
        }
    }

    private async initializeMIDI(): Promise<void> {
        try {
            if (!navigator.requestMIDIAccess) {
                console.error('Web MIDI API is not supported in this browser');
                this.updateMIDIStatus('error', 'MIDI: Not Supported in this browser');
                return;
            }

            this.updateMIDIStatus('pending', 'MIDI: Requesting Access...');

            try {
                this.midiAccess = await navigator.requestMIDIAccess();
                console.log('MIDI access granted');
                this.updateMIDIStatus('connected', 'MIDI: Access Granted');
                this.setupMIDIListeners();
                this.updateDevicesList();
            } catch (error) {
                console.error('Error accessing MIDI devices:', error);
                this.updateMIDIStatus('error', 'MIDI: Access Denied');
            }
        } catch (error) {
            console.error('Error in MIDI initialization:', error);
            this.updateMIDIStatus('error', 'MIDI: Initialization Error');
        }
    }

    private updateMIDIStatus(status: 'connected' | 'error' | 'pending', message: string): void {
        // Publish MIDI status event
        eventBus.publishMIDIStatus(status === 'connected' ? 'connected' :
            status === 'error' ? 'error' : 'disconnected',
            undefined, message);

        if (this.midiStatusElement) {
            // Make sure the element is visible
            this.midiStatusElement.style.display = 'block';

            this.midiStatusElement.textContent = message;

            // Reset classes
            this.midiStatusElement.classList.remove('connected', 'error', 'pending');

            // Add appropriate class
            if (status === 'connected') {
                this.midiStatusElement.classList.add('connected');
            } else if (status === 'error') {
                this.midiStatusElement.classList.add('error');
            } else if (status === 'pending') {
                this.midiStatusElement.classList.add('pending');
            }
        }
    }

    private setupMIDIListeners(): void {
        if (!this.midiAccess) return;

        this.midiAccess.addEventListener('statechange', (event: MIDIConnectionEvent) => {
            console.log('MIDI state change:', event);
            const port = event.port;

            // Update our device list when MIDI devices connect/disconnect
            this.updateDevicesList();

            if (port && port.type === 'input') {
                if (port.state === 'connected') {
                    this.setupInputDevice(port as MIDIInput);
                    this.updateMIDIStatus('connected', `MIDI: Connected to ${port.name || 'device'}`);
                } else if (port.state === 'disconnected') {
                    this.updateMIDIStatus('pending', `MIDI: Device ${port.name || ''} disconnected`);

                    // If this was our active device, clear the active device
                    if (this.activeDevice === port.id) {
                        this.activeDevice = null;
                    }
                }
            }
        });

        // Set up existing input devices
        this.midiAccess.inputs.forEach((input: MIDIInput) => {
            if (input.state === 'connected') {
                this.setupInputDevice(input);

                // Set the first connected device as active by default
                if (!this.activeDevice) {
                    this.activeDevice = input.id;
                    this.updateMIDIStatus('connected', `MIDI: Connected to ${input.name || 'device'}`);
                }
            }
        });
    }

    private updateDevicesList(): void {
        if (!this.midiAccess || !this.midiDevicesListElement) return;

        // Make sure the devices container is visible
        const devicesContainer = document.getElementById('midi-devices-container');
        if (devicesContainer) {
            devicesContainer.style.display = 'block';
        }

        // Clear the current list
        this.midiDevicesListElement.innerHTML = '';
        this.connectedDevices.clear();

        let hasDevices = false;

        // Add all input devices to the list
        this.midiAccess.inputs.forEach((input: MIDIInput) => {
            hasDevices = true;

            // Store device info
            const deviceInfo: MIDIDeviceInfo = {
                id: input.id,
                name: input.name || 'Unknown Device',
                manufacturer: input.manufacturer || 'Unknown Manufacturer',
                state: input.state,
                type: input.type,
                connection: input.connection
            };

            this.connectedDevices.set(input.id, deviceInfo);

            // Create device element
            const deviceElement = document.createElement('div');
            deviceElement.className = `midi-device ${input.id === this.activeDevice ? 'active' : ''}`;
            deviceElement.dataset.deviceId = input.id;

            deviceElement.innerHTML = `
                <div>
                    <div class="midi-device-name">${deviceInfo.name}</div>
                    <div class="midi-device-info">${deviceInfo.manufacturer} (${deviceInfo.state})</div>
                </div>
                <div>
                    <button class="select-device-btn">Use This Device</button>
                </div>
            `;

            // Add click handler to select this device
            const selectBtn = deviceElement.querySelector('.select-device-btn');
            if (selectBtn) {
                selectBtn.addEventListener('click', () => {
                    this.setActiveDevice(input.id);
                });
            }

            if (this.midiDevicesListElement) {
                this.midiDevicesListElement.appendChild(deviceElement);
            }
        });

        if (!hasDevices) {
            this.midiDevicesListElement.innerHTML = '<div>No MIDI devices detected. Please connect a MIDI device and refresh the page.</div>';
        }
    }

    private setActiveDevice(deviceId: string): void {
        this.activeDevice = deviceId;

        // Update UI to show active device
        const deviceElements = document.querySelectorAll('.midi-device');
        deviceElements.forEach((el) => {
            if (el instanceof HTMLElement) {
                if (el.dataset.deviceId === deviceId) {
                    el.classList.add('active');
                } else {
                    el.classList.remove('active');
                }
            }
        });

        // Update status
        const deviceInfo = this.connectedDevices.get(deviceId);
        if (deviceInfo) {
            this.updateMIDIStatus('connected', `MIDI: Using ${deviceInfo.name}`);
        }
    }

    private setupInputDevice(input: MIDIInput): void {
        input.addEventListener('midimessage', (event: MIDIMessageEvent) => {
            // Only process messages from the active device
            if (this.activeDevice && input.id === this.activeDevice) {
                if (event.data) {
                    const data = Array.from(event.data) as [number, number, number];
                    this.handleMIDIMessage(data);
                }
            }
        });
    }

    private handleMIDIMessage(data: [number, number, number]): void {
        const [status, note, velocity] = data;
        const isNoteOn = (status & 0xF0) === 0x90; // MIDI note on message (channel agnostic)
        const isNoteOff = (status & 0xF0) === 0x80; // MIDI note off message (channel agnostic)

        // Some devices send a note-on with velocity 0 instead of a note-off
        const isEffectiveNoteOff = isNoteOff || (isNoteOn && velocity === 0);

        if (isNoteOn || isEffectiveNoteOff) {
            const noteName = this.midiNoteToNoteName(note);
            if (noteName) {
                // Publish note event through the event bus
                eventBus.publishNoteEvent(noteName, isNoteOn && velocity > 0, 'midi');

                // Also update the piano directly for backward compatibility
                const keyElement = document.querySelector(`[data-note="${noteName}"]`);
                if (keyElement instanceof HTMLElement) {
                    if (isNoteOn && velocity > 0) {
                        this.piano['keyDown'](keyElement);
                    } else {
                        this.piano['keyUp'](keyElement);
                    }
                } else {
                    // Note is outside our piano range
                    console.log(`Note ${noteName} (MIDI ${note}) is outside the piano range`);
                }
            }
        }
    }

    private midiNoteToNoteName(midiNote: number): string | null {
        const noteNames = ['C', 'C#', 'D', 'D#', 'E', 'F', 'F#', 'G', 'G#', 'A', 'A#', 'B'];

        // MIDI note 60 is middle C (C4)
        const octave = Math.floor(midiNote / 12) - 1;
        const noteIndex = midiNote % 12;

        // Check if the note is within our piano's range (C3-C5)
        // Akai MPK Mini 25 has 25 keys from C3 to C5
        if (octave >= 3 && octave <= 5) {
            // Only include C5, not the rest of octave 5
            if (octave === 5 && noteIndex > 0) {
                return null;
            }
            return `${noteNames[noteIndex]}${octave}`;
        }

        return null;
    }
}