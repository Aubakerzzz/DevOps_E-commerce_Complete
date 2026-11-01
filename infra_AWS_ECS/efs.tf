resource "aws_efs_file_system" "mongo" {
  creation_token = "${var.project_name}-mongo"
  encrypted      = true

  tags = {
    Name = "${var.project_name}-mongo"
  }
}

resource "aws_efs_mount_target" "mongo" {
  count           = 2
  file_system_id  = aws_efs_file_system.mongo.id
  subnet_id       = aws_subnet.public[count.index].id
  security_groups = [aws_security_group.efs.id]
}

resource "aws_efs_access_point" "mongo" {
  file_system_id = aws_efs_file_system.mongo.id

  posix_user {
    gid = 999
    uid = 999
  }

  root_directory {
    path = "/mongo-data"
    creation_info {
      owner_gid   = 999
      owner_uid   = 999
      permissions = "0755"
    }
  }
}