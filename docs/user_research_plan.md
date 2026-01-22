# Loan Ranger – User Research Plan

## Objectives
- Validate whether the revamped comparison experience and qualification workflows meet loan officer expectations for speed and clarity.
- Quantify appetite for deeper data integrations (tax, rate feeds) and identify compliance constraints before investing in APIs.
- Gather SUS (System Usability Scale) benchmarks and qualitative feedback to guide Phase 5 polish.

## Participants
- Recruit 6–8 licensed loan officers (mix of retail and wholesale) from existing customer list.
- Screening: 3+ years originating loans, works across conventional + FHA, comfortable with desktop + mobile.
- Incentive: \$150 gift card or donation per 45-minute moderated session.

## Methodology
1. **Prototype walkthrough (30 min)**
   - Scenario-based tasks covering: building two comparison scenarios, running qualification, launching ARM wizard, exporting data.
   - Observe completion time, note friction, capture think-aloud quotes.
2. **Deep-dive interview (10 min)**
   - Explore appetite for live tax feeds, pricing engines, compliance hurdles.
   - Document required data granularity and approval workflow for external sources.
3. **Wrap-up (5 min)**
   - Administer SUS survey.
   - Rank most valuable potential integrations (tax, MI auto-drop, LOS sync, etc.).

## Logistics
- Conduct sessions remotely via Zoom with recorded consent.
- Use Figma prototype + instrumented Flutter build (feature flags) for realistic flows.
- Assign notetaker to tag observations against themes (comparison, qualification, ARM, export).

## Analysis & Deliverables
- Synthesize findings into:
  - Heatmap of friction points per workflow.
  - Prioritized integration backlog with evidence quotes.
  - SUS score trend and qualitative highlights.
- Share readout in sprint review; convert top integration requests into roadmap epics before API contracts begin.
