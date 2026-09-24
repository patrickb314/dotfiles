---
name: write-like-bridges
description: Write or revise technical research papers in Patrick Bridges' voice — the HPC/systems paper style from his published work (MPI, GPU communication, operating systems, fault tolerance, performance measurement). Use this skill whenever drafting, revising, or reviewing any part of a research paper, workshop paper, preprint, abstract, or technical report for Patrick or his group: abstracts, introductions, contribution lists, design sections, evaluation write-ups, related work, limitations, conclusions, rebuttals, and grant-report prose. Trigger it even when the request sounds routine — "tighten this intro", "write the related work", "turn these results into a paragraph", "draft an abstract for this", "does this sound like me?" — and trigger it for papers where he is a co-author or advisor, since the group's papers carry the same voice.
---

# Writing in Patrick Bridges' technical paper voice

This skill encodes the prose habits found across Bridges' published systems
papers, drawn from full texts spanning 2011 to 2026 — the CPU-free MPI GPU
communication paper (CLUSTER 2026), the GPU triggering survey (2024), the
Beatnik mini-application paper (2024), Mondragón's performance interference
paper and Levy's memory compression paper (both SC 2016), the selective
reliability paper (2012), and the DRAM fault recovery and MISD papers (2011).
The style is stable across that span, which means the patterns below are
reliable, not incidental.

**The voice is the group's, not just the first author's.** Bridges writes and
edits heavily on his students' and collaborators' full conference papers, so
SC, CCGrid, Cluster, and IPDPS papers with Mondragón, Levy, Dosanjh, Marts,
Stewart, or Schafer as first author carry this voice as faithfully as his own
first-author work. Apply this skill to any paper from the group.

The voice is that of a systems researcher who assumes the reader is a peer:
plain, declarative, dense with mechanism, quantified wherever a number exists,
and scrupulously honest about what the work does not do. It never sells.

## The core stance

Before reaching for any template, internalize the stance, because the templates
follow from it:

**Say the mechanism.** A claim without a mechanism is not worth writing. When
explaining why something is faster, name the operation that was removed. When
comparing to prior work, name the specific call or protocol step that differs.
"Our approach is more efficient" is not a sentence in this voice; "this
eliminates the extra network round trip used by the prior approach" is.

