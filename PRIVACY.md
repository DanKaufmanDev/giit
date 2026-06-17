# Privacy

Giit is designed to operate primarily on repositories on your machine.

## Local Data

Giit may store local application data needed for the product to work, including:

- App preferences.
- Keybindings and appearance settings.
- Repository metadata used by the interface.
- Recovery points and snapshots.
- Workflow history needed for recovery and undo features.
- Logs used for local troubleshooting.

Repository contents, recovery data, configuration, and workflow history are
intended to remain local to your environment unless you explicitly perform an
operation that sends data elsewhere.

## Network Access

Network access is used for actions you initiate or enable, such as:

- Fetching, pulling, pushing, cloning, or otherwise communicating with Git
  remotes.
- Checking for updates.
- Downloading application updates, if supported by the installed build.

Git remotes, hosting providers, credential helpers, SSH agents, and operating
system services may have their own privacy behavior outside Giit's control.


## Sensitive Repository Data

Repositories can contain secrets, proprietary code, credentials, private commit
messages, or personal information. Giit should treat repository contents and
derived recovery data as sensitive local data.

Users remain responsible for the privacy practices of any Git remote, hosting
provider, integration, or external tool they choose to use with their
repositories.

## Contact

For privacy questions, open an issue or contact the project maintainers through
the current public support channel.
