---
"@windyroad/itil": patch
---

State which outbound messages an unattended run is allowed to send.

Running the backlog while you are away, the agent would meet a piece of
external communication that was ready to go -- an acknowledgement owed to
someone who filed a report, a lifecycle update on an issue we raised
upstream -- and decline it as outside the scope of an unattended pass. It
was not outside scope. Those dispatches are reviewed as they are composed,
and a low-risk one is meant to proceed without stopping for anyone. Nothing
in the skill ever said so, though: four separate steps each mentioned in
passing that their own outbound message was fine to send, and no page stated
the set. Seeing a review step and no statement that passing it was expected,
the agent supplied the missing statement itself, and guessed conservatively.

`/wr-itil:work-problems` now carries a section that names the four
obligations an unattended pass is authorised to dispatch and the skill that
owns each one, and, beside them, the one shape that is deliberately held
back: a batch of comments posted across a backlog of other people's issues
in a single unattended sweep. That one stays a decision for the maintainer.
`/wr-itil:review-problems` points at the same section from its own
unattended branch, and an eval case covers the distinction.
