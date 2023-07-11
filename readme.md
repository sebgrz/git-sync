## Repos synchronizer

Tool to auto-synchronize git repositories between both Github and Gitlab repo hostings

Assumptions:
- intergration with both GH and GL APIs
- auto-creation project if doesn't exists
	- gitlab doing this automatically - pushing mirror to the non-exists project automatically create it

> Important! The script has no any error handling/logging mechanism, so if any error occurs during synchronization it's possible that no `journalctl` will report this.

Files struct:
- config.json - providers configuration file (authorization data and so on)
- repos - list repos to synchronize
- git-sync.sh - main script file
- git-sync.{service|timer} - systemd units files to run `git-sync` as a timer service
- install.sh - script file to install `git-sync` as a service

## Installation

### Providers configuration
`config.json` file:
For github (gh) is require only to set:
- username
- token - PAT token in developer settings.
  Required permissions: Administration (R/W), Contents (R/W), Metadata (R)

For gitlab (gl) (as gitlab can be installed individually, self-hosted configuration has additional fields):
- https - true/false depends on service is running with ssl cert
- host - address on which the service is exposed
- username
- token - pat token - scopes: api, read_api, read_repository, write_repository

### Repositories configuration
`repos` file
This file contains all repositories to synchronize. Each line represent one synchronization.
Format (sync `provider-a` to `provider-b`):
```
<provider-a>:<username>/<project>|<provider-b>:<username>/<project>
```

Example:
```
gl:example/example|gh:example/example-backup
```
