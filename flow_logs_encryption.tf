resource "aws_kms_key" "flow_log_encryption" {
  description             = "${aws_vpc.vpc.id} flow log encryption"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  policy = <<EOT
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "kms:*",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
      },
      "Effect": "Allow",
      "Resource": "*"
    },
    {
      "Action": [
        "kms:CreateGrant",
        "kms:CreateKey",
        "kms:Describe*",
        "kms:List*"
      ],
      "Effect": "Allow",
      "Resource": "*",
      "Principal": {
        "AWS": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:user/${var.kms_user}"
       }
    },
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "logs.us-west-2.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt*",
        "kms:Describe*",
        "kms:Encrypt*",
        "kms:GenerateDataKey*",
        "kms:ReEncrypt*"
      ],
      "Resource": "*",
      "Condition": {
        "ArnEquals": {
          "kms:EncryptionContext:aws:logs:arn": "arn:aws:logs:us-west-2:${data.aws_caller_identity.current.account_id}:log-group:${var.cluster_name}-flow-log"
        }
      }
    }
  ]
}
EOT
}

resource "aws_kms_alias" "flow_log_encryption" {
  name          = "alias/${aws_vpc.vpc.id}-flow-log"
  target_key_id = aws_kms_key.flow_log_encryption.key_id
}
