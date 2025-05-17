# Harmoniq Project Meeting Notes


## Meeting Date: May 16, 2025
**Attendees:** Matthew Taruno (Developer), Toby Yuheng Zhao (Client)
**Duration:** 3:00 PM - 4:00 PM

I presented my system architecture diagram to Toby and presented the idea to potentially create the project in a mobile app format since that would be more useful and convenient from an end user perspective of somebody practicing on an actual piano.

Work has to be done this week as for how I would want to implement a audio (from the built in mic) to timeline converter. We are quite certain there should be online implementations that might get is 90 percent of the way there in terms of their offering but that has to be figured out soon in terms of the specific details of the implementation.


## Meeting Date: April 19, 2025
**Attendees:** Matthew Taruno (Developer), Toby Yuheng Zhao (Client)
**Duration:** 3:00 PM - 4:00 PM

### Agenda
1. Project Status Review
2. Technical Discussion
3. Next Steps
4. Action Items

### Project Status Review
#### Completed Items
- [x] Basic project structure setup
- [x] Express.js server with TypeScript configuration
- [x] Initial HTML template with basic styling
- [x] Development environment setup (npm scripts, TypeScript config)
- [x] Basic keyboard input detection

#### In Progress
- [ ] Interactive piano keyboard interface
- [ ] Real-time chord detection system
- [ ] Timeline view for chord progression

#### Blockers/Issues
- Need client input on audio processing library choice (Essentia.js vs Klangio)
- Need client approval on database approach (JSON files vs traditional database)

### Technical Discussion
#### Frontend
- [ ] Need to implement piano keyboard visualization
- [ ] Design chord display interface
- [ ] Plan timeline view UI components
- [ ] Consider using Web Audio API for sound generation

#### Backend
- [ ] Set up chord detection algorithm
- [ ] Implement chord progression analysis
- [ ] Design data structure for storing favorites
- [ ] Plan API endpoints for chord detection and analysis

### Next Steps
1. [ ] Implement basic piano keyboard interface with mouse/keyboard controls
2. [ ] Create chord pattern recognition algorithm
3. [ ] Develop real-time chord display
4. [ ] Set up basic note-to-frequency conversion

### Action Items
| Task | Owner | Due Date | Status |
|------|--------|----------|---------|
| Design piano keyboard UI | Matthew | April 26 | [ ] |
| Review and approve UI design | [Client] | April 26 | [ ] |
| Set up basic audio processing | Matthew | May 3 | [ ] |
| Review and test timeline view | [Client] | May 3 | [ ] |

### Notes
- Consider using Web MIDI API for better keyboard input handling
- Need to research music theory libraries for chord detection
- Consider adding unit tests for chord detection algorithm
- Look into WebSocket for real-time updates
- Schedule demo for client to test basic keyboard input

---

## Previous Meetings

### Initial Project Setup (April 18, 2024)
**Key Decisions:**
- Client approved TypeScript for both frontend and backend
- Confirmed minimalistic stack approach (HTML, CSS, TS, Node.js, Express)
- Approved starting with JSON files for data storage
- Selected Essentia.js as primary audio processing library

**Action Items Completed:**
- [x] Set up project repository
- [x] Configure TypeScript
- [x] Set up Express server
- [x] Create basic project structure

**Follow-up Items:**
- [ ] Client to review audio processing library options
- [ ] Client to approve database schema design
- [ ] Client to review and approve UI mockups 