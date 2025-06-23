
ARG BUILDER_IMAGE=debian:bookworm-slim
FROM --platform=$BUILDPLATFORM ${BUILDER_IMAGE} AS builder

LABEL maintainer="NAME <EMAIL@EMAIL.com>"

ARG EXC_USER="foo"
ARG EXC_UID="1000"
ARG EXC_GID="100"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Base packages + locale setup
ENV DEBIAN_FRONTEND=noninteractive
RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        locales \
        netbase \
        sudo \
        tini \
        wget && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen && \
    rm -rf /usr/share/locale/*

# Configure environment
ENV SHELL="/bin/bash" \
    EXC_USER="${EXC_USER}" \
    EXC_UID="${EXC_UID}" \
    EXC_GID="${EXC_GID}" \
    LANG="en_US.UTF-8" \
    LC_ALL="en_US.UTF-8" \
    LANGUAGE="en_US.UTF-8" \
    TZ="UTC" \
    TERM="xterm-256color"
ENV PATH="${PATH}" \
    HOME="/home/${EXC_USER}"

# Setup user permissions
COPY user_permissions.sh /usr/local/bin/user_permissions
RUN chmod a+rx /usr/local/bin/user_permissions

# Enable prompt color in the skeleton
RUN sed -i 's/^#force_color_prompt=yes/force_color_prompt=yes/' /etc/skel/.bashrc && \
    echo 'eval "$(conda shell.bash hook)"' >> /etc/skel/.bashrc

# Delete existing user with UID="${EXC_UID}" if it exists
RUN if grep -q "${EXC_UID}" /etc/passwd; then \
        userdel --remove $(id -un "${EXC_UID}"); \
    fi

RUN echo "auth requisite pam_deny.so" >> /etc/pam.d/su && \
    sed -i.bak -e 's/^%admin/#%admin/' /etc/sudoers && \
    sed -i.bak -e 's/^%sudo/#%sudo/' /etc/sudoers && \
    useradd --no-log-init --create-home --shell /bin/bash --uid "${EXC_UID}" --no-user-group "${EXC_USER}" && \
    chmod g+w /etc/passwd && \
    user_permissions "/home/${EXC_USER}"

USER ${EXC_USER}

RUN mkdir "/home/${EXC_USER}/work" && \
    user_permissions "/home/${EXC_USER}"

COPY run-hooks.sh start.sh /usr/local/bin/

ENTRYPOINT ["tini", "-g", "--", "/usr/local/bin/start.sh"]

USER root

COPY checksums/* /usr/local/checksums/
COPY hooks/* /usr/local/bin/hooks/


# Some architectures add junk cache, so we remove it
RUN rm -rf "/home/${EXC_USER}/.cache/"

# Switch back to non-root user
USER ${EXC_USER}
WORKDIR /home/${EXC_USER}

