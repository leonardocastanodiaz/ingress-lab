# ============================
# Terraform + LocalStack Runner
# ============================

FROM alpine:3.19

# Versions (pin for reproducibility)
ENV TERRAFORM_VERSION=1.6.6
ENV LOCALSTACK_VERSION=4.12.0

# Core tools
RUN apk add --no-cache \
    bash \
    curl \
    unzip \
    python3 \
    py3-pip \
    py3-virtualenv \
    git \
    ca-certificates \
    openssl \
    jq \
    docker-cli \
    aws-cli

# ----------------------------
# Install Terraform
# ----------------------------
RUN curl -fsSL https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip \
    -o /tmp/terraform.zip && \
    unzip /tmp/terraform.zip -d /usr/local/bin && \
    rm /tmp/terraform.zip

# ----------------------------
# Install LocalStack CLI
# ----------------------------
RUN apk add --no-cache --virtual .build-deps \
      build-base \
      libffi-dev \
      openssl-dev \
      python3-dev \
      cargo \
      rust && \
    python3 -m venv /opt/localstack && \
    /opt/localstack/bin/pip install --no-cache-dir localstack==${LOCALSTACK_VERSION} && \
    apk del .build-deps

# Make localstack available globally
ENV PATH="/opt/localstack/bin:${PATH}"

# ----------------------------
# Entrypoint
# ----------------------------
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

WORKDIR /workspace

ENTRYPOINT ["/entrypoint.sh"]
CMD ["bash"]
