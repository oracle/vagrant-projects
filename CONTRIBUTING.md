# Contributing to the Oracle Vagrant Projects repository

Oracle welcomes contributions to this repository from anyone.

If you want to submit a pull request to fix a bug or enhance an existing
`Vagrantfile` or associated script, please first open an issue and link to that
issue when you submit your pull request.

If you have any questions about a possible submission, feel free to open
an issue too.

All pull requests require the contributor to have agreed to and signed the
[Oracle Contributor Agreement](https://www.oracle.com/technetwork/community/oca-486395.html) (OCA).

For pull requests to be accepted, the bottom of your commit message must have
the following line using your name and e-mail address as it appears in the
OCA signatories list.

```shell
Signed-off-by: Your Name <you@example.org>
```

This can be automatically added to pull requests by providing the `--signoff`
or `-s` parameter when commiting:

```shell
git commit --signoff
```

Only pull requests from committers that can be verified as having signed the OCA
can be accepted.

## Pull request process

1. Fork this repository
1. Create a branch in your fork to implement the changes. We recommend using
the issue number as part of your branch name, e.g. `1234-fixes`
1. Ensure that any documentation is updated with the changes that are required
by your fix.
1. Ensure that any samples are updated if the base image has been changed.
1. Submit the pull request. *Do not leave the pull request blank*. Explain exactly
what your changes are meant to do and provide simple steps on how to validate
your changes. Ensure that you reference the issue you created as well.
We will assign the pull request to 2-3 people for review before it is merged.

Copyright (c) 2018, 2020 Oracle and/or its affiliates.
