provider "aws" {
  region = "ap-northeast-1" # 東京リージョン
}

resource "aws_s3_bucket" "wiz_bucket" {
  bucket = "wiz-demo-bucket-${random_id.rand.hex}"
  acl    = "private"

  tags = {
    Name        = "WizDemo"
    Environment = "Dev"
  }
}

resource "random_id" "rand" {
  byte_length = 4
}

resource "aws_cloudfront_origin_access_control" "s3_oac" {
  name                              = "wiz-oac"
  description                       = "OAC for S3"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

resource "aws_cloudfront_distribution" "wiz_cf" {
  enabled             = true
  default_root_object = "index.html"

  origin {
    domain_name = aws_s3_bucket.wiz_bucket.bucket_regional_domain_name
    origin_id   = "wizS3Origin"

    origin_access_control_id = aws_cloudfront_origin_access_control.s3_oac.id
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "wizS3Origin"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "WizCloudFront"
    Environment = "Dev"
  }
}

data "aws_iam_policy_document" "s3_policy" {
  statement {
    sid    = "AllowCloudFrontAccess"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudfront.amazonaws.com"]
    }

    actions = [
      "s3:GetObject"
    ]

    resources = [
      "${aws_s3_bucket.wiz_bucket.arn}/*"
    ]

    condition {
      test     = "StringEquals"
      variable = "AWS:SourceArn"
      values   = [aws_cloudfront_distribution.wiz_cf.arn]
    }
  }
}

resource "aws_s3_bucket_policy" "wiz_policy" {
  bucket = aws_s3_bucket.wiz_bucket.id
  policy = data.aws_iam_policy_document.s3_policy.json
}

