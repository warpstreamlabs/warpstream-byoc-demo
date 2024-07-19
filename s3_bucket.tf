# Provision an S3 bucket with the minimum bucket policy.

resource "aws_s3_bucket" "warpstream_bucket" {
  bucket = "warpstream-byoc-demo-bucket"

  tags = {
    Name        = "warpstream-byoc-demo-bucket"
    Environment = "staging"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "warpstream_bucket_lifecycle" {
  bucket = aws_s3_bucket.warpstream_bucket.id

  # Automatically cancel all multi-part uploads after 7d so we don't accumulate an infinite
  # number of partial uploads.
  rule {
    id     = "7d multi-part"
    status = "Enabled"
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  # No other lifecycle policy. The WarpStream Agent will automatically clean up and
  # deleted expired files.
}

data "aws_iam_policy_document" "warpstream_iam_policy_document_bucket" {
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
    principals {
      type        = "AWS"
      identifiers = [aws_iam_role.warpstream_iam_role.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "warpstream_bucket_policy" {
  bucket = aws_s3_bucket.warpstream_bucket.id

  policy = data.aws_iam_policy_document.warpstream_iam_policy_document_bucket.json
}

output "s3_bucket_url" {
  value = "s3://${aws_s3_bucket.warpstream_bucket.bucket}?region=${aws_s3_bucket.warpstream_bucket.region}"
}