**Quantify or don't claim.** Every performance statement carries a number, and
the number carries its uncertainty. Ranges rather than single figures
("12–39% lower latency for message sizes between 32 bytes and 512KB"), and
explicit statistical grounding where it exists ("Headline performance claims are
supported by non-overlapping 95% confidence intervals on the per-trial
averages").

**Volunteer the bad news.** Where the approach loses, say so in the same
sentence register as where it wins, in the results *and again in the
conclusion*. This is the most consistent habit in the entire corpus. The SC16
compression paper's conclusion reports 45%, 44%, and 24% improvements and then,
in the next sentence, "However, LAMMPS-lj, LAMMPS-eam, and SAMRAI require a
substantial increase in memory." Hiding a weakness costs more credibility than
the weakness costs.

**Credit prior work as load-bearing.** Differentiating from prior work does not
mean diminishing it. When someone else's method is what makes yours possible,
say so plainly: "the method described in this paper for conducting such
estimations relies heavily on EMMA for extrapolation, and would not be possible
without it."

**Scope the claim before making it.** When introducing a term the paper will
lean on, define it, then immediately state what it excludes. This preempts the
reviewer's objection instead of waiting for it.

**No selling.** No "novel paradigm," no "revolutionary," no "seamlessly," no
rhetorical questions, no em-dash drama, no "not just X, but Y." If a phrase
would survive a find-and-replace into a different paper on a different topic,
it is filler — cut it or make it specific.

**No rhetorical compression.** This is the failure mode most likely to creep in,
because it reads as good writing in other registers. Do not set up a short,
punchy declarative clause and then deliver the content after a colon. These are
all wrong:

> The flush is what hurts: the application still pays PFS commit bandwidth.
> That cost is dominated by one term: the bandwidth required to commit a
> checkpoint to the parallel filesystem.
> The mechanism-level difference is who moves the data: their simulated model
> assumed the host CPU drives the copy.

In this voice a colon introduces an enumeration ("for two reasons: (1) … and
(2) …"), a list ("our recovery model comprises the following steps:"), or a
definitional expansion — never a dramatic reveal. Rewrite each of the above as
one ordinary declarative sentence that carries its own mechanism, even though
the result is longer:

> Because node-local capacity is small, the application still pays parallel
> filesystem commit bandwidth, only on a slightly longer period.

The rewrites here and in `references/sentence-craft.md` illustrate the move, not
wording to reuse. Lifting one verbatim into a draft usually repeats a clause the
surrounding paragraph already established; write the plain sentence that fits
the paragraph you actually have.

The same objection covers neighboring moves: sentences that announce a count
("Three extensions follow directly."), mid-paragraph aphorisms ("Capacity, not
bandwidth, is the binding constraint."), and any sentence whose appeal is that
it is pithy. Plainness is the target, not compression.

This is distinct from the run-in headers described below. A bolded or
italicized header followed by a colon and ordinary prose is a structural label
and belongs in this voice. A colon inside running prose, setting up a payoff,
does not.

## Signature moves

These five appear so consistently that their absence makes a draft sound like
someone else wrote it.

### 1. The "Unfortunately" pivot

Establish what the field does, then pivot to the gap with `Unfortunately,` or
`However,`. This is the load-bearing transition of every introduction and most
background subsections.

> Proposed exascale systems will present extreme fault tolerance challenges to
> applications and system software. In particular, these systems are expected to
> suffer soft or hard errors at least several times a day. [...]
> **Unfortunately,** fault-tolerance methods currently in use by large-scale
> applications, such as roll-back recovery from a checkpoint, may be unsuitable
> to address the challenges of exascale computing.

> A number of important system services need *strong scaling* [...]
> **Unfortunately,** modern multiple-instruction/multiple-data (MIMD) approaches
> to multi-core OS design cannot exploit the fine-grained parallelism needed to
> provide such scaling.

Use it once in the abstract, once or twice in the introduction, and freely in
background and related work. It is honest signposting, not a tic — it tells the
reader exactly where the paper's opening is.

### 2. Contributions as noun phrases, introduced by "Specifically"

The introduction always ends with an explicit contribution list, introduced by a
sentence containing *specifically*, and each bullet is a **noun phrase**, not a
sentence and not a verb-first imperative. Each bullet ends with a section
cross-reference when the paper has room for one.

> Specifically, this paper describes in detail the following research
> contributions:
>
> - The design of new GPU communication abstractions for MPI that support
>   stream-triggered communication and preserve important MPI two-sided
>   communication semantics, while enabling implementations to move operations
>   that generally require CPU involvement off the communication critical path.
> - The demonstration of the usage of this API to create halo exchange
>   primitives used by both benchmarks and production applications written for
>   the Cabana performance portability framework.
> - A CPU-free implementation of this API for HPE Slingshot 11 systems that
>   leverages the deferred work queue (DWQ) and counter features of the libfabric
>   API. The key technical insight underlying this implementation is that
>   FI_REMOTE_WRITE triggering counters can be used to handle both receiver
>   readiness and receiver completion, eliminating unnecessary network round
>   trips required by previous CPU-free approaches.
> - Identification, re-attribution, and analysis via an ablation study of the
>   performance gap between stream-triggered communication and Cray MPICH on
>   irregular small-message exchanges, including potential optimizations to close
>   the gap.

Note the opener nouns: *The design of*, *The demonstration of*, *A CPU-free
implementation of*, *A comparison of*, *The identification of*, *A detailed
analysis of*, *A validation of*, *A study that examines*, *Identification,
re-attribution, and analysis of*. Note also that bullets are uneven in length —
the one carrying the key insight is allowed to run long and to contain a second
sentence beginning "The key technical insight underlying this implementation
is...". Do not pad the short ones to match.

The SC16 interference paper shows the same list with `§` cross-references and a
lead-in that first says where the background lives:

> After providing essential background information on performance interference
> in HPC applications and a brief introduction to key concepts from extreme
> value theory in Section II, we describe in detail the following contributions:
>
> - A stochastic model that can be used to characterize and extrapolate the
>   performance of HPC applications in the presence of representative sources of
>   interference in next-generation HPC systems […] (§III);
> - A validation of this model using a set of synthetic benchmarks with BSP
>   computing periods whose lengths follow different probability distributions
>   (§IV);
> - A simple and efficient method of characterizing different sources of
>   interference and their impact on applications (§V);

**Survey and position papers use a verb-first variant** in which each bullet
completes the stem "this paper …":

> this paper makes the following contributions:
>
> - Presents a taxonomy for approaches to GPU-triggered communication that
>   highlights the major design decisions that an MPI API needs to address
>   (Section 3);
> - Summarizes the key features of and classifies nine different MPI stream- and
>   kernel-triggering API proposals using this taxonomy […] (Section 4);
> - Highlights key gaps in the existing GPU triggering MPI APIs and in the MPI
>   standard […] (Section 5).

Use noun phrases for papers that build a system and verb-first for papers that
survey, classify, or argue a position.

### 3. Scoped definitions

Italicize a term at first definition, state precisely what it means, then state
what remains outside the definition. The second half is the part most writers
skip and Bridges never does.

> By *CPU-free*, we mean specifically that after enqueueing communication
> operations to a GPU stream, no CPU work is required to initiate or wait for
> the completion of a communication operation: all data movement, completion
> notification, and synchronization between sender, receiver, and NIC are
> handled by the GPU stream and the NIC. **CPU work remains during request setup**
> (matching, RMA-key exchange, NIC work queue entry construction), as is typical
> for persistent MPI operations.

> the interface provides the application with separate calls for allocating
> *failable memory* – memory in which failures will cause notifications to be
> sent to the application.

### 4. Inline numbered enumeration

Enumerate reasons, requirements, and steps inside the sentence with `(1)`,
`(2)`, `(3)`. This is the dominant way complex conditions get expressed, far
more often than a bulleted list. It keeps the reasoning in one grammatical unit
so the reader sees how the parts relate.

> Our approach uses persistent point-to-point and collective operations whenever
> possible for two reasons: (1) they cover almost all of the commonly used MPI
> semantics, reducing the number of new abstractions or optimizations that need
> to be added to MPI, and (2) they explicitly separate setup operations involved
> in creating a request from the use of that request on the communication fast
> path.

> However, we determined that such calls were (1) unnecessary if we carefully
> leverage MPI persistent operations and OFI deferred work queue/triggered
> operation semantics, and (2) were undesirable if the application could
> separately guarantee and indicate buffer readiness.

Reserve real bullet lists for contributions, taxonomies, and enumerated recovery
or algorithm steps.

### 5. Run-in headers for taxonomies and design decisions

When enumerating categories of prior work, design decisions, or software
modules, use a bolded or italicized run-in phrase followed by a colon and then
ordinary prose. Each entry names the thing, describes the mechanism, and cites
the canonical example.

> **CPU-free one-sided communication:** In this approach, GPU code, whether
> stream or kernel triggered, uses a restricted communication interface that
> eliminates the complex synchronization logic used to match messages [...]
> NVIDIA's NVSHMEM library is the canonical example of this approach and HPE has
> also published a paper describing a CPU-free MPI one-sided interface.

Design decisions get imperative-phrase headers: *Reuse existing MPI persistent
operations:*, *Provide a GPU-aware MPI progress engine abstraction:*, *Add
MPI_Match operations for persistent requests:*, *Retain required MPI buffer
readiness guarantees:*. Related-work sections use topical headers instead:
**Interference impact characterization.**, **Extreme Value Theory.**

### 6. Define the success criterion before measuring against it

When the paper asks whether an approach is worth doing — the recurring
*viability* and *feasibility* framing — state what would make it worth doing
before presenting any measurement. This turns a judgment call into a test the
reader can check.

> **II. EVALUATING THE VIABILITY OF MEMORY COMPRESSION**
>
> In this section, we examine the conditions that must exist for memory
> compression to be viable. **Memory compression is viable if its benefits
> outweigh its costs.** In this context, the benefit of memory compression is a
> reduction of the application's total execution time. [...] The principal costs
> of memory compression can be divided between storage overhead and runtime
> overhead. In the remainder of this section, we analytically model the costs
> and benefits of memory compression to determine when it is likely to be
> viable.

## Section-by-section craft

`references/section-patterns.md` gives the full template and verbatim exemplars
for each section: abstract, introduction, background, design, implementation,
evaluation, related work, limitations/future work, and conclusion. **Read it
before drafting any section of a paper.** The abstract and related-work
templates in particular are formulaic enough that following them is most of the
work.

The short version:

| Section | Shape |
| --- | --- |
| Abstract | Stakes → `However,` gap → "In this paper we describe the design, implementation, and evaluation of…" → what we demonstrate → the key mechanism → quantified results including a weaker one |
| Introduction | Context with citations → the gap → one-sentence thesis + scoped definition → "Specifically, this paper describes the following contributions:" |
| Background | "The remainder of this section provides background on X, Y, and Z." then run-in-header subsections, each ending with why it matters to this paper |
| Design | Numbered design decisions with imperative run-in headers, each giving the reason before the mechanism |
| Evaluation | Setup described so it could be rerun (exact iteration counts, problem sizes, software versions, why each was chosen) → results per benchmark → losses reported as plainly as wins |
| Related work | Grouped by approach; for each closest work, "Unlike them, our…" plus the mechanism-level difference |
| Limitations | Its own section, titled *Limitations and Directions for Future Work*; each future item names the limitation it addresses |
| Conclusion | Restate contributions concretely with numbers; no new framing, no flourish |

## Diction

`references/sentence-craft.md` has the working vocabulary, the transition
inventory, the hedging register, and a list of words to avoid. Consult it when
revising line by line or when a draft feels close but off.

The characteristic verbs: *leverage, exercise, expose, characterize, quantify,
assess, examine, demonstrate, identify, eliminate, preserve, augment, restrict*.
The characteristic framings: *viability, feasibility, tradeoff, overhead, fast
path, critical path, semantics, expressiveness*.

Write in first person plural (*we*), active voice, present tense for design and
past tense for experiments. Sentences run long and carry embedded enumerations,
but they stay grammatically plain — the complexity is in the content, never in
the syntax.

## Paper and section titles

Two patterns, both used heavily:

**Gerund-led analytical titles** — the paper's verb is the paper's claim:
*Evaluating the Viability of Process Replication Reliability for Exascale
Systems*; *Characterizing Application Sensitivity to OS Interference Using
Kernel-Level Noise Injection*; *Understanding GPU Triggering APIs for MPI+X
Communication*; *Measuring Thread Timing to Assess the Feasibility of Early-bird
Message Delivery*; *Quantifying and Modeling Irregular MPI Communication*.

**Name-colon-expansion** for artifacts: *Beatnik: A Novel Global Communication
Mini-Application*; *Cholla: A Framework for Composing and Coordinating
Adaptations in Networked Systems*; *MiniMod: A Modular Miniapplication
Benchmarking Framework for HPC*.

Titles state what was done, not what was achieved. *Evaluating the Viability of…*
is preferred over *Efficient, Scalable…* — the second promises, the first
reports.

## Revising someone else's draft into this voice

Student and collaborator drafts usually need the same six passes, in order:

1. **Find the missing "Unfortunately."** If the introduction states context and
   then jumps to the contribution, the gap is unstated. Insert the pivot.
2. **Convert contribution bullets to noun phrases** and add section
   cross-references.
3. **Add the mechanism** to every comparative claim. Search for *better*,
   *faster*, *more efficient*, *improved* and require each to name what changed.
4. **Add numbers and their uncertainty** to every performance claim; delete
   claims for which no measurement exists.
5. **Find the hidden loss.** If the evaluation reports only wins, either the
   experiment was too narrow or a result was omitted. Report it, and carry it
   into the conclusion.
6. **Check that novelty claims are bounded.** "The first" becomes "the first of
   which we are aware"; "all proposals" becomes "all nine proposals known to the
   authors."
7. **Hunt the rhetorical colons.** Search running prose for `: ` and check each
   one. If it follows a short punchy clause rather than introducing a list,
   enumeration, or definition, rewrite the sentence plainly. Do the same for
   count-announcing sentences and mid-paragraph aphorisms.
8. **Keep the concrete names.** Benchmarks, matrices, applications, and machines
   are named, never generalized away — *audikw_1*, *Serena*, *CTH-st*, *LULESH*,
   *Frontier*, *Tuolumne*. If a draft says "an adaptive-mesh hydrodynamics code"
   where the code has a name, put the name back.
9. **Cut the selling.** Delete *seamlessly*, *cutting-edge*, *paradigm*,
   *significantly* used without a number, and any sentence that would fit in
   another paper unchanged.

## Interaction with the global writing guide

Patrick's global instructions apply Strunk & White and forbid AI tics. Those
instructions and this voice agree almost everywhere — omit needless words,
active voice, nouns and verbs over adjectives, no stock openers or closers, no
false balance, no empty transitions.

Two places need care. First, this voice uses longer sentences than a strict
"omit needless words" reading would suggest; the length comes from packing in
mechanism and enumerations, not from padding, and that is correct here. Second,
`Unfortunately,` and `In contrast,` are real transitions doing real work in this
voice, not the empty connective tissue the global guide warns against — keep
them. Everything else in the global guide applies unchanged, including the
Oxford comma and US spelling.

## Reference files

- `references/section-patterns.md` — per-section templates with verbatim
  exemplars from the published papers. Read before drafting a section.
- `references/sentence-craft.md` — diction, transitions, hedging, quantification
  conventions, and a banned-phrase list. Read when revising line by line.
