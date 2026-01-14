#import "/prelude.typ": *

== Correctness of literal extraction <sec:literal-extraction-correctness>

We now prove that the extracted literals correctly describe the matches of a regex. The properties which we care about are those which will allow us to accelerate regex matching. For that, we will consider three useful properties separately. For any literal whose prefix (@lst:prefix) is `s`, we want to show that any match of a regex $r$ must start with the string $s$. Through the contrapositive (if a match does not start with $s$, it is not a match of $r$) we will be able to do prefix acceleration by skipping haystack positions where $s$ does no occur. For ```rocq Impossible``` literals, we want to show that no match of $r$ whose literal is ```rocq Impossible``` can exist. This will allow us to immediately say that for such a regex and any haystack, there is no match. Finally, for ```rocq Exact s``` literals, we want to show that any match of a regex $r$ whose literal is ```rocq Exact s``` is exactly the string $s$. This will allow us to skip running regex engines entirely and just use a much faster substring search.

We want the theorems to be stated in terms of the #TODO[```rocq is_tree``` inductive][Reference the definition in background section], preferably talking about a specific regex, ie. ```rocq is_tree [Areg r]```. Recall, however, that some of its rules such as the ```rocq tree_sequence``` rule talk about more than just the head of the tree actions. That means that in the proofs during induction over ```rocq is_tree``` if we do not generalize over the entire list of tree actions, we will get stuck on those rules. To avoid this, we generalize literal extraction over an action and a list of actions in @lst:extract-literal-actions and state the theorems in terms of these.

#linden-listing("Engine/Prefix.v", (
  "extract_action_literal",
  "extract_actions_literal",
))[] <lst:extract-literal-actions>

For ```rocq extract_action_literal``` we return ```rocq Nothing``` for the non-regex actions since they do not consume any characters from the input. For ```rocq extract_actions_literal```, we chain the literals of each action. When the list of actions is empty, we return the same literal as we would for $epsilon$, ```rocq Nothing```. The choice of chaining becomes apparent when we look again at the ```rocq tree_sequence``` rule: ```rocq is_tree (Areg (Sequence r1 r2) :: cont)``` holds if ```rocq is_tree (Areg r1 :: Areg r2 :: cont)```#note[This is when the direction is `forward`. When the direction is `backward`, the condition is ```rocq is_tree (Areg r2 :: Areg r1 :: cont)```, leading to the same illustration of the argument.] does.

With those definitions in place, we can now state the correctness theorems for each literal variant.

=== Correctness of the prefix of literals

We first want to state the correctness lemma of ```rocq extract_literal_char```. We want to say that given a character descriptor `cd` and a character `c` that matches it, the extracted literal from `cd` is the prefix of `c`. This is formalized by @thm:correctness-extract-literal-char. In that statement we additionally generalize over the tail of the string where `c` is the head of it. Since the `ignoreCase` flag was not checked in ```rocq extract_literal_char```, we additionally add it to our hypotheses.

