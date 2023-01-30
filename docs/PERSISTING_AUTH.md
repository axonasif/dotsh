[dotsh filesync](https://github.com/axonasif/dotsh#cross-workspace-and-local-filesync) can help with persisting auth for almost all\* programs, so that you don't have to re-auth each time a Gitpod workspace is launched. All of the examples/instructions below are to be followed inside a Gitpod workspace to setup persistence.

If you're looking for including/installing _persistent_ tools inside a workspace, see [easy package installation](https://github.com/axonasif/dotsh#easy-cross-platform-package-installation).

Please follow [Quickstart for gitpod](https://github.com/axonasif/dotsh#quickstart-for-gitpod) if you're not using `dotsh` and want to use the below examples.

## docker

```bash
# To login
docker login

# To persist
dotsh filesync save -dh ~/.docker/config.json
```

## doppler

You can also check [this](https://www.loom.com/share/aa43b004a8cd4d84a2d9f7c1390f8110) loom if you want a visual guide.

```bash
# To login
# Make sure to select 'N[o]' when it asks about launching a browser
doppler login

# To persist
dotsh filesync save -dh ~/.doppler/.doppler.yaml
```

If you're looking for examples that doesn't use dotfiles to setup doppler but rather configure in repo level, here are a few:
- https://github.com/jimmybrancaccio/gitpod-doppler-test
- https://github.com/gitpod-samples/demo-secrets-management

## gcloud

```bash
# To login
gcloud auth login --no-launch-browser

# To persist
cd ~/.config/gcloud
dotsh filesync save -dh access_tokens.db active_config configurations credentials.db
```

## gh or glab

No manual login/persistence is necessary when using `dotsh` as your dotfiles installer[[1](/src/config/scm_cli.sh)].

Note: You can set `DOTFILES_GITHUB_TOKEN` or `DOTFILES_GITLAB_TOKEN` at https://gitpod.io/variables with `*/*` scope to use a custom token other than the one provided by Gitpod.

## GnuPG / git commit signing

```bash
# Simply save the gnupg dir after creating keys
# And after this you could sign your commits easily without having to set gnupg each time.
dotsh filesync save -dh ~/.gnupg
```

## npmrc (for private packages)

```bash
# To login
npm login

# To persist
dotsh filesync save -dh ~/.npmrc
```

Have an example that you'd like to add? Feel free to raise a pull request 🙌
