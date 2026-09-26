---
name: write-like-bridges
description: Write or revise technical research papers in Patrick Bridges' voice — the HPC/systems paper style from his published work (MPI, GPU communication, operating systems, fault tolerance, performance measurement). Use this skill whenever drafting, revising, or reviewing any part of a research paper, workshop paper, preprint, abstract, or technical report for Patrick or his group: abstracts, introductions, contribution lists, design sections, evaluation write-ups, related work, limitations, conclusions, rebuttals, and grant-report prose. Trigger it even when the request sounds routine — "tighten this intro", "write the related work", "turn these results into a paragraph", "draft an abstract for this", "does this sound like me?" — and trigger it for papers where he is a co-author or advisor, since the group's papers carry the same voice.
---

# Writing in Patrick Bridges' technical paper voice

This skill encodes the prose habits found across Bridges' published systems
papers, drawn from full texts spanning 2011 to 2026. The core corpus is the
CPU-free MPI GPU communication paper (CLUSTER 2026), the GPU triggering survey
(2024), the Beatnik mini-application paper (2024), Mondragón's performance
interference paper and Levy's memory compression paper (both SC 2016), the
selective reliability paper (2012), and the DRAM fault recovery and MISD papers
(2011). A second pass added eight more group papers from 2020 to 2025: Vernier
communication monitoring (SC Workshops 2025), the early-bird message delivery
journal paper (Concurrency and Computation 2025), heterogeneous cluster scaling
laws (2025), CMB (CCGrid 2024), complete provenance with containers (2022),
MiniMod (Cluster 2021), SAMPRA (2021), and lightweight measurement of HPC
performance variability (2020). The style is stable across that span, which
means the patterns below are reliable, not incidental; where the later papers
disagree with the earlier ones, the note below says so.

**The voice is the group's, not just the first author's.** Bridges writes and
edits heavily on his students' and collaborators' full conference papers, so
SC, CCGrid, Cluster, EuroMPI, and IPDPS papers with Mondragón, Levy, Dosanjh,
Marts, Stewart, Dominguez-Trujillo, Wofford, or Schafer as first author carry
this voice as faithfully as his own first-author work. Apply this skill to any
paper from the group.

**The inline `(1)`/`(2)` enumeration and the scoped definition are both stronger
in Bridges' own first-author papers than in the student-led ones.** When he
holds the first or last author slot on a recent paper, weight those two moves
up. Everything else in this file holds across the whole group.

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

These appear so consistently that their absence makes a draft sound like
someone else wrote it.

### 1. The gap pivot

Establish what the field does, then pivot to the gap. The pivot is `However,`
by default and `Unfortunately,` when the gap is genuinely unfortunate rather
than merely unaddressed. Across the expanded corpus `However,` outnumbers
`Unfortunately,` roughly nine to one, so a draft that reaches for
`Unfortunately,` more than once or twice per paper has overcorrected into a tic.
Reserve it for the sentence where the field's best available answer is known to
be inadequate.

`However,` doing the ordinary work of the pivot, from the CMB abstract and the
early-bird introduction:

> Allowing data to be sent when it is ready increases opportunities for
> overlapping communication and computation. **However,** with multiple
> fine-grained, thread-safe interfaces, the task of optimizing an application's
> peer-to-peer fine-grained communication is complex.

> Existing work has assumed that thread arrival times […] follow a normal
> distribution or that there are regularly laggard threads […]. **However,**
> previous work has not used empirical data to characterize thread arrival
> distributions.

The gap can also be stated without any pivot word at all, as a plain limitation
sentence. MiniMod opens its gap with `Currently,`:

> **Currently,** this requires the creation of a new version of the proxy
> application for each combination of the approach being tested.

`Unfortunately,` is not always sentence-initial. It appears after a semicolon
and bracketed by commas mid-sentence, and both placements are lighter than the
sentence-initial form:

> […] the performance of benchmarks [50] or simplified proxy applications;
> **unfortunately,** benchmarks and proxy applications often simplify or elide
> key communication characteristics of applications.

> The decentralized and emergent effects of such variation are,
> **unfortunately,** also difficult to systematically measure, analyze, and
> predict […]

