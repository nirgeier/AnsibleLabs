#!/usr/bin/env bash
: <<'DOC'
build.sh
---------
Small helper for building and pushing a multi-architecture Docker image
for the Ansible Labs project using Docker Buildx and a docker-compose
build definition.

What this script does (high level):
	1. Locates the git repository root and cd's there so paths are predictable.
	2. Ensures the host supports emulating other CPU architectures by
		 registering binfmt handlers (via tonistiigi/binfmt).
	3. Creates and switches to a docker buildx builder instance named
		 `multiarch-builder` and bootstraps it.
	4. Runs `docker buildx bake` with the project's docker-compose.yml to
		 build and push the ansible-labs image defined in that file.

Usage:
	./build.sh

Requirements / Preconditions:
	- Docker (Engine) installed and running on the host
	- docker buildx available (Docker >= 19.03 with buildx plugin or
		Docker Desktop which bundles it)
	- You must be logged in to the GitHub Container Registry:
		echo $CR_PAT | docker login ghcr.io -u USERNAME --password-stdin
	- You must be logged in to Docker Hub:
		docker login -u USERNAME
	- This script must be executed from a git working tree (it uses
		`git rev-parse --show-toplevel` to find the project root).

Notes / Behavior details:
	- The script uses the container image `tonistiigi/binfmt` to register
		qemu/binfmt handlers for cross-architecture emulation. That requires
		`--privileged` to the runner container (the temporary container).
	- This script creates a buildx builder named `multiarch-builder` and
		switches the current Docker context to use it. If you run this script
		multiple times, buildx will silently re-use an existing builder
		with the same name, or fail if it exists in a conflicting state.
	- The final build step uses `docker buildx bake` with the
		`docker/docker-compose.yml` file and targets the service
		named `ansible-labs` (defined in the repo's compose file).

Customization:
	- You can change the image name and tag by exporting IMAGE and IMAGE_TAG
		before running the script, e.g.:
			IMAGE=ghcr.io/nirgeier/ansible-labs IMAGE_TAG=v1.2.3 ./build.sh

Failure modes:
	- If Docker is not running, commands will fail.
	- If `git rev-parse` fails (not a git repo), the script will abort.
	- If you are not logged into ghcr.io, the push step will fail.

DOC

set -euo pipefail

# Resolve the root of the Git project so we can refer to files by absolute
# path. If this fails this script will exit (not a git repo).
ROOT_DIR=$(git rev-parse --show-toplevel)

# Change into the repository root. This makes relative paths in the
# docker-compose bake file consistent regardless of where the script is
# invoked from.
cd "$ROOT_DIR"

# Allow the user to override the image name and tag via environment
# variables. These defaults match the repository's historical values.
IMAGE=${IMAGE:-ghcr.io/nirgeier/ansible-labs}
IMAGE_TAG=${IMAGE_TAG:-latest}
DOCKERHUB_IMAGE=${DOCKERHUB_IMAGE:-nirgeier/ansible-labs}

# Compute BUILD_TIME in UTC ISO8601 (compatible on Linux and macOS)
BUILD_TIME=$(date +"%Y-%m-%dT%H:%M:%SZ")
# Get the git remote origin URL (if available)
# Named SourceRepository to match the variable expected by docker-compose.yml
SourceRepository=$(git config --local --get remote.origin.url)

echo "Building image: ${IMAGE}:${IMAGE_TAG} (root: ${ROOT_DIR})"

# Step 1: Build the mkdocs site so it can be copied into the Docker image.
echo "Building mkdocs site..."
bash "$ROOT_DIR/mkdocs/scripts/init_site.sh" --no-serve

# Step 2: Register binfmt handlers for multi-architecture emulation.
# The `tonistiigi/binfmt` image provides an easy way to install the
# kernel helpers that allow qemu to run foreign-architecture binaries.
# We run it as a temporary privileged container.
echo "Registering binfmt emulation handlers (required for cross-arch builds)..."
docker run --privileged --rm tonistiigi/binfmt --install all || echo "binfmt: already configured by host (OrbStack/Docker Desktop)"

# Step 3: Create / select a docker buildx builder and switch to it.
# `--use` makes the new builder the current default for buildx operations.
# If the builder already exists, just switch to it.
echo "Creating and switching to buildx builder 'multiarch-builder'..."
if ! docker buildx inspect multiarch-builder >/dev/null 2>&1; then
	docker buildx create --name multiarch-builder --use
else
	docker buildx use multiarch-builder
fi

# Step 3: Bootstrap the builder. This starts the builder container
# and registers its capabilities (including the registered binfmt
# handlers) so the builder is ready to run multi-platform builds.
echo "Bootstrapping buildx builder..."
docker buildx inspect --bootstrap

# Step 4: Build and push using `docker buildx bake`.
# Run from docker/ so that context: .. in the compose file resolves to the repo root.
echo "Running buildx bake for production (build + push)..."
cd "$ROOT_DIR/docker"
BUILD_TIME="$BUILD_TIME" \
IMAGE="$IMAGE" \
IMAGE_TAG="$IMAGE_TAG" \
SourceRepository="$SourceRepository" \
docker buildx bake \
	--allow=fs.read=.. \
	-f docker-compose.yml \
	--push \
	ansible-labs

echo "Done."
