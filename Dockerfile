FROM debian:buster-slim AS builder
RUN apt-get update && \
    apt-get install --no-install-suggests --no-install-recommends --yes python3-venv gcc libpython3-dev && \
    python3 -m venv /venv && \
    /venv/bin/pip install --upgrade pip

ENV PIP_DEFAULT_TIMEOUT=100 \
    PIP_DISABLE_PIP_VERSION_CHECK=1 \
    PIP_NO_CACHE_DIR=1 \
    POETRY_VERSION=1.0.5

FROM builder AS builder-venv

RUN /venv/bin/pip install "poetry==$POETRY_VERSION" && python3 -m venv /venv

COPY pyproject.toml poetry.lock /
RUN /venv/bin/poetry export -f requirements.txt | /venv/bin/pip install -r /dev/stdin

FROM builder-venv AS tester

COPY . /app
WORKDIR /app
RUN /venv/bin/pytest

FROM gcr.io/distroless/python3-debian11 AS runner
COPY --from=tester /venv /venv
COPY --from=tester /app /app

WORKDIR /app

ENTRYPOINT ["/venv/bin/python3", "-m", "tester"]
USER 1001