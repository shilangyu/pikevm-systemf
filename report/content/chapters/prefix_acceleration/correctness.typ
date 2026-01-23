#import "/prelude.typ": *
#import fletcher: *
#import curryst: *

== Correctness <sec:unanchored-pikevm-correctness>

To convince ourselves that the new unanchored PikeVM algorithm is correct, we need a baseline to compare it against. As such, we prove that the result returned by this PikeVM variant is exactly the one defined by our backtracking tree semantics. This in turn implies that we are coherent with the matching semantics defined by ECMAScript. This result has been already established and proven for the original anchored PikeVM in Linden. The original proof is quite involved and lays out an entire pipeline of how to go from a VM executing instructions all the way down to the backtracking tree semantics. In this chapter we outline the most important aspects of that proof pipeline and we refer the reader to Chapter 6 of @linden for all the details. Other than the obvious desire to get a ```rocq Qed.``` on the proof of correctness for our new algorithm, there was a strong motivation to reuse as much as possible of the existing proof infrastructure from the anchored PikeVM. This has been successfully achieved by modifying the anchored PikeVM semantics to be able to operate both in an anchored fashion as well as in an unanchored one. This change of operation mode is achieved purely by picking a different initial state for the PikeVM. Due to this proof engineering effort, the vast majority of the proof pipeline is reused.

We first discuss the technical details that allowed to modify the anchored PikeVM definition to support unanchored matching without losing any of the previous functionality. The PikeVM's state is extended with a single optional parameter which we call ```rocq nextprefix```. It stores three things: the literal $ell$ extracted from the regex, a counter indicating in how many characters the prefix of that literal will match the haystack, and an instance of a substring search algorithm conforming to @lst:substring-search-class. If this triple is not set, the PikeVM will operate in the original anchored mode. The original small-step semantics of the PikeVM#note[Defined in #source-permalink(find-statement("Engine/PikeVM.v", "pike_vm_step"))] are modified to take this new state parameter into account. Most of them remain unchanged, but instead new small-step rules are added to perform the work needed to, 1) simulate the lazy prefix#note[`pvs_nextchar_generate`], 2) perform the filtering optimization#note[`pvs_nextchar_filter`], 3) perform the acceleration optimization#note[`pvs_acc`]. Below we explain which existing rules needed adjustments.

- One of the small-step rules#note[`pvs_match`] was responsible for handling the case when we find a match and therefore store it as our best match so far. This rule must be modified to set `nextprefix` to ```rocq None``` at this point to downgrade the execution to anchored mode. If this was not done, the unanchored PikeVM would continue trying to find matches further down the haystack potentially overwriting the current best match, which would violate the semantics of finding the leftmost match.
- The original rule for advancing the haystack position#note[`pvs_nextchar`] is restricted to only apply in the anchored mode. In unanchored mode, we instead want to use the rule which additionally simulates the lazy prefix / does filtering.
- The original rule for handling the case when there are no active threads nor blocked threads#note[`pvs_final`] is also restricted to only apply in anchored mode. In unanchored mode, we instead want to use the rule which performs the acceleration optimization.

