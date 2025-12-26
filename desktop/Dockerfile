# =============================================================================
# Fotobook Desktop Application - Build Dockerfile
# =============================================================================
# This Dockerfile is for BUILDING the Flutter desktop application.
# Since desktop apps require a GUI to run, this container is used for:
# - CI/CD builds
# - Creating release binaries
# - Running tests
# =============================================================================

FROM ubuntu:22.04 AS builder

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies for Flutter and Linux desktop builds
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    clang \
    cmake \
    ninja-build \
    pkg-config \
    libgtk-3-dev \
    liblzma-dev \
    libstdc++-12-dev \
    libsqlite3-dev \
    libsecret-1-dev \
    libjsoncpp-dev \
    && rm -rf /var/lib/apt/lists/*

# Set up Flutter
ENV FLUTTER_VERSION=3.24.0
ENV FLUTTER_HOME=/opt/flutter
ENV PATH="$FLUTTER_HOME/bin:$PATH"

# Download and extract Flutter
RUN curl -L "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    | tar xJ -C /opt

# Configure Flutter
RUN flutter config --no-analytics \
    && flutter config --enable-linux-desktop \
    && flutter precache --linux

# Create build directory
WORKDIR /app

# Copy pubspec files for dependency caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build the Linux desktop application
RUN flutter build linux --release

# =============================================================================
# Output Stage - Extract built binaries
# =============================================================================
FROM scratch AS artifact

# Copy the built application
COPY --from=builder /app/build/linux/x64/release/bundle /fotobook-linux

# =============================================================================
# Test Stage - Run Flutter tests
# =============================================================================
FROM builder AS test

# Run tests
RUN flutter test

# =============================================================================
# Usage:
# =============================================================================
# Build the application:
#   docker build --target artifact --output type=local,dest=./dist .
#
# Run tests:
#   docker build --target test .
#
# Build for all platforms (requires separate builds):
#   - Linux: Use this Dockerfile
#   - Windows: Use Windows host with Flutter installed
#   - macOS: Use macOS host with Flutter installed
# =============================================================================
