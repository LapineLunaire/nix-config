# Configuration guidance

## Writing

- Document only what applies now, including in this file. Git keeps the history.
- Delete comments, documentation, and decisions that no longer apply. Do not keep or rewrite them just to explain the past.
- Use plain, familiar words in comments, documentation, and replies. Everything should be easy to read and understand.
- Keep comments and documentation short and useful.
- There is no 80-character line limit for code, comments, or documentation. Break lines where it helps readability.
- Explain choices and limitations that are not clear from the code.
- Leave out comments that repeat the code. Keep related settings together.
- Format Nix with Alejandra.

## Checks

- Include new configuration in the flake's import chain, with all required inputs and upstream modules.
- Evaluate new modules through the actual flake exports and inputs. Check host configurations through the flake as they are added. An isolated module check does not establish that the flake works.
- Do not assume something works because it is already in the configuration.
- Test behavior you are unsure about before relying on it.
- Say what was checked: syntax, Nix evaluation, builds, or running behavior.
- If a check could not run, say so. Do not report it as passed.

## Commits

- Write one imperative subject line with no body or trailers, like the existing `git log`.
- Name the change itself, such as "Share Attic client configuration between desktops and servers", not the reason or the steps.
- Commit only when asked. Do not push unless asked.