Sentence-initial `Unfortunately,` carries the most weight and is worth spending
on the paper's central gap:

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

Spend `Unfortunately,` on the abstract's gap sentence or the introduction's,
and use `However,` everywhere else, including the background and related-work
caveats where the pivot is doing routine work. Both are honest signposting that
tells the reader where the paper's opening is, and both stop working once they
repeat often enough to read as a verbal habit.

### 2. Contributions as noun phrases

The introduction always ends with an explicit contribution list, and the default
bullet is a **noun phrase** — not a sentence, not a verb-first imperative. Each
bullet ends with a section cross-reference when the paper has room for one.

The lead-in sentence is formulaic but not fixed. The whole inventory from the
corpus, in rough order of frequency:

> This paper makes the following contributions:
> In summary, this paper makes the following contributions:
> The contributions of this paper are:
> This paper's contributions are:
> Overall, this paper describes the following contributions toward achieving this goal:
> Specifically, this paper describes in detail the following research contributions:
> After providing essential background […] in Section II, we describe in detail the following contributions:
> we make the following contributions:

Pick one and move on. `Specifically,` is a real option but it is not the house
style it was once thought to be; `This paper makes the following contributions:`
is the plainest and most common. The `Overall,` variant is worth knowing because
it follows a stated goal sentence, which is itself a good move when the paper
has one:

> Our overall goal is to enable system and application architects to accurately
> assess and predict performance variation in large-scale systems. **Overall,
> this paper describes the following contributions toward achieving this goal:**

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

Two verb-first variants also occur, and they are not restricted to survey
papers. The first completes the stem "this paper …", used in the GPU triggering
survey:

> this paper makes the following contributions:
>
> - Presents a taxonomy for approaches to GPU-triggered communication that
>   highlights the major design decisions that an MPI API needs to address
>   (Section 3);
> - Summarizes the key features of and classifies nine different MPI stream- and
>   kernel-triggering API proposals using this taxonomy […] (Section 4);
> - Highlights key gaps in the existing GPU triggering MPI APIs and in the MPI
>   standard […] (Section 5).

The second opens each bullet with *We*, and it appears in tool-building papers —
Vernier (2025) and MiniMod (2021) both use it:

> In summary, this paper makes the following contributions:
>
> - **We identify** specific motivating system optimization challenges
>   encountered in optimizing communication in production HPC systems and
>   applications and why current tools have thus far proved inadequate to
>   address these issues (cf, Section 2);
> - **We propose** a new scalable tool, Vernier, that can collect a wide range
>   of statistical information on the irregular and dynamic communication
>   patterns of large, parallel, scientific codes designed to meet these
>   challenges and that can be integrated with existing simulation tools [53]
>   and benchmarks [60] (cf, Section 3); and,
> - **We evaluate** this approach on several full-scale applications; namely,
>   xRAGE [25], Parthenon-VIBE [26], and AMG2023 [41], demonstrating Vernier's
>   ability to capture detailed information about communications at scale that
>   accurately characterizes application communication (cf, Sections 4 and 5).

Default to noun phrases. Reach for a verb-first form when the contributions are
a sequence of things the authors did rather than a set of artifacts they built,
and then keep one form for the whole list — the corpus never mixes them.

Whichever form the bullets take, keep the cross-references. The corpus uses
`(Section 3)`, `(Section IV)`, `(§III)`, and `(cf, Section 2)`; spelled-out
`Section N` is the common case and `§` is rare in the recent papers.

### 3. The roadmap paragraph

The introduction closes with a paragraph that walks the reader through the
remaining sections. It opens with a fixed sentence and then assigns one clause
per section, and it is close to mandatory in the group's IEEE- and ACM-format
papers.

Two grammatical forms are used. The first makes *we* the subject of each clause
and puts the section reference at the end (MiniMod, CMB):

> **The remainder of this paper is structured as follows.** We provide a
> background for our paper in Section II. We detail the design of the CMB in
> Section III. We describe how we conducted our experiments and present the
> results of our experiments in Section IV. We discuss the implications of the
> case study in Section V. **Finally, we distinguish our work from existing
> related work in Section VI and present our conclusions in Section VII.**

The second makes the section the subject (early-bird journal paper):

