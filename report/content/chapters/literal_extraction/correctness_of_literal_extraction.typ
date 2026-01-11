#import "/prelude.typ": *

== Correctness of literal extraction <sec:literal-extraction-correctness>

We now prove that the extracted literals correctly describe the matches of a regex. The properties which we care about are those which will allow us to accelerate regex matching. For that, we will consider each literal variant separately. For ```rocq Prefix s```, we want to show that any match of a regex $r$ whose literal is ```rocq Prefix s``` must start with the string $s$. Through the contrapositive (if a match does not start with $s$, it is not a match of $r$) we will be able to do prefix acceleration by skipping haystack positions where $s$ does no occur. For ```rocq Impossible```, we want to show that no match of $r$ whose literal is ```rocq Impossible``` can exist. This will allow us to immediately say that for such a regex and any haystack, there is no match. Finally, for ```rocq Exact s```, we want to show that any match of a regex $r$ whose literal is ```rocq Exact s``` is exactly the string $s$. This will allow us to skip running regex engines entirely and just use a much faster substring search.

=== Correctness of ```rocq Prefix``` literals

#TODO[Correctness of ```rocq Prefix``` literals]

=== Correctness of ```rocq Impossible``` literals

#TODO[Correctness of ```rocq Impossible``` literals]

=== Correctness of ```rocq Exact``` literals

#TODO[Correctness of ```rocq Exact``` literals]
