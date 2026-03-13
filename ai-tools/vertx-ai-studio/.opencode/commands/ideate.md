---
description: Brainstorm ideas with an audience-first creative ideation session
agent: ideate
---

$ARGUMENTS

If no arguments are provided:
1. Ask the user what topic or problem they want to brainstorm about.
2. Ask who the target audience is (roles, experience level, context).
3. Run a free-form ideation session using the perspective lenses.
4. Present ideas as a numbered list with audience impact noted for each.
5. Offer to deep-dive on any idea or delegate to @git-ops to create issues.

If arguments provide a topic but no audience:
1. Ask who the target audience is before generating ideas.
2. Once the audience is clear, diverge with 6-8 ideas across multiple angles.
3. Highlight which perspective lens each idea comes from.
4. Offer to score, rank, or expand on any ideas.

If arguments include both a topic and audience context:
1. Skip clarification and start diverging immediately.
2. Generate 8-12 ideas across at least 3 perspective lenses.
3. Flag any radical ideas with the three-part protocol (insight, risk, experiment).
4. Offer to evaluate and rank ideas, or delegate winners to @git-ops as issues.

If arguments include "--structured" or "structured session":
Run a full four-phase brainstorming session:

**Phase 1 -- Understand the Audience**
1. Confirm or ask about target users, pain points, and success criteria.
2. Summarize the audience profile before proceeding.

**Phase 2 -- Diverge**
3. Generate 8-12 ideas across at least 3 perspective lenses (frustrated user,
   power user, newcomer, competitor's user, non-user).
4. Include at least 2 radical ideas with the three-part protocol.
5. If brainstorming about a software project, read relevant source files first.

**Phase 3 -- Evaluate**
6. Score each idea on audience impact (1-5), feasibility (1-5), and novelty (1-5).
7. Present a ranked table sorted by weighted score (audience impact weighted 2x).

**Phase 4 -- Converge**
8. For each top idea, provide a concept description, minimal implementation
   approach, and first concrete next step.
9. For approved ideas, delegate to @git-ops to create GitHub issues.

After any session, ask the user if they want to:
- Go deeper on specific ideas
- Run a structured session (if not already in one)
- Create GitHub issues for actionable ideas (delegate to @git-ops)
