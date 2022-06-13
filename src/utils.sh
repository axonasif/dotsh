function is::gitpod() {
      # Check for existent of this gitpod-specific file and the ENV var.
      test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT;
}
