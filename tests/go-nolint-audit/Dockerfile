FROM skill-test-base

ARG TARGETARCH=amd64

# Install Go 1.22
RUN curl -fsSL "https://dl.google.com/go/go1.22.7.linux-${TARGETARCH}.tar.gz" | \
    tar -xz -C /usr/local
ENV PATH="/usr/local/go/bin:${PATH}"

# Install golangci-lint v1.62.2
RUN curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/master/install.sh | \
    sh -s -- -b /usr/local/bin v1.62.2
