# Provision a role with the minimum IAM policy.

data "aws_iam_policy_document" "warpstream_iam_policy_document_role" {
  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject",
      "s3:GetObject",
      "s3:DeleteObject",
      "s3:ListBucket"
    ]
    resources = [
      aws_s3_bucket.warpstream_bucket.arn,
      "${aws_s3_bucket.warpstream_bucket.arn}/*"
    ]
  }
}

resource "aws_iam_policy" "warpstream_iam_policy" {
  name   = "warpstream-byoc-demo-policy"
  policy = data.aws_iam_policy_document.warpstream_iam_policy_document_role.json
}

resource "aws_iam_role" "warpstream_iam_role" {
  name               = "warpstream-byoc-demo-role"
  assume_role_policy = <<EOF
  {
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Principal" : {
          "AWS" : "arn:aws:iam::767397817548:root"
        },
        "Action" : "sts:AssumeRole",
        "Condition": {}
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy_attachment" "warpstream_iam_policy_attachment" {
  role       = aws_iam_role.warpstream_iam_role.name
  policy_arn = aws_iam_policy.warpstream_iam_policy.arn
}

output "role_arn" {
  value = aws_iam_role.warpstream_iam_role.arn
}
