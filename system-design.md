# Harmoniq System Design

## Current Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser Environment                       │
│                                                                  │
│  ┌──────────────┐       Direct Method Calls      ┌────────────┐  │
│  │              │◄──────────────────────────────►│            │  │
│  │  Piano.ts    │                                │ Timeline.ts │  │
│  │              │                                │            │  │
│  └──────┬───────┘                                └─────┬──────┘  │
│         │                                              │         │
│         │                                              │         │
│         │                                              │         │
│         │                                              │         │
│         ▼                                              ▼         │
│  ┌──────────────┐                                ┌────────────┐  │
│  │              │                                │            │  │
│  │ChordDetector │                                │ LocalStorage│  │
│  │              │                                │            │  │
│  └──────────────┘                                └────────────┘  │
│         ▲                                                        │
│         │                                                        │
│         │                                                        │
│  ┌──────┴───────┐                                                │
│  │              │                                                │
│  │MIDIVisualizer│                                                │
│  │              │                                                │
│  └──────────────┘                                                │
│         ▲                                                        │
│         │                                                        │
└─────────┼────────────────────────────────────────────────────────┘
          │
          │
┌─────────┴────────┐
│                  │
│   MIDI Device    │
│                  │
└──────────────────┘
```

## Current Data Flow

1. **User Input**:
   - User plays notes on piano (via mouse, keyboard, or MIDI device)
   - MIDI device sends signals to browser (if using MIDI)

2. **Note Processing**:
   - MIDIVisualizer captures MIDI signals and converts to note events
   - Piano class manages active notes and visual feedback
   - When notes change, Piano calls ChordDetector

3. **Chord Detection**:
   - ChordDetector analyzes active notes and identifies chords
   - Returns chord name to Piano class

4. **Timeline Update**:
   - Piano directly calls Timeline.addChord() when a chord is detected
   - Timeline stores chord in memory array and updates UI
   - Timeline also saves to localStorage for persistence

5. **User Interaction with Timeline**:
   - User can play, save, or clear chord history
   - Timeline manages these operations directly

## Limitations of Current Architecture

1. **Tight Coupling**: Components directly call methods on each other
2. **Limited Testability**: Hard to test components in isolation
3. **No Separation of Concerns**: UI and data logic are mixed
4. **No Central State Management**: State is distributed across components
5. **No API Layer**: Everything happens in the browser

## Proposed Event-Based Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Browser Environment                       │
│                                                                  │
│  ┌──────────────┐                                ┌────────────┐  │
│  │              │                                │            │  │
│  │  Piano.ts    │                                │ Timeline.ts │  │
│  │              │                                │            │  │
│  └──────┬───────┘                                └─────┬──────┘  │
│         │                                              │         │
│         │                                              │         │
│         │                                              │         │
│         │                                              │         │
│         ▼                                              ▼         │
│  ┌──────────────┐     ┌─────────────────┐       ┌────────────┐  │
│  │              │     │                 │       │            │  │
│  │ChordDetector │────►│  Event Bus      │◄──────│ LocalStorage│  │
│  │              │     │ (Custom Events) │       │            │  │
│  └──────────────┘     └─────────────────┘       └────────────┘  │
│         ▲                     ▲                                  │
│         │                     │                                  │
│         │                     │                                  │
│  ┌──────┴───────┐      ┌─────┴───────┐                          │
│  │              │      │             │                          │
│  │MIDIVisualizer│      │  UI Events  │                          │
│  │              │      │             │                          │
│  └──────────────┘      └─────────────┘                          │
│         ▲                                                        │
│         │                                                        │
└─────────┼────────────────────────────────────────────────────────┘
          │
          │
┌─────────┴────────┐
│                  │
│   MIDI Device    │
│                  │
└──────────────────┘
```
