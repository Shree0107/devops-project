resource "aws_vpc_endpoint" "ecr_api" {

  vpc_id = aws_vpc.main.id

  service_name = "com.amazonaws.eu-west-3.ecr.api"

  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "ecr_dkr" {

  vpc_id = aws_vpc.main.id

  service_name = "com.amazonaws.eu-west-3.ecr.dkr"

  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true
}

resource "aws_vpc_endpoint" "secret_manager" {

  vpc_id = aws_vpc.main.id

  service_name = "com.amazonaws.eu-west-3.secretsmanager"

  vpc_endpoint_type = "Interface"

  subnet_ids = [
    aws_subnet.private.id
  ]

  security_group_ids = [
    aws_security_group.endpoint.id
  ]

  private_dns_enabled = true
}

