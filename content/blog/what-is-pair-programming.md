---
title: What Is Pair Programming? A Guide for Solo Learners
description: What pair programming is, where it came from, the main styles, what developers like and dislike about it, and where to find someone to pair with.
date: 2026-11-24
---

Pair programming is two people working on the same code at the same time, on one shared screen. One person types, the other watches, thinks ahead and asks questions, and every so often they swap.

It started as a way for professional teams to work, but it's just as useful for two people learning to code together. This guide is a short tour: what pairing is, where it came from, how people do it, what they like and don't, and where to find someone to try it with.

## How it works

The two roles have names. The **driver** has the keyboard and focuses on the line being written right now. The **navigator** reviews each line as it appears, keeps the bigger picture in mind and spots problems early: a missed edge case, a better name, a step that's been forgotten.

Neither role is the "senior" one. The point is that two kinds of thinking happen at once, and that you swap roles regularly, every 15 to 30 minutes or at a natural break, so both people stay engaged.

## How it started

Developers have sat at one desk and worked through a problem together for as long as there have been programs to write. It got its name and its reputation in the late 1990s through Extreme Programming (XP), a way of working developed by Kent Beck on a payroll project at Chrysler. XP made pairing one of its core practices, and Beck's 1999 book *Extreme Programming Explained* took it to a much wider audience. Since then, a fair amount of research has looked at pairing in classrooms. A [study of 554 intro-programming students at UC Santa Cruz](https://cacm.acm.org/research/pair-programming-improves-student-retention-confidence-and-program-quality/), for example, found that students who paired were more confident in their work and more likely to stay in computer science.

## Types of pair programming

There are a few common styles, and most pairs mix them.

- **Driver and navigator.** The classic version described above. A good default if you've never paired before, and we cover it in more detail in [The Driver/Navigator Technique, Explained](/blog/driver-navigator-pair-programming).
- **Ping-pong.** One person writes a failing test, the other writes the code to make it pass, then they swap. It works well if you're learning test-driven development, because the rhythm is built in.
- **Strong-style.** The person with the idea isn't allowed to type it. As Llewellyn Falco, who came up with the style, puts it: for an idea to go from your head into the computer, it must go through someone else's hands. It's slower, and it's very good for learning, because you can't skip explaining.
- **Mob (or ensemble) programming.** The same idea with a whole group: one driver, everyone else navigating, rotating often.

For two learners at a similar level, plain driver and navigator with regular swaps is the easiest place to start.

## What developers like about it, and what they don't

The case for pairing is mostly about thinking out loud. In their [long guide on martinfowler.com](https://www.martinfowler.com/articles/on-pair-programming.html), Birgitta Böckeler and Nina Siessegger put it simply:

> Pair programming forces us to discuss approaches and solutions, instead of only thinking them through in our own head.

Debugging comes up often too. One developer, in replies collected by [Julia Evans](https://jvns.ca/blog/2014/08/05/pair-programming-is-amazing-except-when-its-not/), said that "pair debugging on the other hand can be excellent." When we asked on r/learnprogramming how people learned with a partner, one reply described a lot of personal success with it, mostly from having someone to talk confusing problems through with.

The case against is just as real. The same guide admits it:

> Working so closely with another person for long stretches of time is intense.

Others in Julia Evans' collection were blunter: pairing "can be very stressful and draining for an introvert," and "I type somewhat slow and I always feel pressure (real or imagined) from the other person." Differences in skill level and who gets to decide come up again and again. And in our own Reddit thread, the worst stories were about partners: someone who went silent before a deadline, or someone who let the other person do all the work.

Read together, most of the complaints are about long hours, mismatched partners or the wrong setup, not about the idea itself. Short sessions with someone at a similar level avoid a lot of them.

## How people pair today

Most pairing now happens remotely. The simplest setup is a voice call with screen sharing on Discord, Zoom or Google Meet, with the navigator watching the driver's screen. To let both people type in the same files, [VS Code Live Share](https://marketplace.visualstudio.com/items?itemName=MS-vsliveshare.vsliveshare) is free. Paid tools like Tuple are built specifically for pairing. If an older guide points you to JetBrains' Code With Me, note that JetBrains [is shutting it down](https://blog.jetbrains.com/platform/2026/03/sunsetting-code-with-me/), with the final shutdown in early 2027.

You'll also see AI coding assistants described as an "AI pair programmer." They're useful for syntax and quick explanations, and early classroom studies suggest they can help with the task itself. The same studies find that people pairing with another person [report a stronger sense of working together](https://doaj.org/article/5a7b6b4fedbb46c38a492de0ce5a8748). An assistant answers your questions. A partner also expects you to show up next week.

## Where to find someone to pair with

A short list is below. For more on choosing someone and keeping it going, see [How to Find a Coding Buddy (and Actually Keep One)](/blog/how-to-find-a-coding-buddy).

- **People you already know.** Classmates, a bootcamp cohort, a coworker who's also learning. The easiest start, if you have them.
- **Course communities.** Free courses like The Odin Project and freeCodeCamp have busy Discord servers and forums, and people there do look for study partners. Requests can get lost in fast-moving channels, so be specific about what you're working on and when you're free.
- **Reddit.** r/programmingbuddies exists for exactly this. Posts often get plenty of "count me in" replies; fewer turn into regular sessions.
- **Local meetups and coding dojos.** Great for meeting people face to face, if there's one near you.
- **Pairin.** We built [Pairin](/) for this step. You post what you want to learn, talk to the people who apply, and only commit once it feels like a good fit. Then the two of you get a private space to keep going, with a short check-in each week.

## Where to go from here

Pair programming is a simple idea: two people, one problem, swapping roles. The hard part is rarely the technique. It's finding someone at a similar level with a schedule that overlaps yours. So don't plan a big commitment yet. Find one person, book an hour this week, pick something small to build, and see how it feels. You'll know after one or two sessions whether it's for you.
