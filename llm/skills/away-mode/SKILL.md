---
name: away-mode
description: Run a repo's yaks unattended while Jess is away. The main session coordinates and does all work in subagents; each yak agent works in its own worktree and keeps its own HTML report page in a shared directory; the coordinator merges each branch to main and keeps an index page. Use when Jess says "away mode", "I'll be out for a few hours, work the yaks", or "do another round".
---

# Away mode

Jess is away for hours. You are the coordinator. Keep your own context small: every piece of real work happens in a subagent, and you read only their short final reports. You pick nothing, write nothing, and fix nothing yourself, except merges and worktree cleanup.

## The report directory

Everything the run produces for Jess lives in `away/` at the repo root, committed to main:

- `index.html`: the overview. Coordinator-owned.
- `<agent>.html`: one page per agent, named after the agent. Only that agent edits it while it works, so pages never conflict at merge.
- `FORMAT.md`: the page format, copied from `FORMAT.md` beside this skill. Every yak agent reads it.

`away/` is scratch. Jess deletes it once she has reviewed it, so write for her review, not for posterity: no dates in paths, no archive structure. Anything worth keeping goes into commit messages, CLAUDE.md, or yaks, never only into `away/`. Another round adds a "Round N" section to the index and more pages beside it. If an `away/` from an earlier run is still there, ask Jess before replacing it.

## Agents

Give every agent a name, an entertaining one, never reused within the directory. Fixed roles:

- **Shepherd**: picks the yaks. Read-only in round 1; from round 2 on, it also scaffolds the round's section and pages.
- **Herald**: builds the round 1 scaffold: index, FORMAT.md, one pre-filled page per agent.
- **Tally**: closes a round: fills the index's status cells and summary, and turns the pages' Gotchas into fixes in the repo's CLAUDE.md. A round's close and the next round's scaffold can be one Tally run.
- Yak agents: one per yak or per small group of yaks that share files.

Launch every agent that writes with `isolation: "worktree"`. Its worktree branches from origin/main, so its first step is `git merge --ff-only main`.

## The flow

1. **Pick (Shepherd).** It reads the repo's CLAUDE.md and task tracker (`yx list --ready`) and picks 3 to 6 yaks agents can finish without Jess. Leave out human jobs (👩🏽‍🦱), anything that pushes, deploys, or releases, and design questions Jess hasn't decided, unless a documented guess covers it. It groups picks into waves with disjoint files, and checks `git worktree list` and wip yaks for another session's live work, so the run avoids those files. It reports: yak IDs, one-line task, files, starting guesses, wave, size. It also lists runners-up and what it rejected, with reasons.
2. **Scaffold (Herald, or Shepherd from round 2).** It builds the directory, as above. You merge it to main before launching any yak agent, because the agents read their pages from main.
3. **Run the waves.** Launch a wave's agents in parallel, each with the prompt below. When one reports merged-ready, merge it (below), then `chmod -R u+w <worktree>` (yx makes files read-only) and `git worktree remove` it. Keep the branch. Then fill its page's diff link (below). Launch the next wave when every branch it depends on is merged.
4. **Close the round (Tally).** Then push-notify Jess: one line saying what landed, the test count, and where to read.
5. **Another round** when Jess asks, or when she said to keep going.

## Merging

Each agent's work lands on main as one merge commit, so its commits stay a visible lump. This overrides Jess's usual linear-history rule: in away mode she wants merge commits.

1. In the agent's worktree, `git merge main`, which brings main in. Run the full suite there.
2. Merge the branch into main with `git -C <main> merge --no-ff <branch> -m "Merge <agent>: <one-line summary> - claude"`. Its first parent is the main before, so the merge commit's diff is exactly the agent's work.
3. Push main (`git -C <main> push`). Jess allows pushing main in away mode, and the push makes the diff link resolve. Don't push anything else, and never `yx sync`, deploy, or release.
4. Rename the branch to `away/<agent>` (`git branch -m`), and keep it until Jess deletes `away/`.

