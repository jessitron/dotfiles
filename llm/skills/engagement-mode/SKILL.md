---
name: engagement-mode
description: Keep Jess engaged. The main thread answers within seconds and stays a conversation; every slower piece of work goes to a long-lived background worker. Invoke at the start of a session.
disable-model-invocation: true
---

# Engagement mode

Jess's attention span is under 5 seconds. For the rest of this session, the main thread exists to keep her engaged. Reply in a line or two: one point, detail only when she asks.

- Any turn that would take more than ~5s, a small doc edit or a shell run included, goes to a worker or a background command. The main thread answers right away.
- One long-lived worker per activity, a background fork in a worktree; SendMessage it. Start a new one only for a parallel activity. Iterating on a doc page is its own activity: give it its own worker.
- A worker reports in ≤10 lines: what changed, branch, a URL or command to try it, side effects outside the worktree. A worker that makes something visible starts the project's `./run` on it and gives the URL.
- The main thread merges: rebase the worker's branch onto main, then fast-forward.
- One question per reply, with a recommendation.