#figure(
  stack(
    spacing: 3em,
    prooftree(
      rule(
        name: smallcaps[Generate],
        ```rocq state.nextprefix = Some (0, lit, search)```,
        ```rocq advance_input state.inp = inp'```,
        ```rocq state.blocked = thr :: blocked```,
        ```rocq state.active = []```,
        align(
          center,
          stack(
            dir: ttb,
            spacing: 0.6em,
            ```rocq state'.inp = inp'```,
            [```rocq state'.active = (thr :: blocked) ++ [initial_thread]``` $quad$ ```rocq state'.blocked = []```],
            ```rocq state'.nextprefix = compute_nextprefix lit search inp'```,
          ),
        ),
      ),
    ),
    prooftree(
      rule(
        name: smallcaps[Filter],
        ```rocq state.nextprefix = Some (S n, lit, search)```,
        ```rocq advance_input state.inp = inp'```,
        ```rocq state.blocked = thr :: blocked```,
        ```rocq state.active = []```,
        align(
          center,
          stack(
            dir: ttb,
            spacing: 0.6em,
            ```rocq state'.inp = inp'```,
            [```rocq state'.active = thr :: blocked``` $quad$ ```rocq state'.blocked = []```],
            ```rocq state'.nextprefix = (n, lit, search)```,
          ),
        ),
      ),
    ),
    prooftree(
      rule(
        name: smallcaps[Accelerate],
        ```rocq state.nextprefix = Some (n, lit, search)```,
        ```rocq advance_input_n (S n) state.inp = inp'```,
        ```rocq state.blocked = []```,
        ```rocq state.active = []```,
        align(
          center,
          stack(
            dir: ttb,
            spacing: 0.6em,
            ```rocq state'.inp = inp'```,
            [```rocq state'.active = [initial_thread]``` $quad$ ```rocq state'.blocked = []```],
            ```rocq state'.nextprefix = compute_nextprefix lit search inp'```,
          ),
        ),
      ),
    ),
  ),
  caption: [The new small-step rules added to the PikeVM to support unanchored matching. `state` is the current state of the PikeVM and `state'` is the resulting state after applying the rule. Unmentioned fields of the state remain unchanged.],
) <fig:pikevm-iductive-rules-unanchored>


With these modifications, we extend the small-step semantics with the following three new rules, visualized in @fig:pikevm-iductive-rules-unanchored

#[
  #set enum(numbering: "1)")

  + To simulate the lazy prefix, whenever `nextprefix` is set and its counter has reached zero, we advance the haystack position by one, move the blocked threads to the active set, and append to the end of the active set a new thread with the label of the initial instruction of the bytecode. We must also recompute the value of the `nextprefix` counter by using the literal and the substring search algorithm stored in `nextprefix`.
  + To perform filtering, whenever `nextprefix` is set and its counter is greater than zero, we advance the haystack position by one, move the blocked threads to the active set, but do not add any new threads. We also decrement the `nextprefix` counter by one.
  + To perform acceleration, whenever `nextprefix` is set and there are no active nor blocked threads, we use the substring search algorithm stored in `nextprefix` to skip ahead in the haystack to the next potential match position. We reinitialize the active set with a single thread with the label of the initial instruction of the bytecode. We also recompute the value of the `nextprefix` counter.
]

The new unanchored PikeVM has an executable functional version#note[Defined in #source-permalink(find-statement("Engine/FunctionalPikeVM.v", "pike_vm_match_unanchored"))] which is proven to follow exactly the small-step semantics#note[Proven in #source-permalink(find-statement("Engine/FunctionalPikeVM.v", "pike_vm_match_correct_unanchored"))].

With this setup we now discuss the essential aspects of the proof pipeline and how it is adjusted to accommodate the unanchored PikeVM. The main task is to adjust all of the proofs that performed any kind of case analysis on the small-step semantics of the PikeVM to these new rules. Additionally, all lemmas that stated something with regards to the initial state of the PikeVM have been duplicated to state the analogous thing for the unanchored initial state#note[These analogous lemmas are found next to the original one with a suffix of `_unanchored`]. Otherwise, other theorems are fully reused without any changes. The challenge of proving the correctness of the PikeVM stems from its vastly different execution order and that it executes bytecode rather than operating on backtracking trees.

