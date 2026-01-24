#import "/prelude.typ": *
#import fletcher: *
#import curryst: *

== Backtracking trees <sec:backtracking-trees>

The precise semantics on which we operate are defined by _backtracking trees_. A backtracking tree describes all possible ways one can match a regex against a concrete haystack during backtracking matching if we were to not stop as soon as we found a match. The nodes of this tree represent choices, assertions, setting values of the captures, consumption of a character. Two special nodes `Match` and `Mismatch` indicate that this exploration path has led to a match and mismatch respectively. These nodes can only ever be leaves of the tree. Once we materialize a tree for some regex and haystack, we say that the result of matching is the path from the root of the tree to the leftmost `Match` leaf. If no such leaf exists, the matching has no result.

#let ex-r = ```re /a(?:b|c)t+/```
#let ex-hay = hay.with("abcttt")

Haystacks in Linden are represented by the `input` type#note[Defined in #linden-permalink(linden-statement("Semantics/Chars.v", "input"))] and additionally encode the current position within it. This is done by storing the characters that are ahead of us as well as the reverse of the characters before us. For example, if we wish to write the positioned haystack #ex-hay(position: 4) as the `input` type, it would be ```rocq Input "tt" "tcba"```.

To track the values of captures, Linden stores them in a `group_map`#note[Defined in #linden-permalink(linden-statement("Semantics/Groups.v", "group_map"))]. A `group_map` is a mapping from capture indices to optional pairs of positions within the haystack. A pair of positions indicates the start and end of the substring captured by the corresponding capture. An unset capture is represented by `None`.

In Linden, the backtracking tree is represented by the `tree`#note[Defined in #linden-permalink(linden-statement("Semantics/Tree.v", "tree"))] inductive. To create a backtracking tree for some regex and haystack, we use the `is_tree` relation#note[Defined in #linden-permalink(linden-statement("Semantics/Semantics.v", "is_tree"))]. Finally, to traverse the tree to find the leftmost match, we use the `tree_res`#note[Defined in #linden-permalink(linden-statement("Semantics/Tree.v", "tree_res"))] (sometimes abstracted to the wrapper function `first_leaf`#note[Defined in #linden-permalink(linden-statement("Semantics/Tree.v", "first_leaf"))]). These traversing functions return an optional `leaf` type#note[Defined in #linden-permalink(linden-statement("Semantics/Tree.v", "leaf"))], which is simply a new `input` indicating where the match ends and the resulting `group_map`.

Theorems will be stated in terms of these definitions, thus we dedicate the next paragraphs to illustrating each with an example.

```rocq is_tree [Areg r] inp gm forward tr``` $thick$ states that `tr` is the backtracking tree for the regex `r` and haystack `inp` with an initial group map `gm` (all captures unset), in the forward direction. The direction is needed to encode lookbehinds. It is safe to ignore this parameter in our definitions, as we will not be dealing with them. The interesting looking ```rocq [Areg r]``` is a singleton list of a so called `action`#note[Defined in #linden-permalink(linden-statement("Semantics/Semantics.v", "action"))]. To relate a regex and input to a tree, the `is_tree` relation operates on a list of actions. The `Areg r` action instructs the `is_tree` relation to construct a tree for the regex `r`. Such an action can potentially produce two new actions. Consider the regex `Sequence r1 r2`. The `tree_sequence` rule of the `is_tree` inductive will produce two new actions to handle each regex one after the other: ```rocq [Areg r1, Areg r2]```#note[If the direction is `backwards`, the order of these two actions would be swapped]. The remaining kinds of actions are not relevant to our discussion, hence we omit them.

Now that we have `tr`, we can extract the ```rocq option leaf``` from it using ```rocq tree_res tr GroupMap.empty inp forward``` or equivalently ```rocq first_leaf tr inp```. The group map we provide is the initial value for the traversal. During it, the group map will be populated with the values of the captures as they are encountered in the tree.

We conclude this discussion by showing two concrete rules of the `is_tree` relation to give better intuition about how trees are constructed. We omit the group map and the direction. Consider the rule for the ```re +``` and for a successful character descriptor match:

#{
  set text(size: 10pt)
  set align(center)

  prooftree(rule(
    name: smallcaps[Plus],
    ```rocq is_tree (Areg r1 :: Areg (Quantified greedy 0 Inf r1) :: cont) inp titer```,
    ```rocq is_tree (Areg (Quantified greedy (S 0) Inf r1) :: cont) inp titer```,
  ))

  prooftree(rule(
    name: smallcaps[Star],
    ```rocq read_char cd inp = Some (c, inp')```,
    ```rocq is_tree cont inp' tcont```,
    ```rocq is_tree (Areg (Character cd) :: cont) inp (Read c tcont)```,
  ))
}
