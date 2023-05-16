resource "aws_iam_role" "flow_log" {
  name = "${aws_vpc.vpc.id}-flow-log"
  
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": "vpc-flow-logs.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy" "flow_log" {
  name = "${aws_vpc.vpc.id}-flow-log"
  role = aws_iam_role.flow_log.id

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": [
        "logs:DescribeLogGroups",
        "logs:DescribeLogStreams",
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:log-group:*"
    },
    {
      "Action": [
        "logs:PutLogEvents"
      ],
      "Effect": "Allow",
      "Resource": "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:log-group:*:log-stream:*"
    }
  ]
}
EOF

  depends_on = [
    aws_iam_role.flow_log,
  ]
}

resource "aws_cloudwatch_log_group" "flow_log" {
  kms_key_id = aws_kms_key.flow_log_encryption.arn
  name = "${var.cluster_name}-flow-log"
}

resource "aws_flow_log" "flow_log" {
  iam_role_arn = aws_iam_role.flow_log.arn
  log_destination = aws_cloudwatch_log_group.flow_log.arn
  traffic_type = "ALL"
  vpc_id = aws_vpc.vpc.id

  depends_on = [
    aws_iam_role_policy.flow_log,
  ]
}