To bridge this gap, the existing proof pipeline goes through an intermediate engine called the _PikeTree_ which sits somewhere between backtracking trees and the execution scheme of the PikeVM. Given a backtracking tree, the PikeTree explores it non-deterministically in an order analogous to the PikeVM. The PikeTree starts with the backtracking tree of the regex and haystack on which we are operating. It is the initial value of the active set of the PikeTree; instead of storing threads with bytecode labels, the PikeTree stores backtracking subtrees. The PikeTree then explores this tree in the same order as the PikeVM would explore its NFA, producing new subtrees in its active and blocked set along the way. The match-equivalence between the PikeTree and the backtracking trees is achieved through showing that as the PikeTree explores the backtracking tree, it maintains an invariant that the result from the PikeTree state remains the same#note[Initialization: #source-permalink(find-statement("Engine/PikeTree.v", "init_piketree_inv_unanchored")), Preservation: #source-permalink(find-statement("Engine/PikeTree.v", "pts_preservation"))]. Then, to prove the match-equivalence between the PikeVM and the PikeTree, we show that there exists a particular execution trace of the PikeTree which corresponds to the execution trace of the PikeVM. We show this correspondence by relating individual parts of the state of the PikeVM to the one of the PikeTree through a simulation invariant#note[Initialization: #source-permalink(find-statement("Engine/PikeEquiv.v", "initial_pike_inv_unanchored")), Preservation: #source-permalink(find-statement("Engine/PikeEquiv.v", "invariant_preservation"))].

With that simplified view of the already existing proof pipeline in mind, we now present the changes that were needed to retrofit unanchored matching to the PikeTree as well.

=== The unanchored PikeTree

We modify the small-step semantics of the PikeTree to accommodate unanchored matching in a similar fashion as we did for the PikeVM. PikeTree is not meant to be an executable or realistic engine, but merely a proof artifact. Its construction is already exponential and its execution is non-deterministic. We can use the non-determinism to our advantage, it allows for simpler modifications and abstractions. In the end, we only require that there exists an execution trace that will correspond to that of the PikeVM.

Firstly, we add a new parameter to the state of the PikeTree called `future`. It corresponds to PikeVM's `nextprefix`, but is simpler as it only stores a single backtracking subtree. When wanting to perform unanchored matching of the regex $r$ on the haystack $s$, the initial value of `future` is set to be the subtree corresponding to the right branch of the backtracking tree of ```re /[^]*?r/``` over $s$. We visualize the initial state of the unanchored PikeTree in @fig:unanchored-piketree-init.

#let active-set-color = rgb("FFC20A")
#let future-color = rgb("0C7BDC")

#figure(
  diagram(
    spacing: (1.5em, 2em),

    node((0, 0), name: <root>),

    // left
    node((-1, 1), [Tree of ```re /r/``` at position 0 of $s$], name: <left>),
    edge(<root>, <left>),

    // right
    node((1, 1), [`Consume` any character], name: <consume>),
    edge(<root>, <consume>),
    node((1, 2), [Tree of ```re /[^]*?r/``` at position 1 of $s$], name: <right>),
    edge(<consume>, <right>),

    {
      let box(name, c, enclose, label, anchor) = {
        node(
          enclose: enclose,
          stroke: (paint: c, dash: "dashed"),
          fill: rgb(..c.components().slice(0, 3), 5%),
          inset: 8pt,
          corner-radius: 3pt,
          name: label,
        )
        node((rel: (0pt, 1em), to: (name: label, anchor: anchor)), text(fill: c, weight: "bold", name))
      }
      box("Active set", active-set-color, <left>, <box-left>, "north")
      box("Future", future-color, (<consume>, <right>), <box-right>, "north")
    },
  ),
  caption: [Backtracking tree of ```re /[^]*?r/``` over a haystack $s$. #text(active-set-color)[Left subtree] is the initial active set tree, #text(future-color)[right subtree] is the initial `future` subtree.],
) <fig:unanchored-piketree-init>

During execution, the `future` tree will be used to simulate the lazy prefix. This `future` subtree is crucial for the PikeTree to be able to attempt matches at positions further down the haystack. Each time we want to simulate the lazy prefix, we remove the `Consume` node from the `future` subtree which leaves us with a tree of the same shape as in @fig:unanchored-piketree-init, but with the backtracking trees representing regexes at the next haystack position. We then set the new right subtree (which is a `Consume` followed by the tree of ```re /[^]*?r/``` at the next haystack position) as the new `future` and append the new left subtree (which is the tree of ```re /r/``` at the next haystack position) to the active set. This way, we allow the PikeTree to explore matches in the haystack positions that follow. When doing filtering, we do the same unfolding but we discard the new left subtree instead of appending it to the active set.

