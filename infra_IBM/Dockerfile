FROM hashicorp/terraform:1.9

# Install IBM Cloud CLI (optional but useful for auth/debugging)
RUN apk add --no-cache curl bash openssh-client \
    && curl -fsSL https://clis.cloud.ibm.com/install/linux | sh

WORKDIR /workspace
ENTRYPOINT ["/bin/bash"]