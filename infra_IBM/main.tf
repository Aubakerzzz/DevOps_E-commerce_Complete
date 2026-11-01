# VPC
resource "ibm_is_vpc" "vpc" {
  name = "${var.project_name}-vpc"
}

# SSH Key
resource "ibm_is_ssh_key" "ssh_key" {
  name       = "${var.project_name}-ssh-key"
  public_key = var.ssh_public_key
}

# Security Group
resource "ibm_is_security_group" "sg" {
  name = "${var.project_name}-sg"
  vpc  = ibm_is_vpc.vpc.id
}

resource "ibm_is_security_group_rule" "ssh" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = var.admin_cidr
  tcp {
    port_min = 22
    port_max = 22
  }
}

resource "ibm_is_security_group_rule" "http" {
  group     = ibm_is_security_group.sg.id
  direction = "inbound"
  remote    = "0.0.0.0/0"
  tcp {
    port_min = 80
    port_max = 80
  }
}

# Subnet
resource "ibm_is_subnet" "subnet" {
  name            = "${var.project_name}-subnet"
  vpc             = ibm_is_vpc.vpc.id
  zone            = var.zone
  ipv4_cidr_block = "10.240.0.0/24"
}

# Ubuntu Image (data source)
data "ibm_is_image" "ubuntu" {
  name = "ibm-ubuntu-22-04-3-minimal-amd64-1"
}

# Virtual Server Instance
resource "ibm_is_instance" "vm" {
  name    = "${var.project_name}-vm"
  image   = data.ibm_is_image.ubuntu.id
  profile = var.profile

  primary_network_interface {
    subnet          = ibm_is_subnet.subnet.id
    security_groups = [ibm_is_security_group.sg.id]
  }

  vpc       = ibm_is_vpc.vpc.id
  zone      = var.zone
  keys      = [ibm_is_ssh_key.ssh_key.id]
  user_data = file("${path.module}/user_data.sh")

  tags = [
    "project:${var.project_name}",
    "managed-by:terraform"
  ]
}

# Floating IP for public access
resource "ibm_is_floating_ip" "fip" {
  name   = "${var.project_name}-fip"
  target = ibm_is_instance.vm.primary_network_interface[0].id
}