#let lazy-iter = {
  set text(size: 8pt)

  diagram(
    spacing: 1em,
    node((0, 0), name: <root>),

    // left
    node((-1, 1), [`t1`], name: <left>),
    edge(<root>, <left>),

    // right
    node((1, 1), [`Consume c`], name: <consume>),
    edge(<root>, <consume>),
    node((1, 2), [`t2`], name: <right>),
    edge(<consume>, <right>),
  )
}


#figure(
  stack(
    spacing: 3em,
    prooftree(
      rule(
        name: smallcaps[Generate],
        align(horizon, stack(dir: ltr, ```rocq state.future = ```, lazy-iter)),
        ```rocq advance_input state.inp = inp'```,
        ```rocq may_erase t2 = future'```,
        ```rocq state.blocked = tgm :: blocked```,
        ```rocq state.active = []```,
        align(
          center,
          stack(
            dir: ttb,
            spacing: 0.6em,
            [```rocq state'.inp = inp'``` $quad$ ```rocq state'.future = future'```],
            [```rocq state'.active = (tgm :: blocked) ++ [t1]``` $quad$ ```rocq state'.blocked = []```],
          ),
        ),
      ),
    ),
    prooftree(
      rule(
        name: smallcaps[Filter],
        align(horizon, stack(dir: ltr, ```rocq state.future = ```, lazy-iter)),
        ```rocq advance_input state.inp = inp'```,
        ```rocq state.blocked = tgm :: blocked```,
        ```rocq state.active = []```,
        ```rocq first_leaf t1 = None```,
        align(
          center,
          stack(
            dir: ttb,
            spacing: 0.6em,
            [```rocq state'.inp = inp'``` $quad$ ```rocq state'.future = t2```],
            [```rocq state'.active = tgm :: blocked``` $quad$ ```rocq state'.blocked = []```],
          ),
        ),
      ),
    ),
    prooftree(
      rule(
        name: smallcaps[Accelerate],
        ```rocq tree_acceleration inp future = (inp', acc, t)```,
        ```rocq may_erase acc = future'```,
        ```rocq state.blocked = []```,
        ```rocq state.active = []```,
        align(
          center,
          stack(
            dir: ttb,
            spacing: 0.6em,
            [```rocq state'.inp = inp'``` $quad$ ```rocq state'.future = future'```],
            [```rocq state'.active = [t]``` $quad$ ```rocq state'.blocked = []```],
          ),
        ),
      ),
    ),
  ),
  caption: [The new small-step rules added to the PikeTree to support unanchored matching. `state` is the current state of the PikeTree and `state'` is the resulting state after applying the rule. Unmentioned fields of the state remain unchanged.],
) <fig:piketree-iductive-rules-unanchored>

By having added the `future` state parameter, we now explain how it is used to create steps analogous to the new ones in the unanchored PikeVM. These rules are visualized in @fig:piketree-iductive-rules-unanchored. The PikeTree does not have access to the literal of regex we are executing nor does it have access to a substring search algorithm. The lack of it is not an issue, as we replaced it by having non-deterministic steps in the PikeTree semantics#note[In fact, the choice of not including the literal and substring searches in the PikeTree was intentional. This way, it describes a broader class of optimizations that perform filtering and acceleration for potentially various reasons.]. In the unanchored PikeVM, we simulated the lazy prefix only when it was necessary, namely when the counter of `nextprefix` reached zero indicating that the literal's prefix matches at that position. However, for correctness' sake, there is no issue in simulating the lazy prefix at every haystack position. Thus, for the PikeTree, the small-step rule responsible for simulating the lazy prefix#note[`pts_nextchar_generate`] can be applied non-deterministically together with the filtering rule#note[`pts_nextchar_filter`]. The only condition that is imposed on the filtering step is that we cannot filter out a subtree from `future` that did contain a successful match. This restriction does not prevent us from applying the lazy prefix simulation step even when that subtree contains no matches. Without having access to a literal or a substring search algorithm, this non-determinism is essential. We cannot make this choice deterministic by choosing to always filter whenever the `future` subtree contains no matches. Doing so would encode an execution strategy that takes ideal decisions. But the PikeVM's filtering rule is only an under-approximation of such an ideal strategy. The PikeVM may very well not filter out a position where a match is not present. Thus, this non-determinism allows us to say that there exists a trace of choices made by the PikeTree that corresponds to the concrete decisions made by the PikeVM. We must address one final discrepancy. In the PikeVM, the lazy prefix simulation step was recomputing the `nextprefix`. This recalculation could lead to setting `nextprefix` to ```rocq None``` (no more occurrences found). Our unfolding of the `future` tree does not have this capability. To remedy this, we define a non-deterministic relation ```rocq may_erase``` which can turn any tree into either itself or into ```rocq None```. We allow turning a tree into ```rocq None``` under the sole condition that this tree does not contain any successful matches. This relation can be seed in @lst:may-erase.

