# ---------------------------------------------------------
# ACK S3 Controller IAM Role (IRSA)
# ---------------------------------------------------------

resource "aws_iam_role" "ack_s3" {
  name = "ack-s3-controller"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.main.arn
        }
        Condition = {
          StringEquals = {
            "${replace(aws_iam_openid_connect_provider.main.url, "https://", "")}:sub" = "system:serviceaccount:ack-system:ack-s3-controller"
          }
        }
      }
    ]
  })

  tags = {
    "ServiceAccount" = "ack-s3-controller"
  }
}

resource "aws_iam_role_policy_attachment" "ack_s3_full_access" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.ack_s3.name
}

output "ack_s3_role_arn" {
  value = aws_iam_role.ack_s3.arn
}



