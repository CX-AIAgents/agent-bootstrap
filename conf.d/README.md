# Bootstrap Config Directory

By default, mise [`config.toml`](../config.toml) reads this directory and merge the configs

Be aware of the `mise bootstrap` execution ordering, based on [Run Order](https://mise.jdx.dev/bootstrap.html#how-it-runs):

<!-- Please keep this table as the exact wording copy from the doc above, tho can be formatted properly -->
| Step | Part (`--only`, `--skip`) | Applies | Hooks |
| --- | --- | --- | --- |
| 1 | `accounts` | [`[bootstrap.users]` and `[bootstrap.groups]`](https://mise.jdx.dev/bootstrap/accounts.html) | |
| 2 | `plugins` | [`[bootstrap.plugins]`](https://mise.jdx.dev/bootstrap/packages/plugins.html) | |
| 3 | `files` | Files and directories with [`phase = "pre-packages"`](https://mise.jdx.dev/bootstrap/files.html) | |
| 4 | `packages` | [`[bootstrap.apt.sources]`](https://mise.jdx.dev/bootstrap/packages/apt.html#sources), then [`[bootstrap.packages]`](https://mise.jdx.dev/bootstrap/packages/) from built-in package managers | `pre-packages`, `post-packages` |
| 5 | `files` | The remaining [`[bootstrap.files]` and `[bootstrap.directories]`](https://mise.jdx.dev/bootstrap/files.html) | |
| 6 | `services` | [`[bootstrap.services]`](https://mise.jdx.dev/bootstrap/services.html), except user services with `requires_tools = true` | |
| 7 | `firewall` | [`[bootstrap.linux.firewall]`](https://mise.jdx.dev/bootstrap/firewall.html) | |
| 8 | `compose` | [`[bootstrap.compose]`](https://mise.jdx.dev/bootstrap/compose.html) | |
| 9 | `repos` | [`[bootstrap.repos]`](https://mise.jdx.dev/bootstrap/repos.html) | `pre-repos`, `post-repos` |
| 10 | `dotfiles` | [`[dotfiles]`](https://mise.jdx.dev/dotfiles.html) | `pre-dotfiles`, `post-dotfiles` |
| 11 | `mise-shell-activate` (`shell`) | [`[bootstrap.mise_shell_activate]`](https://mise.jdx.dev/bootstrap/shell.html) | |
| 12 | `macos-defaults` (`defaults`) | [`[bootstrap.macos.defaults]`](https://mise.jdx.dev/bootstrap/macos-defaults.html) and the other `[bootstrap.macos.*]` keys | `pre-defaults`, `post-defaults` |
| 13 | `macos-launchd-agents` (`launchd`) | [`[bootstrap.macos.launchd.agents]`](https://mise.jdx.dev/bootstrap/launchd.html) | |
| 14 | `linux-systemd-units` (`systemd`) | [`[bootstrap.linux.systemd.units]`](https://mise.jdx.dev/bootstrap/systemd.html) | |
| 15 | `user` | [`[bootstrap.user]`](https://mise.jdx.dev/bootstrap/shell.html#set-your-login-shell) | `pre-user`, `post-user` |
| 16 | `tools` | `[tools]`, as `mise install` would | `pre-tools`, `post-tools` |
| 17 | `packages` | Packages from [package manager plugins](https://mise.jdx.dev/bootstrap/packages/plugins.html) | |
| 18 | `services` | User services with `requires_tools = true` | |
| 19 | `task` | The [`bootstrap` task](https://mise.jdx.dev/bootstrap.html#the-bootstrap-task), if one exists | |
| 20 | `final-hook` | | `final` |

The execution order is not bounded to the ordering of the file numbers.
In fact, the file numbers in this directory are just a reminder of the actual order above.
