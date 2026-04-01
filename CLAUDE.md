# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is an economics research project studying how marital insurance (via matrimonial property regimes) affects job search behavior. It exploits the 2018 Dutch reform that changed the default property regime from universal to limited community property. Authors: Sofia Valdivia & Heleen Ren.

## Repository Structure

- **Code/**: Stata `.do` files for data processing and analysis
  - `descriptive_stats_dhs.do` — Main analysis file: imports DHS panel data (2010–2024), constructs variables (marital status, reservation wages, job search intensity), produces descriptive graphs, and runs preliminary regressions
- **Drafts/**: LaTeX paper draft (`proposal_draft.tex`) using `johd` style
- **Slides/**: Beamer presentation (`slides_marital_insurance.tex`) and bibliography (`bib.bib`)
- **Code/model**: Matlab files to solve the model 

## Data

- Primary data source: Dutch Household Survey (DHS), stored externally in Dropbox (`~/Dropbox/Research Ideas/2_Households_Savings/Source/DHS/`)
- DHS files follow naming convention: `wrk{year}en_{version}.dta` (work module) and `agw{year}en_{version}.dta` (assets/wealth module)
- Data is not committed to the repo; file paths are set per-user in the Stata do-files via `c(username)` conditionals
- Figures output to a separate `Household_Savings` GitHub repo's Figures directory

## Build Commands

- **Compile paper**: `latexmk -pdf Drafts/proposal_draft.tex`
- **Compile slides**: `cd Slides && bibtex slides_marital_insurance && latexmk -pdf slides_marital_insurance.tex`
- **Run Stata analysis**: Open `Code/descriptive_stats_dhs.do` in Stata (requires DHS data files in Dropbox)

## Key Variables in Stata Code

- `burgst` — marital status (1=community property, 2=separation of property, 4=cohabiting, 6/7=single)
- `rw_monthly` — constructed monthly reservation wage (combined from two survey questions)
- `married_after2018` — treatment indicator for the 2018 Dutch property regime reform
- `hsol` — number of job applications (search intensity measure)
- `nohhold` — household identifier used for clustering

## Conventions

- Stata graph styling uses `plotplain` scheme with `grstyle` and `colorpalette` packages
- LaTeX documents use `natbib`/`bibtex` for citations
- Beamer slides use Madrid theme with seahorse color theme

## Rules
- Always ask clarifying questions before starting a complex task
- Show your plan and steps before executing
- Cite sources when doing research

## Task-Based Workflow (Executor/Reviewer)

This project uses a structured task-based workflow for model implementation. The pattern is:

### Task Docs

All task docs live in `docs/` and follow the template in `docs/task_template.md`. Each task doc has:
- Structured metadata (ID, title, date, status, assignee)
- Motivation, specific goal, success criteria (checkboxes)
- Inputs/relevant files table
- Scope boundaries (DO / DO NOT)
- Append-only action log
- Outcome and next step (filled after review)

Status values: `open` | `in-progress` | `executor-done` | `in-review` | `accepted` | `rejected` | `blocked`

### Running the Executor

When the user says "run executor on task_XX":

1. Read `docs/task_XX.md` fully.
2. Update the task doc status to `in-progress` and append an action log entry.
3. Launch the executor agent with this prompt:

   > Execute the task described in docs/task_XX.md. Read the task doc first to understand scope, goal, success criteria, and relevant files. Read all files listed in the "Inputs / Relevant Files" table. Do only what the task doc says. Report back with: (1) what you checked, (2) what changed, (3) what you learned, (4) what remains uncertain, (5) next recommended step.

4. When the executor finishes, update the task doc:
   - Set status to `executor-done`
   - Append an action log entry summarizing what the executor did
   - Record any files created or modified

### Running the Reviewer

When the user says "run reviewer on task_XX":

1. Read `docs/task_XX.md` fully.
2. Update the task doc status to `in-review` and append an action log entry.
3. Launch the reviewer agent with this prompt:

   > Review the completed task described in docs/task_XX.md. Read the task doc, then read all files listed in "Inputs / Relevant Files" and any files the executor created or modified (check the action log). Verify each success criterion. Cross-reference any formulas against model3.tex and solution_tasks.md. Report: (1) what was verified, (2) what is correct, (3) what is uncertain, (4) ACCEPT or REJECT with reasons, (5) next recommended step.

4. When the reviewer finishes, update the task doc:
   - Set status to `accepted` or `rejected` based on the reviewer's decision
   - Append an action log entry with the reviewer's findings
   - Fill in the "Outcome" and "Next Recommended Step" sections

### Creating a New Task

1. Copy `docs/task_template.md` to `docs/task_XX.md` (increment the number).
2. Fill in all fields. Be specific about scope boundaries.
3. If there is a GitHub issue, link it. If not, write "n/a".
4. The task is ready when status is `open`.

### Key Principles

- **One task, one bounded goal.** If the executor says "this is too large", split it.
- **Source of truth is the LaTeX.** For any formula, `Drafts/model3.tex` is authoritative. `docs/solution_tasks.md` is the derived analytical reference.
- **Scope boundaries are hard limits.** The executor must not touch files outside the DO list.
- **The action log is the record.** All work is logged with dates.