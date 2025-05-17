export declare class ChordDetector {
    private chordPatterns;
    detectChord(notes: string[]): string | null;
    private noteToNumber;
    private numberToNote;
    private matchesPattern;
}
