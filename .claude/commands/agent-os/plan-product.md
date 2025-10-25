## Product Planning Process

You are helping to plan and document the mission, roadmap and tech stack for the current product.  This will include:

- **Gathering Information**: The user's product vision, user personas, problems and key features
- **Tech Stack Preferences**: Explicit tech stack choices from the user
- **Mission Document**: Take what you've gathered and create a concise mission document
- **Roadmap**: Create a phased development plan with prioritized features
- **Tech Stack Document**: Document the technical stack used for all aspects of this product's codebase

This process will create these files in `agent-os/product/` directory.

### PHASE 0: Tech Stack Preferences (Critical)

**BEFORE launching the product-planner agent, check if the user has provided EXPLICIT tech stack preferences.**

Look for:
1. Tech stack mentioned in the user's request
2. Tech stack from previous conversation
3. Clear standards in `agent-os/standards/global/tech-stack.md` (if it exists)

**If NO clear tech preferences exist:**
- Inform the user: "Before creating your product plan, I need to understand your tech stack preferences. The product-planner agent will ask you about your choices for backend language, database, frontend, and deployment."
- Note this for the product-planner agent

**If tech preferences ARE provided:**
- Note them explicitly to pass to the product-planner agent
- Ensure they will be respected in the product documentation

### PHASE 1: Gather Product Requirements and Create Documentation

Use the **product-planner** subagent to create comprehensive product documentation.

**Provide to the product-planner agent:**
- Product idea, features, target users (if user provided)
- Tech stack preferences (if user provided or if standards exist)
- Instruction to ASK user for tech stack if not provided

The product-planner will:
- Confirm (or gather) product idea, features, target users
- ASK user for tech stack preferences if not already clear
- Create `agent-os/product/mission.md` with product vision and strategy
- Create `agent-os/product/roadmap.md` with phased development plan
- Create `agent-os/product/tech-stack.md` documenting the user's chosen tech stack

### PHASE 2: Display Results

Display to the user:
- Confirmation of files created
- Summary of product mission
- Roadmap phases overview

Output to user:

"Review these files to ensure they accurately capture your product vision and roadmap."

## Output

Upon completion, the following files should have been been created and delivered to the user:

- `agent-os/product/mission.md` - Full product vision and strategy
- `agent-os/product/roadmap.md` - Phased development plan
- `agent-os/product/tech-stack.md` - Tech stack list for this product
