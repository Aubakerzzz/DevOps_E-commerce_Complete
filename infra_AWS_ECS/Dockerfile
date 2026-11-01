
# Use the official Terraform image.
FROM hashicorp/terraform:1.9.8

# Set the working directory inside the container.
WORKDIR /workspace

# Copy all Terraform configuration files into the image.
COPY *.tf ./



# Copy the EC2 startup script.
COPY user_data.sh ./

# Start an interactive shell.
ENTRYPOINT ["/bin/sh"]