> **The rest of this paper is structured as follows.** Section 2 explains the
> background and the problem the paper addresses. Section 3 discusses the
> instrumentation and experimental set-up for this paper. Section 4 presents the
> results of our experiments. Section 5 discusses the implications of this work
> and presents our plan for future extensions. Section 6 contextualizes our work
> in the body of related work. Section 7 concludes our paper.

Note that both close the same way, folding related work and the conclusion into
one final clause introduced by `Finally,` or simply listed last. Related work
and conclusions never get a sentence of their own here.

Where the contribution bullets already carry section cross-references, the
roadmap shrinks to a single sentence covering only what the bullets missed
(Vernier):

> **In addition,** we compare this approach with other systems for monitoring
> communication in HPC applications (cf, Section 6), and present directions for
> future work and conclude (cf, Section 7).

Do not write a roadmap that restates the contributions. Its only job is to map
section numbers to content for a reader who will skip around.

### 4. Scoped definitions

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

### 5. Inline numbered enumeration

Enumerate reasons, requirements, and steps inside the sentence with `(1)`,
`(2)`, `(3)`, in preference to breaking them out as a bulleted list. It keeps
the reasoning in one grammatical unit so the reader sees how the parts relate.
This is the strongest marker of Bridges' own first-author prose — it is
everywhere in the CPU-free and GPU-triggering papers and much thinner in the
student-led ones — so weight it up when he holds the first or last author slot.

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

A lettered variant, `a)` and `b)`, does the same job when the items are parallel
capabilities rather than reasons. From the SAMPRA abstract:

> To properly address and accelerate research projects with these needs, SAMPRA
> **a)** integrates privacy-preserving storage and data transfer systems with
> data-centric virtual environments, and **b)** supports effective researcher
> use of the system through active collaboration between local IT personnel,
> campus enterprise IT service providers, and campus data librarians by defining
> clear roles with associated personnel.

Reserve real bullet lists for contributions, taxonomies, and enumerated recovery
or algorithm steps.

### 6. Run-in headers for taxonomies and design decisions

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

### 7. Define the success criterion before measuring against it

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

### 8. Turn results into named, scoped heuristics

When the evaluation produced advice rather than a single verdict, the paper adds
a Discussion section between the results and related work that converts the
measurements into a short list of findings. Each finding is named, argued from a
specific figure or number, and bounded by the condition under which it holds.
The lead-in sentence says what kind of list follows.

CMB numbers them and gives each a run-in header:

> The results reported by the CMB and described above **suggest several broad
> conclusions and heuristics regarding the use of fine-grained communication:**
>
> **1) Necessity of Empirical Analysis:** Our evaluation demonstrates that the
> same application profile […] can exhibit different behaviors depending on the
> system used. For example, some techniques that prove consistently beneficial
> on Manzano result in slowdowns on Mutrino. […]
>
> **3) Safe Configurations:** […] For Manzano it was consistently beneficial to
> aggregate and send two messages, with speedups as high as 12.79%. On Mutrino,
> the same configurations generally had slowdowns of less than 1%. […] Existing
> modeling work predicts that our Mutrino results are atypical [18], [19], **but
> it does limit our recommendation for applications sending buffers of this
> size.**

The performance-variability paper uses plain bullets, each one a conditional
claim naming the method and the workload class it survives:

> The performance of our parametric and non-parametric methods on these six
> workloads performed on two different systems **leads us to conclude the
> following:**
>
> - The performance variation of trivial and controlled workloads, such as FTQ
>   and FWQ, can be accurately modeled and predicted by parametric and
>   non-parametric methods.
> - Parametric methods that rely on GEV estimation and either node or rank level
>   granularity of data rather than iteration maxima granularity of data
>   overestimate performance variation on workloads with internal communication
>   and synchronization overhead. **However, their median estimates remain
>   accurate.**
> - Parametric methods can still be useful […] **if and only if** the network
>   behaves predictably and with minimal fluctuations.

