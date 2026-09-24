# Sentence craft: diction, transitions, hedging, quantification

Use this file when revising line by line, or when a draft has the right
structure but the wrong texture.

## Contents

- [Working vocabulary](#working-vocabulary)
- [Transitions](#transitions)
- [Hedging and bounded claims](#hedging-and-bounded-claims)
- [Quantification conventions](#quantification-conventions)
- [Emphasis and typography](#emphasis-and-typography)
- [Sentence shapes](#sentence-shapes)
- [Words and constructions to avoid](#words-and-constructions-to-avoid)
- [Before and after](#before-and-after)

---

## Working vocabulary

**Verbs that carry the paper.** These do most of the work and recur across every
paper in the corpus:

*leverage, exercise, expose, characterize, quantify, assess, examine,
demonstrate, identify, eliminate, preserve, augment, restrict, enqueue, defer,
trigger, amortize, saturate, offload, overlap, scale, turn over*

*exercise* has a specific technical sense — a benchmark exercises a
communication pattern. *expose* likewise — a benchmark exposes a performance
difference. Both are used constantly and should not be swapped for *test* or
*show*.

**Nouns that frame the analysis:**

*viability, feasibility, tradeoff, overhead, fast path, critical path, semantics,
expressiveness, usability, scalability, strong scaling, weak scaling,
granularity, ablation, insight, mechanism, abstraction*

Two framings are so characteristic they appear in paper titles: **viability**
("Evaluating the Viability of…", "On the Viability of…") and **feasibility**
("to Assess the Feasibility of…"). When the paper's question is whether an
approach can work at all, use these rather than "effectiveness."

**Adjectives, used sparingly:** *fine-grained, coarse-grained, lightweight,
irregular, persistent, transient, uncorrected, deferred, restricted, canonical,
modest*. Adjectives are load-bearing technical qualifiers here, not color.

---

## Transitions

The inventory is small and every item does work.

| Transition | Use |
| --- | --- |
| `Unfortunately,` | The gap. The single most characteristic transition in this voice. |
| `However,` | Same job as *Unfortunately* with less weight; also for mid-paragraph caveats. |
| `In contrast,` | Direct comparison between two named approaches. |
| `Specifically,` | Narrowing from a general claim to the precise one. Very frequent. |
| `In particular,` | Picking out the most important member of a set just introduced. |
| `Note that` / `Note, however,` | Flagging the inconvenient fact the reader must carry forward. |
| `As a result,` | Consequence, usually of a constraint just stated. |
| `Similarly,` | Second instance of a pattern; also links future-work items. |
| `Because of this,` | Design rationale. |
| `First, … Second, … Third, … Finally,` | Ordinal structure in design decisions and future work. |

Do not invent transitions outside this set. `That said,`, `Moving forward,`,
`With that in mind,`, `Importantly,`, `It is worth noting that` do not appear in
the corpus and read as someone else's prose.

---

## Hedging and bounded claims

The register is confident about mechanism and cautious about generality. Hedge
the scope of a claim, never the mechanism itself.

**Bound the survey and the novelty claim.** Do not claim exhaustiveness, and
attach "of which we are aware" or "known to the authors" to any "first" or
"all":

> we are aware of only two that attempt to provide CPU-free communication

> The work described in this paper is the first **of which we are aware** that
> provides an analytical underpinning to studies of emerging HPC application
> interference…

> This is the first comprehensive survey of all nine proposals **known to the
> authors** that address stream/graph-, kernel-triggered, and GPU-initiated
> communication abstractions for MPI…

> Existing proposals/prototypes cited in this paper **may not include** all
> hardware vendors or systems currently available and certainly there **may be**
> other solutions forthcoming or that are not yet public.

**Attribute the hypothesis.** When the reason is a belief rather than a
measurement, say so:

> This is, **we hypothesize,** because both the numerical methods that require
> these complex communication patterns are inherently complex and beyond the
> scope of what is normally considered appropriate for a mini-application.

**Qualify generality with `generally`, `typically`, `often`, `most`, `many`.**
These appear constantly and are precise, not weaselly:

> More general-purpose GPU communication APIs, including **most** proposed
> GPU-triggered MPI APIs [8] and NVIDIA NCCL [6], **still generally** use the CPU
> on the communication fast path.

**Mark preliminary work as preliminary.** *initial*, *preliminary*,
*prototype*, *first step* are used without embarrassment:

> We also present **preliminary** results that examine the viability of the basic
> approach and the software abstractions needed to support it.

> **These initial results are promising, but more work is needed.**

**Name the best case when you report the best case:**

> This latency improvement is a **best-case** improvement for stream triggering
> because it requires two kernel launches and a synchronization per send.

**Use `may`, `can`, `could` for projected rather than measured effects:**

> This optimization **may** reduce communication latency and increase
> small-message bandwidth, while improving the performance of strong scaling
> workloads whose performance is dominated by communication latency.

---

## Quantification conventions

- **Ranges over point estimates** when the measurement varies across a
  parameter: `12–39%`, `62-239%`, `6-13%`, `2.7–4.9%`.
- **Name the parameter range the number applies over**: "for message sizes
  between 32 bytes and 512KB."
- **`up to X%`** only in abstracts and headline sentences, never as the only
  form in the results section.
- **Uncertainty in tables**: `49.04 ± 0.26`.
- **State the statistical basis once, up front**: "Headline performance claims
  are supported by non-overlapping 95% confidence intervals on the per-trial
  averages"; "show the average and 95% confidence intervals of the runtime after
  six trials."
- **Report scale in concrete units**: "8,192 GPUs", "1,024 nodes",
  "approximately 3800 source lines of code", "roughly 24M mesh points".
- **Parenthesize the derivation** when a percentage needs one: "a parallel
  efficiency of only 21% (3.5x speedup when moving from 4 to 64 GPUS)".
- Never write *significantly* to mean *a lot*. Either give the number, or
  reserve *significantly* for its statistical sense.

---

## Emphasis and typography

- *Italics* mark a term at its first definition (*CPU-free*, *failable memory*,
  *strong scaling*, *triggering counters*, *deferred work queues*, *domains*).
  Once defined, the term is set in roman.
- *Italics* also fall on the single word carrying a distinction, never a whole
  clause: "our API does not *require* the programmer to guarantee receiver
  readiness"; "to test performance *beyond* the strong scaling limit"; "The
  ZModel class does *not* directly communicate."
- `Monospace` for API calls, environment variables, and type names —
  `MPI_Recv`, `FI_REMOTE_WRITE`, `hipStreamWriteValue64`, `mprotect()`.
- **Bold** only for run-in headers, not for emphasis inside prose.
- No em dashes for dramatic pause. Parentheses and colons carry asides.

---

## Sentence shapes

**The enumerated-reason sentence.** The workhorse.

> Our approach uses persistent point-to-point and collective operations whenever
> possible for two reasons: (1) …, and (2) ….

**The mechanism sentence.** Subject is the mechanism, verb is what it removes or
enables.

> This eliminates the extra network round trip used by the prior approach.

> These operations could also be used to construct fully-offloaded CPU-free
> collective operations.

**The definition-with-exclusion sentence.** Two clauses joined by a colon, then
a follow-on sentence stating what stays outside.

> By *CPU-free*, we mean specifically that …: all data movement, completion
> notification, and synchronization … are handled by the GPU stream and the NIC.
> CPU work remains during request setup (…), as is typical for persistent MPI
> operations.

**The win-then-caveat sentence.** One sentence, or two adjacent sentences, never
separated by a paragraph break.

> On Tuolumne, stream-triggered send and ready send outperform Cray MPICH on the
> large problem by 17-32%, but underperform Cray MPICH on the small problem by
> 22-34%.

**The consequence chain.** Short sentences in sequence, each the consequence of
the last, used to build to the gap.

> The combination of the quantity and the density of the information they store
> makes them particularly susceptible to faults. As a result, most HPC systems
> include some built-in hardware fault tolerance for DRAM.

---

## Words and constructions to avoid

None of these appear in the corpus. Their presence marks a draft as not this
voice.

**Marketing register:** novel paradigm, cutting-edge, state-of-the-art (as
praise rather than as a noun phrase for prior work), revolutionary, seamlessly,
robustly, powerful, game-changing, unlock, harness (use *leverage*), delve.

**Empty intensifiers:** very, quite, extremely, incredibly, dramatically (unless
followed by a number), vastly, hugely. Note that *dramatically* does appear once
in the corpus — "dramatically reduced the size and complexity of the Beatnik
code base" — where the reduction is documented elsewhere by line count. If you
cannot point at the number, cut the word.

**Hedge stacking:** it is worth noting that, it is important to remember that,
one could argue that, arguably, in many ways.

**Contrastive hype:** "It's not X, it's Y"; "not just X but Y"; "X isn't
evolving — it's accelerating." Bridges' comparisons are always
`Unlike them, our…` plus a mechanism, never a reversal for effect.

**The rhetorical lead-in colon.** A short declarative clause, a colon, then the
real content. Bridges flags this on sight as AI writing. All of these were
rejected from drafts:

> The flush is what hurts: the application still pays PFS commit bandwidth.
> That cost is dominated by one term: the bandwidth required to commit a
> checkpoint to the parallel filesystem.
> The mechanism-level difference is who moves the data: their simulated model
> assumed the host CPU drives the copy.

Colons in this voice do three jobs and no others: introduce an inline
enumeration, introduce a list or set of steps, or expand a definition. Compare
the legitimate uses from the corpus:

> for two reasons: (1) they cover almost all of the commonly used MPI
> semantics […] and (2) they explicitly separate setup operations…

> Specifically, our recovery model comprises the following steps:

> libfabric defines two features to enable construction of triggered
> communication: (1) *triggering counters* that count network device events…

Each rejected example becomes an ordinary sentence carrying its own mechanism:

| Rejected | Rewritten |
| --- | --- |
| The flush is what hurts: the application still pays PFS commit bandwidth. | Because node-local capacity is small, the application still pays parallel filesystem commit bandwidth, only on a slightly longer period. |
| The mechanism-level difference is who moves the data: their simulated model assumed the host CPU drives the copy. | Their simulated model assumed the host CPU drives the copy, whereas our implementation issues it from the expander's DMA engine, which is why our measured overhead is lower than their projection. |

**Count-announcing sentences.** "Three extensions follow directly." "Two
problems remain." The corpus introduces future work with an ordinary framing
sentence and then ordinals: "There are many directions for future work that
address limitations of our study and build on the research described in this
paper. First, …"

**Mid-paragraph aphorisms.** "Capacity, not bandwidth, is the binding
constraint." "The tradeoff is the point." Pithiness is not a virtue in this
register; a sentence earns its place by carrying a mechanism or a number.

**Generalizing away concrete names.** The corpus names everything — *audikw_1*,
*Serena*, *Bump_2911*, *Queen_4147*, *CTH-st*, *LULESH*, *HPCCG*, *SAMRAI*,
*Frontier*, *Tuolumne*, *Lassen*. Writing "an adaptive-mesh hydrodynamics code"
when the code is named Fuji drops information the reader needs and reads as
hedging.

**Stock closers:** In conclusion, Overall, To summarize, In summary, Ultimately.
Conclusions begin "In this paper we presented…" or with the artifact's name.

**Stock academic filler:** "a growing body of work", "a rich literature",
"has received considerable attention", "an active area of research". These fit
any paper on any topic, which is what makes them filler. The corpus says the
specific thing instead — "Many MPI APIs for GPU communication have been
proposed, as recently surveyed [8]" or "DRAM errors have been intensively
studied in both HPC and other large computing systems recently."

**Rhetorical questions.** The corpus contains none in Bridges-authored text.

**Passive constructions that hide the actor.** "It was determined that" →
"we determined that". "Performance was measured" → "We measured the performance
of". Passive is fine where the actor is genuinely irrelevant or is the system:
"requests that modify shared state are broadcast to *every* domain."

---

## Before and after

**Generic systems prose → this voice**

Before:

> Our novel approach dramatically improves communication performance compared to
> existing state-of-the-art solutions, demonstrating the power of GPU-side
> triggering. Experiments show significant speedups across a range of workloads.

After:

> Our implementation reduces medium-message ping-pong latency by 12–49% relative
> to Cray MPICH for message sizes between 32 bytes and 512KB, and increases
> latency by 2.7–4.9% for messages 8MB and larger. The improvement comes from
> triggering the local completion atomic from the receiver's FI_REMOTE_WRITE
> counter, which eliminates the extra network round trip used by prior CPU-free
> approaches.

**Padded contribution bullet → noun phrase**

Before:

> - We implemented our system on Slingshot hardware and we show that it works
>   well.

After:

> - A CPU-free implementation of this API for HPE Slingshot 11 systems that
>   leverages the deferred work queue (DWQ) and counter features of the libfabric
>   API and the HPE libfabric CXI provider (Section V).

**Summary-style related work → differencing related work**

Before:

> Smith et al. proposed a GPU-triggered send/receive interface. Jones et al.
> extended this with stream semantics. Our work is related to both.

After:

> Of these, the HPE two-sided GPU communication API [12] and the MPICH
> MPIX_Stream API [11] are closest to our work, and key features from these
> proposals informed our design. Unlike them, our API leverages persistent
> communication to reduce the number of operations to add to the API and augments
> two-sided matching semantics to enable one-sided data movement.

**Hidden loss → reported loss**

Before:

> Our approach achieves strong performance on both systems, with speedups of up
> to 46%.

After:

> On Frontier, stream-triggered send and ready send consistently outperform Cray
> MPICH, achieving 6-13% higher maximum mean speedup on the small problem and a
> 40-46% higher maximum mean speedup on the large problem. On Tuolumne,
> stream-triggered send and ready send outperform Cray MPICH on the large problem
> by 17-32%, but underperform Cray MPICH on the small problem by 22-34%.
