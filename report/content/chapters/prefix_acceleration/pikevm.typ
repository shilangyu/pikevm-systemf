#import "/prelude.typ": *
#import "data.typ": *

#show: setup

== The PikeVM <sec:pikevm>

In this work we have emphasized several times the importance of linear engines and why they are of interest to us. One such engine that has become ubiquitous in practical implementations of linear regex engines is the PikeVM @pikevm. For a regex $r$ and a haystack $s$, it has a runtime complexity of $O(|r| dot |s|)$ and a space complexity of $O(|r|)$. It is implemented by popular libraries such as #TODO[`rust-regex`, RE2, V8, or Golang][cite each engine?]. Some of these libraries additionally implement other linear engines which tend to perform better on specific classes of regexes and haystacks, but have a drawback of either not supporting all of the desired regex features or having a worse space complexity. Consider, for example, a different popular linear engine called the memoized backtracker. In various benchmarks it outperforms the PikeVM, but it incurs a higher space complexity of $O(|r| dot |s|)$ which makes it impractical for large haystacks. Another example is the LazyDFA engine which also outperforms the PikeVM, but currently there is no known way to incorporate support for capture groups into it. Hence, the PikeVM is still the fallback engine of choice in those libraries. The following section presents how the PikeVM searches for matches.


==== Compilation
Before the PikeVM can execute a regex $r$ on any haystack $s$, the PikeVM first compiles the regex down into a bytecode representation. This bytecode is a sequence of instructions that represent the operations needed to perform matching. It describes the exploration of the NFA corresponding to the regex $r$. Each instruction has a label that uniquely identifies it within the bytecode.
// TODO: mention the below?
// While the bytecode aspect is very important to the formalization of the PikeVM and posed challenges solved in @linden, it is not directly relevant to our work on prefix acceleration. Hence, here we will focus on the visual NFA representation of regexes which will aide in understanding the execution of the PikeVM.

==== Execution
#let recall-r-src = "aa|aab"
#let recall-r = raw(lang: "re", "/" + recall-r-src + "/")
Once we have the bytecode, we can execute it on a particular haystack $s$. The execution proceeds by simulating the exploration of the NFA using the bytecode. To track its progress, the PikeVM maintains a state containing so-called _"threads"_. Each thread is essentially a bytecode label that can be thought of as a @program-counter:intro. All threads are synchronized to the same position in $s$. The threads that are currently exploring this position in the haystack are stored in an _"active set"_. Since our backtracking semantics have a notion of priority, the active set is a list ordered by highest priority. To recall, the regex #recall-r produces a match of #hay(match: regex(recall-r-src))[zaab], where the last #hay[b] is not included because the first alternative of the disjunction matches first. So during exploration, the thread corresponding to the first alternative is ordered before the thread corresponding to the second alternative in the active set. Whenever performing work on an active thread, it can lead to three situations.

+ Since all active threads are synchronized to the same position in the haystack, as soon as an active thread needs to advance to the next character, it is transferred to a _"blocked set"_ that is similarly ordered by priority.
+ A thread might complete a unit of work and indicate that more work needs to be done by producing a list of new threads that should be prepended to the active set. For example, if a thread is executing the bytecode responsible for performing a disjunction, it will produce two new threads, one for each branch. To indicate that a thread failed to match (for example due to expecting to see #hay[z] at #hay(position: 2)[zaab]), it can produce an empty list of new threads, effectively ending the thread.
+ As soon as an active thread reaches the accepting state of the NFA, it dies and produces the current _"best match"_ to be stored in the PikeVM's state. The best match represents the current highest priority match found so far. Since we are interested in leftmost semantics, storing the best match so far allows us to wait for a potentially higher priority match to be found later. Notably, a higher priority match can be produced from threads that are currently in the blocked set.

Finally, there is one additional item in the state of a PikeVM: a _"seen set"_. The seen set stores labels of instructions which have already been executed at the current haystack position. A thread is discarded when it revisits one of those labels. This caching is crucial for giving the PikeVM a linear runtime.

We can now summarize the execution of the PikeVM. It repeatedly performs work on the active set until it is exhausted. If the blocked set is empty, it returns the best match found so far. Otherwise, it advances the haystack position by one and transfers the blocked set into the new active set. We illustrate this execution model with an example trace seen in @fig:pikevm-execution. For ease of understanding, we visualize the NFA as a simplified state machine instead of bytecode instructions. The nodes annotated with Greek letters represent the labels and the arrows are annotated with the characters they expect to see in the current haystack position. When relevant, we indicate the priority of the arrows with the smallest number being the highest priority.

#let trace = {
  set par(leading: 0.3em)

  table(
    columns: (7em, 7em, auto),
    stroke: none,
    inset: 7pt,
    align: left,

    table.vline(x: 1, stroke: 1.5pt),

    table.header(
      [#set align(center)
        *Active*],
      [#set align(center)
        *Blocked*],
      [],
    ),

    ..trace-advance(0),
    [$[alpha]$],
    [$[thin]$],
    [We initialize the search from the beginning of the haystack and set the active set to the singleton containing the initial node of the NFA.],
    [$[thin]$],
    [$[beta]$],
    [The $alpha$ thread successfully matches #hay[a]. It produces a new $beta$ thread which must wait for the haystack to be advanced.],

    ..trace-advance(1),
    [$[beta]$],
    [$[thin]$],
    [Since we are out of active threads, we advance the haystack and transfer the blocked set into the new active set.],
    [$[thin]$], [$[gamma, lambda]$],
    [The $beta$ thread can match #hay[b] by means of two different transitions. It produces two new blocked threads, $gamma$ and $lambda$. These are produced in the order of priority.],

    ..trace-advance(2),
    [$[gamma, lambda]$],
    [$[thin]$],
    [We are out of active threads again, so we advance the haystack and transfer the blocked set into the new active set.],
    [$[lambda]$],
    [$[thin]$],
    [We handle the head of the active set, the $gamma$ thread. Its only transition is one that expects to see the character #hay[w]. Since it fails to match, it produces no new threads and effectively dies.],
    [$[thin]$],
    [$[thin]$],
    [The same fate awaits the $lambda$ thread which expects to see #hay[e]. We are out of active and blocked threads, we have found no match!],
    table.cell(colspan: 2, align: center)[*No match!*], [],
  )
}

#wideblock[
  #figure(
    grid(
      columns: (auto, auto),
      gutter: 1em,
      ex-r-nfa, trace,
    ),
    supplement: "Figure",
    caption: [Left: the NFA of the regex #ex-r. Right: execution trace of the PikeVM on #s().],
  ) <fig:pikevm-execution>
]

Despite a match existing at the tail end of the exemplified haystack, no match is found due to the PikeVM being inherently an anchored engine. In the next section we will devise a way to turn it into an unanchored engine all whilst integrating prefix acceleration.

// TODO: mention this only once it becomes relevant
// ==== The PikeVM in Linden
// We briefly detail how the PikeVM is formalized in Linden. The compilation is done by the ```rocq compilation : regex -> code``` function. We formalize the execution model through small-step semantics defined by ```rocq pike_vm_step : code -> pike_vm_state -> pike_vm_state```. The expression ```rocq pike_vm_step code pvs1 pvs2``` states that for some bytecode `code` and an input state `pvs1`, the PikeVM transitions into the state `pvs2`.
