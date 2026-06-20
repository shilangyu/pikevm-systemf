# Verification of realistic regex matching

> Modern regular expressions (regexes) are a powerful tool for finding patterns in text. Modern features such as capturing groups, lookarounds, and backreferences turn the problem of matching into a complex and error-prone task. Real-world implementations additionally employ a large variety of optimizations and heuristics to speed up matching in practice. In this work we don’t shy away from this complexity but instead tame it by providing a formalization of realistic regex matching that includes all of the cumbersome aspects. In the Rocq proof assistant, we provide the formalization and proof of correctness of a prefix acceleration optimization in the PikeVM. We additionally formalize optimizations such as anchored regexes and impossible matches. We combine all of them to produce a realistic matching algorithm which is proven to return matches defined by the ECMAScript 2023 standard.

This repository documents my master thesis at [EPFL](https://www.epfl.ch) in the [SYSTEMF lab](https://systemf.epfl.ch).

Supervised by [Aurèle Barrière](https://aurele-barriere.github.io) and [Clément Pit-Claudel](https://pit-claudel.fr/clement).

See [here](http://github.shilangyu.dev/pikevm-systemf/) for all the compiled documents. Notably, [the final thesis PDF](https://github.shilangyu.dev/pikevm-systemf/report/final.pdf). This project mainly involved working in the following repos:

- [Linden formalization](https://github.com/LindenRegex/Linden)
- [Rust's regex](https://github.com/rust-lang/regex)
- [Regex benchmarking suite](https://github.com/BurntSushi/rebar/)

## Repository structure

### `./proposal`

The presentation and textual proposal of the project before work has begun on it.

### `./meeting_notes`

Weekly notes taken for progress tracking and for recording action items from meetings with my supervisors.

### `./progress_presentation`

Script and graphics used for a progress presentation.

### `./report`

The written report of the entire project. See [the GitHub action](./.github/actions/report/action.yml) for instructions on how to lint and compile the report.

### `./final_presentation`

The presentation used for my thesis defense and shorter versions for PhD interviews or invited talks.

### `./public`

The deployed website of this thesis.
