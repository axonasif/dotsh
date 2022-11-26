function structlog() {
  declare -a args=("$@");
  declare FUNC="${args[0]}";

  (
    exec \
    > >(
      while read -r ___stdout; do
        \echo -e "${BGREEN}[${BCLR:-}${FUNC}${BGREEN}]${RC} $___stdout";
      done
    ) \
    2> >(
      while read -r ___stderr; do
        \echo -e "${BRED}[${BCLR:-}${FUNC}${BRED}]${RC} $___stderr" >&2;
      done
    )

    "${args[@]}";
  )
}
