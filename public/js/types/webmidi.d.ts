interface Navigator {
    requestMIDIAccess(): Promise<MIDIAccess>;
}

interface MIDIAccess {
    inputs: MIDIInputMap;
    outputs: MIDIOutputMap;
    addEventListener(type: 'statechange', listener: (event: MIDIConnectionEvent) => void): void;
    removeEventListener(type: 'statechange', listener: (event: MIDIConnectionEvent) => void): void;
}

interface MIDIInputMap {
    forEach(callback: (input: MIDIInput) => void): void;
}

interface MIDIOutputMap {
    forEach(callback: (output: MIDIOutput) => void): void;
}

interface MIDIInput {
    name: string;
    type: 'input';
    state: 'connected' | 'disconnected';
    addEventListener(type: 'midimessage', listener: (event: MIDIMessageEvent) => void): void;
    removeEventListener(type: 'midimessage', listener: (event: MIDIMessageEvent) => void): void;
}

interface MIDIOutput {
    name: string;
    type: 'output';
    state: 'connected' | 'disconnected';
}

interface MIDIConnectionEvent {
    port: MIDIInput | MIDIOutput;
}

interface MIDIMessageEvent {
    data: [number, number, number];
} 