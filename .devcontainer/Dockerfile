FROM hexpm/elixir:1.18.3-erlang-27.3.2-ubuntu-focal-20241011

# Install git and other useful development tools
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    vim \
    nano \
    htop \
    sudo \
    locales \
    bash-completion \
    inotify-tools \
    # Clean up to reduce image size
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*


# Install hex and rebar for Elixir
RUN mix local.hex --force && \
    mix local.rebar --force

# Set working directory
WORKDIR /workspace

CMD ["/bin/bash"]
