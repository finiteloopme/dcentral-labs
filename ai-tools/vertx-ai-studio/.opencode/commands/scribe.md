---
description: Generate codebase-grounded technical content (blog posts, deep-dives, tutorials, explanations)
agent: scribe
---

$ARGUMENTS

If no arguments are provided:
1. Load the blog-conventions skill
2. Explore the project structure, README, and key source files
3. Ask the user which content type they want:
   - Project overview
   - Architecture deep-dive
   - Feature spotlight
   - Tutorial/how-to
   - Release narrative
   - Explain (comprehension mode)
4. Ask which aspect of the project to focus on
5. Ask about tone: external (default), internal, or marketing
6. Present an outline for confirmation before writing

If arguments specify a type (e.g., "overview", "deep-dive", "spotlight",
"tutorial", "release", "explain"):
1. Explore the project to understand structure and purpose
2. For "release": ask for version range or use latest tag
3. For "spotlight": ask which feature/concept if not specified
4. Present outline for confirmation, then generate content
5. Offer to save to file

If arguments include a specific topic (e.g., "spotlight workspace isolation"):
1. Focus exploration on the specified topic
2. Read relevant source files and git history
3. Present outline, then generate focused content
4. Offer to save to file

If arguments include "--tone=internal" or "--tone=marketing":
1. Apply the specified tone preset from blog-conventions
2. Default is "external" if not specified

If arguments include "--save" or "save to <path>":
1. Generate the content as above
2. Write to the specified path (or default: docs/blog/<slug>.md)
3. Report the file path

After any generation, ask the user if they want to:
- Adjust the tone, depth, or focus
- Expand or trim specific sections
- Add or remove code snippets
- Save to a file (if not already saved)
- Generate a different type of content on the same project