#linden-listing(
  "Engine/PikeTree.v",
  "may_erase",
)[Definition of the non-deterministic relation which erase trees.] <lst:may-erase>

We add this ability of erasing the new `future` tree to the lazy prefix simulation step. The trace of the PikeTree which corresponds to the PikeVM is such that whenever the PikeVM would recompute the `nextprefix` to ```rocq None```, `may_erase` will erase the `future` tree in the PikeTree. Having handled PikeTree's lazy prefix and filtering steps, we now turn to the acceleration step#note[`pts_acc`]. To perform acceleration, we want to be able to non-deterministically perform this unfolding of `future` multiple times, where each unfold is under the condition that the tree we are discarding does not contain any successful matches. To model this, we define a non-deterministic relation ```rocq tree_acceleration```#note[Defined in #source-permalink(find-statement("Engine/PikeTree.v", "tree_acceleration")) ] which takes as input the current haystack position and the `future` tree. It returns a new haystack position to which we have non-deterministically unfolded `future`, the ```re /r/``` subtree `t` at that position, and the ```re /[^]*?/``` subtree `future'` at that position. We set the new active set to be the singleton of `t`. The new `future` is the `may_erase` of `future'` for the same reason as before: after acceleration, the PikeVM can potentially recompute the `nextprefix` to be ```rocq None```. The execution trace which corresponds to the PikeVM is such that the we unfold the `future` tree the same amount of times as the value of the counter in PikeVM's `nextprefix`.

With these modifications, we have adapted the PikeTree to support unanchored matching. There is a clear correspondence between the new small-step rules of the unanchored PikeVM and the ones of the unanchored PikeTree. As for the PikeVM, the new rules for the PikeTree required adjusting existing proofs that performed case-analysis on the small-step semantics. We also duplicate all of the lemmas mentioning the initial state of the PikeTree to separately state the analogous thing about the unanchored initial state#note[These analogous lemmas are found next to the original one with a suffix of `_unanchored`]. The remaining proofs did not require any changes.

We conclude this section by briefly discussing the new simulation invariant that relates PikeVM's `nextprefix` to PikeTree's `future`. Firstly, to support the anchored modes of both engines, we state that PikeVM's `nextprefix` is ```rocq None``` if and only if PikeTree's `future` is ```rocq None```. Secondly, when both are set, we relate the counter in `nextprefix` to the number of left subtrees in `future` containing no successful matches. This invariant is indeed preserved; the `nextprefix` counter is initialized to the distance from the next occurrence of a literal. We know that for all haystack positions before that occurrence, there can exist no match. Therefore, the subtree most certainly also contains no successful matches.

This large bulk of work culminates in the main theorem stating the match-equivalence between the unanchored PikeVM and the backtracking tree semantics.

#linden-theorem("Engine/Correctness.v", "pike_vm_correct_unanchored", proof: [
  By transitivity of match-equivalence through the unanchored PikeTree.
]) <thm:pikevm-correctness-unanchored>
