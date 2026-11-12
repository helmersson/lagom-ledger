# Issue tracker: GitHub

Issues and specifications for this repository live in GitHub Issues. Use the `gh` CLI for issue operations.

## Conventions

- Create issues with `gh issue create --title "..." --body "..."`.
- Read issues with `gh issue view <number> --json number,title,body,labels,comments`.
- List open issues with `gh issue list --state open --json number,title,body,labels,comments`.
- Apply and remove labels with `gh issue edit <number> --add-label "..."` and `--remove-label "..."`.
- Comment on issues with `gh issue comment <number> --body "..."`, and close them with `gh issue close <number>`.
- Infer the repository from `git remote -v`; verify the target with `gh repo view --json nameWithOwner` before the first issue creation in a session.
- File issues only in `helmersson/lagom-ledger`.

## Pull requests as a triage surface

No. Pull requests are not used as feature requests in the triage queue.

## Publishing

When an engineering skill says to publish work to the issue tracker, create a GitHub issue.
