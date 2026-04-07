# Core Evaluation Rubric

This is the evaluation framework that the LLM reviewer uses to assess Claude Code agent performance across sessions and tasks.

## Dimension 1: Delivery Integrity

**Core Question:** Did CC deliver everything it committed to? Did it verify its own work?

### Sub-dimensions

- **Completeness**: Did CC deliver everything it committed to, or were items silently dropped?
- **Verification**: Did CC verify output before claiming "done"?
- **False Positives**: Did CC claim completion without actually checking its work?

### Indicators

- ✓ Commits marked complete only after testing/review
- ✓ Explicit verification steps shown (running tests, reading output, checking file contents)
- ✓ Mid-task problems caught and fixed before claiming done
- ✗ "Done" claims immediately retracted by user correction
- ✗ Planned deliverables missing with no explanation
- ✗ Work partially done, marked complete

---

## Dimension 2: Communication Quality

**Core Question:** Did CC understand intent on first reading? Did it address substance or just surface?

### Sub-dimensions

- **Comprehension**: Did CC understand the user's intent correctly on first reading?
- **Responsiveness**: When corrected, did CC address the substance or just apologize?
- **Clarity-Seeking**: Did CC ask clarifying questions when requirements were ambiguous?
- **Signal-to-Noise**: Did response length match substance, or did verbosity increase without value?

### Indicators

- ✓ Requirements understood correctly on first pass
- ✓ Clarifying questions asked when ambiguous
- ✓ When corrected, root cause addressed with different approach
- ✓ Responses concise and focused
- ✗ Misunderstood primary intent
- ✗ Apologized but repeated same mistake
- ✗ Assumed requirements instead of asking
- ✗ Response length increased while deliverables decreased

---

## Dimension 3: Process & Tool Usage

**Core Question:** Were relevant skills and tools invoked? Were plans written and tasks created?

### Sub-dimensions

- **Skill Activation**: Were relevant skills invoked for the work type?
- **Task Tracking**: Were tasks created for multi-step work?
- **Planning**: Were plans written before complex implementations?
- **Tool Selection**: Were right tools used for the job?

### Indicators

- ✓ Brainstorming skill used before creative work
- ✓ Systematic debugging skill used before attempting fixes
- ✓ Writing-plans skill used before multi-step implementations
- ✓ Edit tool used for modifications, Write for new files
- ✓ Grep used instead of bash grep
- ✓ Tasks created for complex work with clear status tracking
- ✗ Jumped to implementation without planning
- ✗ Wrong tool for the job (Write instead of Edit, Bash grep instead of Grep)
- ✗ No task tracking for multi-step work
- ✗ No clarifying questions before attempting work

---

## Dimension 4: User Interaction Patterns

**Core Question:** Did user have to repeat themselves? Could requests have been structured better?

### Sub-dimensions

- **Repetition**: Did user have to repeat instructions?
- **Ambiguity**: Were instructions ambiguous where clarification would help?
- **Batching**: Did user batch too many disparate requests in one turn?
- **Structure**: Could user have structured requests more effectively?

### Indicators

- ✓ Clear, single-focus requests
- ✓ Each request gets full attention and completion
- ✓ User doesn't need to re-explain
- ✗ User repeats verbatim from earlier turns
- ✗ Ambiguous requirements never clarified
- ✗ User batches 5+ unrelated tasks
- ✗ CC handles first item, forgets about later items

---

## Dimension 5: Session Trajectory

**Core Question:** Did session maintain focus? At what point did quality degrade?

### Sub-dimensions

- **Focus**: Did session maintain focus on original goal?
- **Degradation**: At what point did quality degrade, if at all?
- **Context Pressure**: Was context window compression a factor in errors?
- **Session Boundaries**: Should session have been split?

### Indicators

- ✓ Sessions stay on goal through completion
- ✓ Quality consistent throughout
- ✓ Context used efficiently
- ✓ Session split when work changes domains
- ✗ Scope creep into unrelated work
- ✗ Clear degradation in quality mid-session
- ✗ Context limit reached before completion
- ✗ Multiple different goals in single session
- ✗ Errors only appear near context limit

---

## Scoring Framework

Each dimension should be evaluated as:

- **Strong** (3-4 points): Consistent positive indicators, no red flags
- **Adequate** (2 points): Mix of positive and minor issues
- **Weak** (0-1 points): Frequent red flags, missing key elements

**Total Range:** 0-20 points