#linden-theorem("Engine/Prefix.v", "chain_literals_extract_char", proof: [
  We induct on `cd` yielding cases for each character descriptor. Cases for which ```rocq extract_literal_char cd = Unknown``` are immediately true because
  $
    & #```rocq starts_with (prefix (chain_literals Unknown rest)) (c :: s)``` \
    & quad ~> #```rocq starts_with (prefix Unknown) (c :: s)``` \
    & quad ~> #```rocq starts_with "" (c :: s)``` \
    & quad ~> #```rocq True``` \
  $
  Where the last reduction follows from the base constructor of @lst:starts-with.
  We now consider the remaining four cases.

  1. *CdEmpty*. ```rocq extract_literal_char CdEmpty = Impossible```, and so similarly as above we have

  $
    & ~> #```rocq starts_with (prefix Impossible) (c :: s)``` \
    & ~> #```rocq starts_with "" (c :: s)``` \
    & ~> #```rocq True``` \
  $

  2. *CdSingle*. ```rocq extract_literal_char (CdSingle c') = Exact [c']```. But since ```rocq char_match rer c (CdSingle c')``` holds and the match is case-sensitive, we have ```rocq c = c'```. Now by case analysis of `rest`,
    1. ```rocq rest = Impossible```, which once again leads to ```rocq starts_with "" (c :: s)```
    2. ```rocq rest = Prefix p```,  leads to

    $
      & #```rocq starts_with (prefix (chain_literals (Exact [c]) (Prefix p))) (c :: s)``` \
      & quad ~> #```rocq starts_with (prefix (Prefix (c :: p))) (c :: s)``` \
      & quad ~> #```rocq starts_with (c :: p) (c :: s)``` \
    $
    which holds true by the inductive constructor of @lst:starts-with and by the hypothesis ```rocq starts_with p s```.

    3. ```rocq rest = Exact p```, leads to
    $
      & #```rocq starts_with (prefix (chain_literals (Exact [c]) (Exact p))) (c :: s)``` \
      & quad ~> #```rocq starts_with (prefix (Exact (c :: p))) (c :: s)``` \
      & quad ~> #```rocq starts_with (c :: p) (c :: s)``` \
    $
    which holds true by the same reasoning as above.

  3. *CdRange*. ```rocq extract_literal_char (CdRange c1 c2) = Exact [c1]```, which implies ```rocq c1 = c2```. By ```rocq char_match rer c (CdRange c1 c1)``` and case sensitivity we get that ```rocq c1 = c```. We conclude similarly as in the *CdSingle* case.

  4. *CdUnion*. ```rocq extract_literal_char (CdUnion cd1 cd2) = merge_literals (extract_literal_char cd1) (extract_literal_char cd2)```. By transitivity of ```rocq starts_with``` through ```rocq prefix (chain_literals (extract_literal_char cd1) rest)``` or ```rocq prefix (chain_literals (extract_literal_char cd2) rest)``` (depending on which branch of the union matched `c`), and by the induction hypotheses on `cd1` and `cd2`, we conclude. #TODO[Maybe also add starts_with_chain_merge_literals lemma into the report?]
]) <thm:correctness-extract-literal-char>

With that lemma we can now state and prove the general theorem about the correctness of the prefix of extracted literals for regexes. Given a tree `tree` of actions `acts` over the input `inp`, if `tree` contains a match then `inp` starts with the prefix of the literal extracted from `acts`.

#linden-theorem("Engine/Prefix.v", "extract_literal_prefix_general", proof: [
  We induct on the ```rocq is_tree``` hypothesis. We can immediately assume regex matching is case-sensitive, otherwise the extracted prefix is the empty string and the theorem holds trivially. Similarly, for every case where ```rocq extract_actions_literal acts``` is ```rocq Unknown``` or ```rocq Impossible```, the theorem holds. Additionally all rules which lead to a mismatch (like ```rocq tree_char_fail```) are immediately a contradiction with the match hypothesis. We now focus on the remaining cases which do not follow immediately from the induction hypotheses.

  1. *`tree_char`.* So we have that `char_match c cd`. We conclude by @thm:correctness-extract-literal-char and the induction hypothesis.
  2. *`tree_disj`.* By transitivity of ```rocq starts_with``` through ```rocq prefix (chain_literals (extract_literal r1) (extract_actions_literal cont))``` or ```rocq prefix (chain_literals (extract_literal r2) (extract_actions_literal cont))``` (depending on which branch of the tree contains the result), and by the induction hypotheses, we conclude. #TODO[Maybe also add starts_with_chain_merge_literals lemma into the report?]
  3. *`tree_quant_forced`.* When $m i n = 0$ in the quantifier, the result follows from the induction hypothesis. Otherwise we with the help of @thm:starts-with-app-left this also follows from the induction hypothesis.
]) <thm:correctness-extract-literal-prefix-general>

#linden-theorem("Engine/Prefix.v", "starts_with_app_left", proof: [By induction over `s1`.]) <thm:starts-with-app-left>

#TODO[Correctness of prefix literals]

=== Correctness of ```rocq Impossible``` literals

#TODO[Correctness of ```rocq Impossible``` literals]

=== Correctness of ```rocq Exact``` literals

#TODO[Correctness of ```rocq Exact``` literals]
