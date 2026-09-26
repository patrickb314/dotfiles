# Section patterns with verbatim exemplars

All quoted passages are from published Bridges papers. They are here to be
imitated in structure and register, not copied.

## Contents

- [Abstract](#abstract)
- [Introduction](#introduction)
- [Background](#background)
- [Design](#design)
- [Implementation](#implementation)
- [Evaluation](#evaluation)
- [Discussion](#discussion)
- [Related work](#related-work)
- [Limitations and future work](#limitations-and-future-work)
- [Conclusion](#conclusion)

---

## Abstract

Six moves, in this order. The formula holds across fifteen years.

1. **Stakes** — one sentence on why the problem matters now.
2. **`However,` the gap** — what existing approaches do and why it is not enough.
3. **`In this paper we describe…`** — the thesis, naming design, implementation,
   and evaluation explicitly when all three are present.
4. **What we demonstrate** — the application or use case that makes it concrete.
5. **The key mechanism** — the one technical insight, named specifically.
6. **Quantified results**, including at least one that is qualified or weaker.

Exemplar (2026, CLUSTER):

> Removing the CPU from the communication fast path is essential to efficient
> GPU-based ML and HPC application performance. **However,** existing GPU
> communication APIs either continue to rely on the CPU for communication or
> rely on APIs that place significant synchronization burdens on programmers.
> **In this paper we describe the design, implementation, and evaluation of** an
> MPI-based GPU communication API enabling easy-to-use, high-performance,
> CPU-free communication. We demonstrate the utility and performance of the API
> by showing how it enables CPU-free gather/scatter halo exchange communication
> primitives in the Cabana/Kokkos performance portability framework. The
> implementation leverages FI_REMOTE_WRITE triggering counters to handle
> two-sided readiness and receive notification without CPU involvement or the
> extra round trip used by prior CPU-free one-sided approaches. A performance
> comparison with Cray MPICH on the Frontier and Tuolumne supercomputers shows
> up to a 50% reduction in medium message latency in GPU ping-pong exchanges and
> a 46% speedup improvement over Cray MPICH on regular halo-exchange benchmark
> strong scaling on 8,192 GPUs of the Frontier supercomputer. [...] An ablation
> that disables Cray MPICH's small-message and on-node optimizations shows our
> implementation faster for more configurations on all four CG matrices,
> identifying the path to closing the remaining gap.

Exemplar (2011, Resilience workshop) — same skeleton, smaller paper:

> Exascale systems will present considerable fault-tolerance challenges to
> applications and system software. These systems are expected to suffer several
> hard and soft errors per day. **Unfortunately,** many fault-tolerance methods
> in use, such as rollback recovery, are unsuitable for many expected errors,
> for example DRAM failures. As a result, applications will need to address
> these resilience challenges to more effectively utilize future systems. **In
> this paper, we describe** work on a cross-layer application / OS framework to
> handle uncorrected memory errors. We illustrate the use of this framework
> through its integration with a new fault-tolerant iterative solver within the
> Trilinos library, and present **initial** convergence results.

Note the word *initial* in that last sentence. A workshop paper says so.

Exemplar (2024, CCGrid) — the tightest instance of move 6 in the corpus, where
the win and the loss share a single sentence:

> Modern communication APIs provide increased ability to specify when, where,
> and how to send data between processes. One recent innovation is fine-grained
> communication, where processes are able to send subsets of data as it is ready
> rather than waiting for the entirety of the data to be completed. Allowing
> data to be sent when it is ready increases opportunities for overlapping
> communication and computation. **However,** with multiple fine-grained,
> thread-safe interfaces, the task of optimizing an application's peer-to-peer
> fine-grained communication is complex. **In this paper, we present** the
> Configurable Messaging Benchmark (CMB), a tool for evaluating the application
> impact of fine-grained communication. Using the CMB we perform a case study to
> measure the impact of different fine-grained implementations on a variety of
> realistic application profiles. **Initial results reveal a large optimization
> space ranging from potential speedups as high as 52.97% to slowdowns as high
> as 289.55% relative to bulk-synchronous MPI message passing.**

A generic abstract would have stopped at "speedups as high as 52.97%." Reporting
the 289.55% slowdown in the same clause is what marks the voice, and a draft
that omits the losing number will read as someone else's work no matter how
well the rest of it follows these patterns.

Move 3 has several forms depending on what the paper produced: "In this paper we
describe the design, implementation, and evaluation of…" for a system, "In this
paper, we present…" for a tool, "In this article, we present…" in journal
format, and "In this paper we address this lacuna by measuring and evaluating…"
when the paper is a measurement study answering a named gap.

---

## Introduction

Four paragraphs, occasionally five.

**Paragraph 1 — the technical landscape.** Present tense, heavily cited,
establishes what modern systems do. Introduce the field's own term for the goal
if one exists, and attribute it: "a recent survey of GPU communication
techniques termed this overarching goal *CPU-free communication*."

**Paragraph 2 — the gap.** Opens with the pivot. Name specific features that
existing approaches sacrifice, with citations attached to each.

> Currently proposed CPU-free communication interfaces and implementations often
> significantly reduce the expressiveness of the communication API. For example,
> some remove support for features commonly used in HPC applications, such as
> message matching [1], [5]–[7] and two-sided data movement [5], from the
> available APIs to achieve the benefits of CPU-free communication; this has
> limited their usability in HPC applications and performance portability
> frameworks.

**Paragraph 3 — the thesis and its scope.** One sentence stating what the paper
does, then the scoped definition of the paper's central term.

> This paper describes the design of new MPI abstractions that enable CPU-free,
> two-sided MPI GPU communication, together with a CPU-free implementation of
> these abstractions for HPE Slingshot network interfaces and an evaluation of
> their performance. By *CPU-free*, we mean specifically that…

**Paragraph 4 — contributions.** See the main SKILL.md. The lead-in is usually
"This paper makes the following contributions:"; bullets are noun phrases;
cross-reference sections.

**Paragraph 5 — roadmap.** Expect this paragraph rather than treating it as
optional; it appears in most of the group's IEEE- and ACM-format papers. Full
form, one clause per section, opened by a fixed sentence and closed by folding
related work and the conclusion together:

> The remainder of this paper is structured as follows. We provide a background
> for our paper in Section II. We detail the design of the CMB in Section III.
> We describe how we conducted our experiments and present the results of our
> experiments in Section IV. We discuss the implications of the case study in
> Section V. Finally, we distinguish our work from existing related work in
> Section VI and present our conclusions in Section VII.

> The rest of this paper is structured as follows. Section 2 explains the
> background and the problem the paper addresses. Section 3 discusses the
> instrumentation and experimental set-up for this paper. Section 4 presents the
> results of our experiments. Section 5 discusses the implications of this work
> and presents our plan for future extensions. Section 6 contextualizes our work
> in the body of related work. Section 7 concludes our paper.

Pick one grammatical subject — *we* or the section — and hold it for the whole
paragraph.

Compressed form, one sentence, used when the contribution bullets already carry
their own cross-references:

> In addition, we compare this approach with other systems for monitoring
> communication in HPC applications (cf, Section 6), and present directions for
> future work and conclude (cf, Section 7).

> Following the presentation of these contributions, the paper discusses
> directions for future work (Section VI), and concludes (Section VII).

> Following an explanation of these contributions, we discuss our results and
> their implications, describe related work and conclude.

> We conclude with a thorough discussion of related work and directions for
> future work.

Short papers compress all of this into a "we begin / we then / finally" roadmap:

> We begin by reviewing the basics of DRAM memory failures and how they are
> handled in current systems. We then discuss a specific model of memory
> failures that we are examining, how the application, OS, and hardware can
> interact to provide this failure model, and how applications recover in this
> scenario. Based on this, we then present a simple OS and hardware interface
> [...] Finally, we discuss related and future work.

---

## Background

Opens by saying what the section will cover, in the order it covers it:

> Our research builds on multiple approaches to reduce these overheads, many of
> them leveraging features of modern communication devices. The remainder of
> this section provides background on GPU communication costs, prior approaches
> to reducing them, and the libfabric features we leverage on HPE Slingshot NICs.

When the paper imports a technique from another field, background explains it to
a systems audience the same way every time: name the field, say what the
technique is for, give concrete uses from unrelated domains to build intuition,
and only then give the math.

> Extreme value theory (EVT) is a sub-field of statistics focused on the
> behavior of maxima of a set of random variables [23]. It is generally used to
> analyze or predict the likelihood of extreme events occurring. EVT works with
> a set of independent, identically distributed (i.i.d.) stochastic events of
> potentially unknown distribution, and seeks to understand when a new extreme
> value (a sample larger than those seen previously) should be expected to
> happen. **It is used in fields such as hydrology to determine long-term flood
> plain levels, and for similar actuarial analyses in the insurance and
> financial industries. It has also been used to estimate the size of demand
> bursts in internet traffic [42].**

The bolded sentences are the ones most writers skip. They are what make an
unfamiliar statistical tool legible to a systems reader in one paragraph.

Subsections use run-in bold headers to enumerate categories of prior approach.
Each entry follows the same internal shape: *name the approach → describe the
mechanism → say what it costs → cite the canonical system*.

> **GPU-initiated CPU-driven communication:** In this approach, GPU kernels
> interact with CPU communication threads that poll memory, waiting for GPU
> kernel completion before initiating communication. This reduces kernel launch
> and stream synchronization latencies, and is typified by the NVIDIA Collective
> Communication Library [6], the MPIX_Stream extension [11] to the MPICH
> communication library, and HPE's original GPU-based communication primitives
> [12].

Background subsections end by stating the payload for this paper — what the
reader needs to carry forward:

> **Note, however,** reading CXI counter values requires CPU progress to update
> host writeback buffers. As a result, GPU memory operations cannot directly
> read CXI counters without CPU involvement.

That `Note, however,` construction is the standard way of flagging the
inconvenient fact that motivates the paper's mechanism.

---

## Design

Open by stating the goal that constrained the design, in first person plural:

> Because of the importance of two-sided communication to a wide range of HPC
> applications, we set out to design an API that supports as many of the
> two-sided and collective MPI communication modes as possible. In addition, we
> sought to design an API that would support CPU-free GPU control flow and data
> movement on the communication fast path of HPE Slingshot 11 network devices.

Then a `Design Decisions` subsection of lettered items with imperative run-in
headers. Each item gives the *reason first, mechanism second*, and inline
enumerations carry the reasons.

> *a) Reuse existing MPI persistent operations:* Our approach uses persistent
> point-to-point and collective operations whenever possible for two reasons:
> (1) they cover almost all of the commonly used MPI semantics, reducing the
> number of new abstractions or optimizations that need to be added to MPI, and
> (2) they explicitly separate setup operations involved in creating a request
> from the use of that request on the communication fast path. The latter is
> particularly important because it allows our matching function to remove
> communication operations with complex semantics [...] from the GPU-NIC fast
> path, where such operations are generally infeasible.

> *d) Retain required MPI buffer readiness guarantees:* **Unlike other
> approaches,** our API does not *require* the programmer to guarantee receiver
> readiness before enqueueing a send. [...] However, we determined that such
> calls were (1) unnecessary if…, and (2) were undesirable if…

Note the italicized *require* — emphasis falls on the single word that carries
the distinction, never on a whole phrase.

Design sections present models as numbered step lists when the sequence is the
contribution:

> Specifically, our recovery model comprises the following steps:
>
> 1. The application designates to the operating and runtime system the portions
>    of its memory in which it can tolerate a transient memory error. Errors in
>    portions of memory not so designated are deemed fatal and cause application
>    termination.
> 2. Upon receiving notification of an uncorrectable memory error in designated
>    memory, the OS signals the application that an error has occurred at a
>    specified address.
> …

---

## Implementation

States what was built on top of what, then describes each module in run-in bold
with its communication or synchronization behavior. Code size is reported as a
fact, because small code size is itself a claim:

> Beatnik's current C++ implementation consists of approximately 3800 source
> lines of code grouped into two set of modules: core modules which implement
> fundamental data structures and algorithms common to all solution methods, and
> Birchoff-Rott (BR) solver modules which implement different approaches to
> estimating the far-field forces […] We detail these modules and their
> communication behavior in the remainder of this section.

> Our entire solver prototype uses only 2500 lines of C++ code.

Module descriptions state what the module does *and what it does not do*, since
the negative fact is usually the interesting one:

> **ZModel** computes derivatives of interface position and velocity using
> heFFTe and BR solver modules as necessary for different model orders. [...]
> The ZModel class does *not* directly communicate with other MPI processes but
> instead invokes other classes which carry out communication specific to the
> relevant numerical method.

---

## Evaluation

Open with what was measured, against what, on which benchmarks, and how claims
are supported statistically:

> We measured the performance of the co-designed API and its prototype
> implementation described in the previous sections to evaluate its strengths
> and weaknesses in comparison with the other communication approaches.
> Specifically, we compared our implementation against Cray MPICH on (1)
> ping-pong micro-benchmarks and (2) CabanaGhost halo-exchange strong scaling,
> and against both Cray MPICH and RCCL on (3) aCG strong scaling. Headline
> performance claims are supported by non-overlapping 95% confidence intervals
> on the per-trial averages.

Note "strengths **and weaknesses**" — stated as the purpose up front.

**When the paper's question is whether an approach is worth doing**, the
evaluation opens by defining what "worth doing" means, before any measurement.
This is the *viability* framing that recurs throughout the corpus:

> **II. EVALUATING THE VIABILITY OF MEMORY COMPRESSION**
>
> In this section, we examine the conditions that must exist for memory
> compression to be viable. Memory compression is viable if its benefits
> outweigh its costs. In this context, the benefit of memory compression is a
> reduction of the application's total execution time. Instead of rolling the
> application back to an earlier checkpoint, memory compression allows the
> application to recover from a DUE by decompressing the backup of the damaged
> page. The principal costs of memory compression can be divided between storage
> overhead and runtime overhead. In the remainder of this section, we
> analytically model the costs and benefits of memory compression to determine
> when it is likely to be viable.

Both sides of the criterion get named — benefit *and* the decomposition of cost
— so the later measurement has something to land against.

**The applications or benchmarks get their own subsection**, with one run-in
paragraph each. The internal shape is fixed: name the code, say in one sentence
what it computes, name the communication or execution feature that makes it
relevant to this paper, and close with a measured fact about its behavior at
scale, cited. The last element is what separates this from a list of names.

> **Parthenon-VIBE** is a hydrodynamics code that solves the inviscid burgers
> equations, built on top of the Parthenon block-structured AMR framework. It
> consists of a neighbor exchange step in addition to a complex load balancing
> step as mesh blocks are mapped to different ranks. **It has been shown to be
> network bound when running at scale on the Crossroads supercomputer [43].**
>
> **AMG 2023** is a parallel algebraic multigrid solver for linear systems on
> unstructured grids that utilizes BoomerAMG and Krylov solvers from hypre. It
> consists of two specified test problems: problem 1 is a 3D diffusion problem
> on a cuboid with a 27-point stencil which is solved with AMG-GMRES and problem
> 2 is a 3D laplace problem on a cuboid with a 7-point stencil which is solved
> using a preconditioned conjugate gradient method. Both solvers require
> irregular communication at each level of coarsening, and the communication
> pattern changes at each coarsening level and is data dependent on the
> structure of the input matrix. **It has been shown to achieve 29% weak scaling
> efficiency for problem 1 and 23% weak scaling efficiency for problem 2 at
> 2,048 nodes [43].**

**Experimental setup** is written so a reader could rerun it. Machines are
described in hardware detail; software versions are tabulated; configuration
choices are justified, including choices made on someone else's advice.

Machine descriptions name the system and give the socket, core, and network
detail in one sentence, then state the resulting process counts:

> Data was collected across 4—32 nodes of the Rocinante system at LANL. Each
> node of Rocinante's standard partition contains two sockets, where each socket
> is composed of a 56-core Intel Sapphire Rapids CPU, connected through a
> HPE/Cray Slingshot11 200Gb/s network. All applications were run with MPI only,
> providing runs on 448 MPI processes up to 3,584 MPI processes.

> The RCCL driver was configured to include the AWS NCCL OFI plugin [21] per
> system operator advice [22].

Parameter choices state the *reason for the choice*, not just the value:

> After completing warm-up iterations, we ran each ping-pong trial for a given
> buffer size for a number of round-trip iterations chosen to make the total
> measurement time between 1 and 30 seconds; this was 100,000 iterations for
> buffer sizes less than 4MB, 10,000 iterations for buffer sizes between 4MB and
> 64MB, and 1,000 iterations for buffer sizes greater than 64MB.

> We chose a large problem size of 30 GB to test strong scaling performance
> below and up to the strong-scaling limit. We chose a small problem size of 2GB
> to test both regular and stream-triggered performance *beyond* the strong
> scaling limit of the problem.

**Results** are reported with the win, the range, and then immediately the
caveat or the loss:

> Stream-triggered exchanges have significantly lower latency than CPU-triggered
> sends and receives, particularly for messages between 4KB and one megabyte.
> Specifically, stream-triggered sends and ready sends have 12–39% and 12–49%
> lower latency than Cray MPICH for message sizes between 32 bytes and 512KB,
> respectively, and 2.7–4.9% increased latency for messages 8MB and larger.
> **This latency improvement is a best-case improvement for stream triggering
> because** it requires two kernel launches and a synchronization per send; more
> complex communication patterns like halo exchanges will incur these overheads
> only once per halo exchange.

> On Frontier, stream-triggered send and ready send consistently outperform Cray
> MPICH, achieving 6-13% higher maximum mean speedup on the small problem and a
> 40-46% higher maximum mean speedup on the large problem. **On Tuolumne,
> stream-triggered send and ready send outperform Cray MPICH on the large
> problem by 17-32%, but underperform Cray MPICH on the small problem by
> 22-34%.**

When a result is disappointing, it is explained mechanistically rather than
excused:

> strong-scaling performance shows a performance increase when scaling from 4 to
> 64 GPUs, but with a parallel efficiency of only 21% (3.5x speedup when moving
> from 4 to 64 GPUS). Similarly, performance turns over and begins to decrease
> after 64 GPUs due to the small amount of computation and large number of
> messages that must be sent in this case. In particular, each GPU stores and
> computes on only a 76 by 76 section of the surface mesh in the 64-node case,
> but must perform all-to-all communication with dozens of other processes.

---

## Discussion

Present when the evaluation produced advice rather than a verdict, and placed
between the results and related work. It converts measurements into a short
list of findings; it does not re-narrate the figures.

The lead-in names what kind of list follows and what evidence produced it:

> The results reported by the CMB and described above suggest several broad
> conclusions and heuristics regarding the use of fine-grained communication:

> The performance of our parametric and non-parametric methods on these six
> workloads performed on two different systems leads us to conclude the
> following:

Two layouts. Numbered items with named run-in headers, when each finding needs a
paragraph of argument:

> **1) Necessity of Empirical Analysis:** Our evaluation demonstrates that the
> same application profile (combination of thread arrival distribution,
> communication stencil, and volume communicated between peer processes) using
> the same fine-grained implementation […] can exhibit different behaviors
> depending on the system used. For example, some techniques that prove
> consistently beneficial on Manzano result in slowdowns on Mutrino. The factors
> that govern performance are complex and hard to disentangle when their impacts
> are so interdependent. Given this, a tool like the CMB can be invaluable in
> making design decisions.
>
> **2) Avoiding Pitfalls:** Figures 5, 6, and 7 show the potential hazard of
> poor fine-grained implementations. Although benefits are possible, these
> results show that some configurations perform radically worse than
> bulk-synchronous two-sided message passing. Conveniently, these configurations
> are easy to avoid. We see that for both systems the worst performing
> configurations are those with a large number of transport partitions coupled
> with two-sided MPI message passing. Although this configuration may start
> communication earlier, the message and matching overheads are considerable.

Or plain bullets, when each finding is a single conditional claim:

> - Computation and memory-bound kernels without any only local (e.g. stencil)
>   communication can be accurately measured, and their performance variation
>   accurately quantified and predicted using both parametric and non-parametric
>   methods.
> - Parametric methods that rely on GEV estimation and either node or rank level
>   granularity of data rather than iteration maxima granularity of data
>   overestimate performance variation on workloads with internal communication
>   and synchronization overhead. However, their median estimates remain
>   accurate.
> - Parametric methods can still be useful in evaluation and predicting
>   performance variation on workloads with internal communication and
>   synchronization overhead **if and only if** the network behaves predictably
>   and with minimal fluctuations.

Every item carries its own bounding clause. The corpus never states a
recommendation without the case where it fails:

> For Manzano it was consistently beneficial to aggregate and send two messages,
> with speedups as high as 12.79%. On Mutrino, the same configurations generally
> had slowdowns of less than 1%. […] Existing modeling work predicts that our
> Mutrino results are atypical [18], [19], **but it does limit our
> recommendation for applications sending buffers of this size.**

Note the last clause. The paper had an excuse available, since prior modeling
says the machine is atypical, and it narrowed its own recommendation anyway.

---

## Related work

Never a list of summaries. Organized by approach — often under bolded topical
headers (**Interference impact characterization.**, **Extreme Value Theory.**) —
and for each closest work the paragraph does three things: name what it does,
name what ours does differently, and name the **mechanism** of that difference.

> Many MPI APIs for GPU communication have been proposed, as recently surveyed
> [8]. Of these, the HPE two-sided GPU communication API [12] and the MPICH
> MPIX_Stream API [11] are closest to our work, and key features from these
> proposals informed our design. **Unlike them,** our API leverages persistent
> communication to reduce the number of operations to add to the API and
> augments two-sided matching semantics to enable one-sided data movement.

> **A key mechanism-level difference from [7] is how** the local completion
> atomic that the GPU polls is triggered: our approach triggers it from the
> receiver's FI_REMOTE_WRITE counter and uses the same mechanism to handle CTS
> messages on the sender, rather than having the sender issue a second fenced
> write to release the receiver. This eliminates the extra network round trip
> used by the prior approach.

Not every comparison is competitive. When prior work sits on a different axis,
name the axis instead of claiming superiority:

> Our work is **orthogonal to** these approaches, as it targets MPI
> communication rather than MPI-IO and can be utilized to represent and diagnose
> entire communication patterns rather than individual call sites while
> providing a framework to explore the tradeoffs in fidelity and scalability of
> different statistical techniques.

> Caliper, in particular, provides a query language, cali-query, for offline
> analysis, while also implementing a ConfigManager to flush data at specified
> intervals, but still requires dumping the entire trace at some point,
> potentially limiting its scalability on long-running production runs of HPC
> applications. **Vernier by way of contrast provides** a combination of
> features that these tools have in addition to providing a flexible backend to
> perform online analysis and binning of data in customizable ways.

The section can open with a sentence stating the axis of comparison for the
whole section rather than diving into the first citation:

> Many tools, benchmarks, and proxy applications have been developed to collect
> communication traces and profiles and to attempt to replicate the
> communication patterns of large multi-physics applications when run at scale.
> We discuss many of these approaches and how Vernier, coupled with the
> flexibility to represent communication patterns at various levels of fidelity,
> can provide the ability to perform deeper research on irregular and dynamic
> communication patterns on applications at scale.

Claims about coverage of the literature are explicitly bounded:

> Of the MPI GPU-triggered communication implementations, **we are aware of only
> two that** attempt to provide CPU-free communication…

Novelty claims are bounded by what the authors know rather than asserted
absolutely:

> The work described in this paper is **the first of which we are aware** that
> provides an analytical underpinning to studies of emerging HPC application
> interference…

> **However, to the best of our knowledge, none of these tools** have the
> flexibility to perform online binning of the collected data to explore the
> trade space between scalability and fidelity…

> This benchmark allows for exploration of potential application performance
> impact of different fine-grained communication **to a degree that has not been
> explored in prior work.**

Credit prior work generously and by name before differentiating from it: "key
features from these proposals informed our design"; "Published information on
the HPE one-sided system informed our data movement and triggering design."

The strongest version of this — and a distinctive move — credits a method the
paper is otherwise differentiating from as indispensable:

> Moreover, unlike our work, the authors did not use extreme value distributions
> themselves to estimate application performance. As previously discussed in
> IV-D, this limits EMMA's direct use in application performance estimation.
> **Nonetheless, the method described in this paper for conducting such
> estimations relies heavily on EMMA for extrapolation, and would not be
> possible without it.**

---

## Limitations and future work

Rarely a standalone section. Across the corpus the slot is filled four ways, and
the choice follows paper length more than anything else:

- merged into the conclusion, titled *Conclusions and Future Work* or
  *Conclusions and Future Directions* — the common case in conference papers;
- a *Discussion and Future Work* section placed before related work, which
  doubles as the heuristics section described above;
- a standalone *Limitations and Directions for Future Work* section, used when
  the limitations are substantial enough to need their own argument;
- a closing paragraph of the conclusion, in workshop papers.

Whichever form, the framing sentence makes explicit that future work addresses
*this paper's* limitations:

> There are many directions for future work that address limitations of our
> study and build on the research described in this paper.

Each item follows: *state the limitation → state why it produces the observed
weakness → state the specific work that would address it*.

> First, the current implementation uses a single libfabric fi_write operation
> to a user-provided buffer for data movement. The vendor implementations with
> which we compare, in contrast, include optimizations such as eager message
> protocols and GPU IPC mechanisms [20]. **This results in worse performance
> particularly for small stream-triggered non-ready sends.** Adding and
> assessing the impact of these and other optimizations on CPU-free
> communication performance is a potential direction for future work.

Ordinals carry the structure — *First, … Similarly, … Second, … Third, …
Finally, …*.

Small-paper version:

> These initial results are promising, but more work is needed. Larger-scale
> studies are need to better characterize the cost of this framework at scale.
> Additionally, we are in the process of identifying more algorithms that can
> benefit from this DRAM failure framework.

Negative results about the group's own prior directions are reported plainly:

> While this work resulted in publications and partially supported a graduate
> student who received his Ph.D., **in the end it proved unnecessarily
> complicated for inclusion in Palacios.**

---

## Conclusion

Restates the contributions concretely, with numbers, in the order the paper
presented them. No new framing, no broadening of the claim, no call to action.

Openers are "In this paper we presented…", "In this paper we have presented…",
or the artifact's name:

> In this paper we have presented motivation, design, and implementation of a
> Configurable Messaging Benchmark, the CMB.

**A common construction is the past-tense rewrite of the abstract.** The
conclusion walks the abstract's moves again in the same order, shifting present
to past, and then adds a paragraph of per-configuration numbers the abstract had
no room for. Vernier does this move for move — compare its abstract, quoted in
part, with its conclusion:

> *Abstract:* Understanding the irregular, dynamic communication patterns in HPC
> applications at scale **is** critical when evaluating potential software
> optimizations and hardware architectures. Current systems monitor
> communication behavior for entire applications as exhaustive traces or
> general-purpose aggregated statistics. Generally, these approaches often **do
> not scale** well and the data gathered **is** often too generic or inflexible…
>
> *Conclusion:* Understanding the irregular, dynamic communication patterns in
> HPC applications workloads at scale **was** the critical goal of this paper…
> **We noted that** current systems monitor application communication behavior
> for the entire application as either exhaustive traces or general-purpose
> aggregated statistics. In general, these approaches often **did not scale**
> well and the data gathered **is** often too broad, generic, or inflexible…
> **Therefore, we introduced** a new methodology and tool, the Vernier
> communication performance monitoring system.

Then the numbers, one configuration per sentence, wins and failures in the same
register:

> For the applications studied, the Hierarchical histograms provided exact
> matches to cosine similarity, while increasing the scalability of data
> collection by 1.5×—4.6×. The Combined histograms provided similarity scores of
> 0.984—0.998 for dense communication patterns while increasing the scalability
> of data collection by 2.75×—13.9×, and providing similarity scores of
> 0.52—0.65 for much sparser communication patterns. **The Aggregate histograms
> also performed well on dense communication patterns, achieving similarity
> scores of 0.72—0.93 while having a total reduction in output data volume of
> 63×—152×, but also struggled on sparse communication patterns.**

Nothing requires this rewrite, but when a conclusion is hard to start, walking
the abstract again in past tense is how these papers do it.

> In this paper we presented a cooperative cross-layer application / OS
> framework for recovering from DRAM memory errors. This framework allows the
> application to allocate *failable* memory and provides notification and
> callback mechanisms for failures that occur within these failable allocations.
> We described the fault and recovery model for this framework. Finally, we
> presented initial results of this framework using the new fault-tolerant
> linear solver FT-GMRES, and showed that the solver is able to converge in the
> presence of memory failures.

> As part of Beatnik's development, we have identified multiple test cases, each
> of which exercises a different, important communication feature in modern HPC
> systems. Finally, we have demonstrated both the scalability of Beatnik on
> modern GPU systems and its ability to evaluate the impact of communication
> parameter changes on benchmark performance.

**The conclusion carries the losses too.** This is the habit that most
distinguishes these conclusions from generic ones — the win is quantified
per-case, and the failure follows immediately in the same register:

> Specifically, we showed that for extreme-scale systems where memory failures
> are projected to occur frequently we can exploit similarity to increase
> application performance by more than 45% for HPCCG, 44% for CTH-st and 24% for
> LULESH.
>
> We showed that the libmemprotect imposes very low runtime overhead. For three
> of the applications (CTH-st, HPCCG, and LULESH), we also showed that the memory
> overhead is modest (less than 30%). **However, LAMMPS-lj, LAMMPS-eam, and
> SAMRAI require a substantial increase in memory.**

When conclusion and future work are merged, the future-work half names the
difficulty honestly rather than promising it away:

> The main direction for future work in this area is improving the methodology's
> ability to handle very low-frequency interference sources for applications with
> small BSP intervals. **This case presents a fundamental challenge** due to the
> disparity between scope of the interference being sampled and the granularity
> at which small BSP intervals sample that interference. As a result, directly
> characterizing such interference in these cases is very challenging. We are
> considering two different approaches for addressing this challenge.

Artifact availability belongs here when relevant: "Beatnik's implementation is
open source and available for download from github [3]."
