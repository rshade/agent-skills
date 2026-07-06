FROM skill-test-base

ARG TARGETARCH=amd64

# Install Go 1.26 (required: go fix modernizers only exist in Go 1.26+)
RUN curl -fsSL "https://dl.google.com/go/go1.26.4.linux-${TARGETARCH}.tar.gz" | \
    tar -xz -C /usr/local
ENV PATH="/usr/local/go/bin:${PATH}"
