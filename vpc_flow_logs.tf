resource "aws_iam_role" "flow_logs" {
  name = "${aws_vpc.vpc.id}-flow-logs"
  
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

resource "aws_iam_role_policy" "flow_logs" {
  name = "${aws_vpc.vpc.id}-flow-logs"
  role = aws_iam_role.flow_logs.id

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
      "Resource": "*"
    }
  ]
}
EOF

  depends_on = [
    aws_iam_role.flow_logs,
  ]
}

resource "aws_cloudwatch_log_group" "flow_logs" {
  name = "${aws_vpc.vpc.id}-flow-logs"
}

resource "aws_flow_log" "flow_log" {
  iam_role_arn = aws_iam_role.flow_logs.arn
  log_destination = aws_cloudwatch_log_group.flow_logs.arn
  traffic_type = "ALL"
  vpc_id = aws_vpc.vpc.id

  depends_on = [
    aws_iam_role_policy.flow_logs,
  ]
}
