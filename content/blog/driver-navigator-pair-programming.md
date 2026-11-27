---
title: The Driver/Navigator Technique, Explained
description: How driver and navigator pair programming works, what each role does, how to run a session, and the common mistakes, including when you're pairing remotely.
date: 2026-12-03
---

Driver and navigator is the classic way to pair program, and it sounds almost too simple: one person types, the other watches, and every so often you swap. That simplicity is also how it goes wrong. Without a bit of structure, one person ends up doing all the work while the other nods along and quietly checks their phone.

This guide covers what each role is actually for, how a session runs, and the habits that keep both people thinking. If you're new to pairing in general, start with our [guide to pair programming](/blog/what-is-pair-programming).

## The two roles

The **driver** has the keyboard. Their job is the small step in front of them: writing this function, making this test pass, fixing this line. They don't need to hold the whole design in their head while they type.

The **navigator** doesn't type. They read each line as it appears, think about where the code is heading, and spot problems early: a missed edge case, a confusing name, a step that's been forgotten.

In their [guide on martinfowler.com](https://www.martinfowler.com/articles/on-pair-programming.html), Birgitta Böckeler and Nina Siessegger describe the driver's thinking as tactical and the navigator's as strategic. The point of splitting the work, as they put it, is "to have two different perspectives on the code." Neither role is the senior one. The value comes from both kinds of thinking happening at once.

## A session, step by step

1. **Pick a small task.** Something you can finish in a session or two: one feature, one bug, one exercise from your course.
2. **Agree on one tiny goal.** Not "build the login page" but "the form shows an error when the email is empty." Writing it down helps, as a test, a commit message or a note.
3. **Drive toward it.** The driver writes the code. The navigator keeps an eye on the goal and writes down anything that can wait: a refactor, a question, an idea for later.
4. **Swap.** Change roles when the tiny goal is done, or after a fixed stretch of time. The guide suggests the Pomodoro technique: 25 minutes of work, then a short break. Either way, swap regularly, so both people spend real time at the keyboard.
5. **Take a real break.** Pairing is tiring, because you're both concentrating the whole time. A five-minute break away from the screen does more than you'd expect.

Then pick the next tiny goal, and go again.

## How to navigate well

Navigating is often the harder role to do well, because it's easy to slide into either backseat driving or switching off.

**Wait before you point out a mistake.** The guide suggests waiting "at least 5 seconds" before saying something. The driver has often seen the typo already, and it's frustrating to be corrected mid-thought.

**Ask before you fix.** One tip from a developer in our r/learnprogramming thread: "Have the navigator ask the driver to explain the next step before offering a fix." It keeps the session on the driver's reasoning, and it often shows you the problem was a misunderstanding rather than a typo.

**Say what, not which keys.** "Let's pull that into its own function" leaves the driver room to think. "Type d-e-f, space, now the name" doesn't, and it turns the driver into a pair of hands.

**Write ideas down instead of interrupting.** A short list of "later" items lets you stay on the tiny goal without losing the thought.

## How to drive well

**Think out loud.** The navigator can only help with what they can follow. "I'm going to loop over the items and skip the empty ones" gives them something to check.

**Say when you disagree.** You're at the keyboard, but you're not just taking dictation. If a suggestion doesn't make sense to you, say so. That conversation is often where the learning happens.

**Don't race ahead.** If you're typing faster than you're explaining, the navigator falls behind and stops being useful.

**Let go of the keyboard.** When it's time to swap, swap, even in the middle of something you're sure you could finish in a minute.

## Pairing remotely

Pairing over a call works the same way. There are two common setups:

- **Screen sharing.** The driver shares their screen on Discord, Zoom or Google Meet, and the navigator watches. It's the easiest to start with. To swap, the other person shares their screen instead, which means the code needs to be on their machine too.
- **A shared editor.** Tools like [VS Code Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare) let both people work in the same files, each in their own editor. Swapping is just agreeing who types.

If you swap machines often, a small open-source tool like [mob.sh](https://mob.sh/) can hand the code over through git, so nobody has to commit and pull by hand.

## When you're at different levels

If one of you is further along, the usual advice is to let the less experienced person drive more. Böckeler and Siessegger put it directly: "if you are the more experienced coder in a pair, make sure to be in the navigator's seat most of the time." Typing the code yourself, with someone explaining as you go, teaches more than watching someone else type it.

This is close to strong-style pairing, where the person with the idea isn't allowed to type it (see the styles in our [pair programming guide](/blog/what-is-pair-programming)). The guide also points out that explaining something is a good test of whether you really understand it, so the more experienced person learns too.

## The short version

The roles are simple: one person types and handles the step in front of them, the other watches the bigger picture. What makes it work is everything around them: a tiny goal you both agree on, a navigator who asks before fixing, a driver who thinks out loud, and swapping often enough that nobody drifts off.

The hardest part is often having someone to try it with. If you don't have a partner yet, our guide on [how to find a coding buddy](/blog/how-to-find-a-coding-buddy) covers where to look, and [Pairin](/) is built for that step: you post what you want to learn, talk to the people who apply, and commit only when it feels like a good fit.
