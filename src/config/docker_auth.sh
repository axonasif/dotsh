function docker_auth() {
    local var_name=DOCKER_AUTH_TOKEN;
    local target="$HOME/.docker/config.json";
    if test -v $var_name; then {
        log::info "Setting up docker login credentials";
        mkdir -p "${target%/*}";
        printf '{"auths":{"https://index.docker.io/v1/":{"auth":"%s"}}}\n' "${!var_name}" > "$target";
    } else {
        log::warn "$var_name is not set";
    } fi
}