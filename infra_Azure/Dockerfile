FROM hashicorp/terraform:1.9

# Install Azure CLI for authentication
RUN apk add --no-cache curl bash openssh-client \
    && curl -sL https://aka.ms/InstallAzureCLIDeb | bash

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]