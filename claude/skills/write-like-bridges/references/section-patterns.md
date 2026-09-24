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

**Paragraph 4 — contributions.** See the main SKILL.md. Introduced with
*Specifically*; bullets are noun phrases; cross-reference sections.

**Optional paragraph 5 — roadmap.** One sentence, appended after the
contribution list, covering only the sections the list did not:

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

**Experimental setup** is written so a reader could rerun it. Machines are
described in hardware detail; software versions are tabulated; configuration
choices are justified, including choices made on someone else's advice.

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

Claims about coverage of the literature are explicitly bounded:

> Of the MPI GPU-triggered communication implementations, **we are aware of only
> two that** attempt to provide CPU-free communication…

Novelty claims are bounded by what the authors know rather than asserted
absolutely:

> The work described in this paper is **the first of which we are aware** that
> provides an analytical underpinning to studies of emerging HPC application
> interference…

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

Gets its own section, usually titled *Limitations and Directions for Future
Work*. The framing sentence makes explicit that future work addresses *this
paper's* limitations:

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
