---
name: skill-lookup
description: Discover, retrieve, and learn about available Agent Skills. key capability for finding tools to solve specific problems.
---

# Skill Lookup

This skill allows the Agent to introspect its own capabilities and find the right tool for the job.

## Capabilities

### 1. Search Skills
Find skills by keyword, category, or tag.

- **Query**: "infrastructure", "flutter", "test"
- **Result**: List of matching skills with descriptions.

### 2. Get Skill Details
Retrieve the full instructions (`SKILL.md`) for a specific skill.

## When to Use

- User asks "Do you have a skill for X?"
- Agent is unsure how to perform a specialized task and wants to check if a skill exists.
- "List all available skills."

## How it Works (Conceptual)

The Agent should:
1.  Check the `.agent/skills` directory.
2.  Read the `SKILL.md` frontmatter to match requirements.
3.  Load the full `SKILL.md` if a match is found to learn the instructions.
