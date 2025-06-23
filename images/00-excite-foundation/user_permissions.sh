set -e

for d in "$@"; do
    find "${d}" \
        ! \( \
            -group "${EXC_GID}" \
            -a -perm -g+rwX \
        \) \
        -exec chgrp "${EXC_GID}" -- {} \+ \
        -exec chmod g+rwX -- {} \+

    find "${d}" \
        \( \
            -type d \
            -a ! -perm -6000 \
        \) \
        -exec chmod +6000 -- {} \+
done