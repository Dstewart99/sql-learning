# SQL Learning

Hands-on SQL practice for Identity and Access Management (IAM) work.

I work in IAM Operations, where a lot of the work in Saviynt runs on SQL.
This repo tracks my practice on a Saviynt-style identity dataset, written
the way I'd query real user and access data on the job.

## Setup
- **Database:** SQLite (`iam_practice.db`)
- **Dataset:** `saviynt_practice_dataset.sql` (a mock `users` table with
  departments, employee types, managers, start dates, and term dates)
- **Tools:** VS Code + SQLTools

## Progress

| Week | Session | Topics |
|------|---------|--------|
| 1 | [Day 1](week1/day1.sql) | SELECT, FROM, WHERE, IS NULL / IS NOT NULL |

## Why IAM-focused?
Questions like "who is still active?", "who are our contractors?", and
"who in this department still has access?" come up constantly in identity
work. Every query here is practice for answering those questions quickly
and accurately.