Details:

- Only you merge, and only to main. Agents never merge or push.
- No rebasing, so the agent's commit hashes stay valid, and the hashes on its page stay right.
- Main moves under you: other sessions commit there. If main moved between steps 1 and 2, repeat step 1.
- On a conflict in step 1, abort it and send the agent back (SendMessage) to merge main in its worktree, resolve, rerun the suite, and report. Don't resolve it yourself.
- Two branches can each pass and still break together: an import move plus another change can make a cycle. That's why the suite runs after main comes in.
- Leave alone any uncommitted change in the main checkout that isn't yours, and tell Jess about it.
- Pushing main publishes whatever GitHub Pages serves, `away/` included. In the index, flag what went public: any change to a published page.

## The diff link

Each agent page has a `diff` section holding a link to its changes on GitHub. Only you can write it, because the merge commit doesn't exist until you make it. After the merge:

- The URL is `https://github.com/<owner>/<repo>/compare/<merge>^1...<merge>`, with both hashes spelled out in full, and the owner and repo taken from `git remote get-url origin`.
- Replace the `<!-- coordinator: diff -->` marker in the agent's page with the link. Commit it on main, and push with the next merge.
- When you fill the index's status cell, link the same URL.

Messy history is fine. If the diff-link commits pile up, batch them: fill every merged agent's link at once, before launching the next wave.

## Usage limits

A usage limit stops every running agent at once. When it resets, SendMessage each stopped agent to continue where it stopped; don't start new ones. A worktree with no commits can be auto-deleted during the pause, so every prompt says: commit early.

## The yak agent prompt

Fill in the brackets. Keep each prompt self-contained: the agent starts cold.

> You are **[Name]**, a yak-shaving agent in the [repo] repo, part of an unattended run while Jess (she/her) is away. A coordinator merges your branch to main; you don't.
>
> First: `git merge --ff-only main`. Read CLAUDE.md, `away/FORMAT.md`, and your pre-filled page `away/[agent].html`. Keep that page updated per FORMAT.md; only you edit it, and updates ride in your own commits. The process rules in `away/index.html` bind you:
> - No push, `yx sync`, deploy, release, or Chrome.
> - Don't edit the index, or the files named below as belonging to other agents.
> - The full suite passes before you report merged-ready.
> - If you're stuck after a few real attempts, write it up, add a yak, and stop.
>
> Commit early, since work must survive a pause, and after each conceptual change, following the repo's commit rules. Run `yx reset` first, then `yx start` and `yx done` your yaks. Add yaks for what you find. Keep README edits to a line or two. Scratch files go in `/tmp/[agent]`.
>
> Your yaks: [IDs, one-line task, files, starting guesses]. Other agents in parallel: [name: files, for each]. Keep out of their files. [Any decision Jess said, e.g. "Jess said keep them for now: measure only."]
>
> When something is ambiguous, guess, and record it in the Guesses format. Final report (under 200 words): branch name, commits, test counts, guesses, and side effects outside your worktree (list yx changes).

## Rules that hold the run together

- **Jess's word beats a pick.** If a yak's history holds a decision of hers ("keep them for now"), narrow the agent's task to fit it, and say so in the notes.
- **Guesses are findable.** Every guess is a Guess / Why / If wrong block with a fixed `guess-` id. Tally links every one from the round's "Read first" list. A design decision an agent makes for Jess goes in the repo's decision record and also on the page as a guess.
- **Public pages get flagged.** Pushing main publishes, so the index lists every change to a page GitHub Pages serves, and Jess can review what went out.
- **Browser checks become human yaks.** Agents can't share one Chrome, and nobody is there to reconnect it.
- **Gotchas feed back.** Each page lists what tripped its agent. Tally adds what a future agent needs to the repo's CLAUDE.md.
- **Side effects are reported.** Every final report lists what the agent changed outside its worktree, so a revert is possible.
