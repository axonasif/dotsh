function is::gitpod() {
    if test -e /ide/bin/gitpod-code && test -v GITPOD_REPO_ROOT; then {
        true;
    } else {
        false;
    } fi
}