Every item names which technique fails and where, rather than only which one
wins, and every item carries the qualifying clause that keeps it from
overreaching — `but it does limit our recommendation`, `However, their
median estimates remain accurate`, `if and only if`. A heuristics list without
those clauses reads as marketing.

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
| Abstract | Stakes → `However,` gap → "In this paper we present/describe…" → what we demonstrate → the key mechanism → quantified results including a weaker one |
| Introduction | Context with citations → the gap → one-sentence thesis + scoped definition → "This paper makes the following contributions:" → roadmap paragraph |
| Background | "The remainder of this section provides background on X, Y, and Z." then run-in-header subsections, each ending with why it matters to this paper |
| Design | Numbered design decisions with imperative run-in headers, each giving the reason before the mechanism |
| Evaluation | Setup described so it could be rerun (exact iteration counts, problem sizes, machines, software versions, why each was chosen) → one run-in-header paragraph per application → results per benchmark → losses reported as plainly as wins |
| Discussion | Optional, between results and related work; converts the measurements into named, numbered heuristics or scoped bullet conclusions, each with its bounding clause |
| Related work | Grouped by approach under run-in headers; for each closest work, "Unlike them, our…" or "Our work is orthogonal to these approaches, as…" plus the mechanism-level difference |
| Limitations | Rarely a section of its own. Usually merged as *Conclusions and Future Work* or *Conclusions and Future Directions*, or split off ahead of related work as *Discussion and Future Work*. Whatever the title, each future item names the limitation it addresses |
| Conclusion | Restate contributions concretely with numbers; often a past-tense rewrite of the abstract; no new framing, no flourish |

## Diction

`references/sentence-craft.md` has the working vocabulary, the transition
inventory, the hedging register, and a list of words to avoid. Consult it when
revising line by line or when a draft feels close but off.

The characteristic verbs: *leverage, exercise, expose, characterize, quantify,
assess, examine, demonstrate, identify, eliminate, preserve, augment, restrict*.
For the measurement and monitoring papers, add *predict, model, evaluate,
reproduce, replicate, capture, collect, annotate, sample*. The characteristic
framings: *viability, feasibility, tradeoff, overhead, fast path, critical path,
semantics, expressiveness, fidelity, granularity, scalability*.

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

Student and collaborator drafts usually need the same passes, in order:

1. **Find the missing gap pivot.** If the introduction states context and then
   jumps to the contribution, the gap is unstated. Insert a `However,` sentence
   naming what existing approaches fail to do. Conversely, if `Unfortunately,`
   appears three or more times, demote all but the strongest to `However,`.
2. **Convert contribution bullets to noun phrases** and add section
   cross-references. If the draft mixes noun phrases with `We`-led bullets,
   pick one form for the whole list.
3. **Check for the roadmap paragraph.** If the introduction ends on the
   contribution bullets and the bullets do not carry section cross-references,
   add "The remainder of this paper is structured as follows." and one clause
   per section, folding related work and the conclusion into the last clause.
4. **Add the mechanism** to every comparative claim. Search for *better*,
   *faster*, *more efficient*, *improved* and require each to name what changed.
5. **Add numbers and their uncertainty** to every performance claim; delete
   claims for which no measurement exists.
6. **Find the hidden loss.** If the evaluation reports only wins, either the
   experiment was too narrow or a result was omitted. Report it, and carry it
   into the conclusion.
7. **Check that novelty claims are bounded.** "The first" becomes "the first of
   which we are aware"; "all proposals" becomes "all nine proposals known to the
   authors."
8. **Hunt the rhetorical colons.** Search running prose for `: ` and check each
   one. If it follows a short punchy clause rather than introducing a list,
   enumeration, or definition, rewrite the sentence plainly. Do the same for
   count-announcing sentences and mid-paragraph aphorisms.
9. **Keep the concrete names.** Benchmarks, matrices, applications, and machines
   are named, never generalized away — *audikw_1*, *Serena*, *CTH-st*, *LULESH*,
   *Frontier*, *Tuolumne*. If a draft says "an adaptive-mesh hydrodynamics code"
   where the code has a name, put the name back.
10. **Cut the selling.** Delete *seamlessly*, *cutting-edge*, *paradigm*, and
    any sentence that would fit in another paper unchanged. Replace
    *significantly* with the number wherever a measurement exists.
11. **Bound the heuristics.** If the draft has a discussion section offering
    recommendations, check that each one names the case where it does not hold.

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
