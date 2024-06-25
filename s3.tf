resource "aws_s3_bucket" "codeartifact" {
  bucket = "${local.project}-s3-codeartifact-${local.env}"
}

resource "aws_s3_bucket" "cloudfront_logs" {
  bucket = "${local.project}-s3-cloudfront-logs-${local.env}"
}


# static s3
resource "aws_s3_bucket" "static" {
  bucket = "${local.project}-s3-static-${local.env}"
}

resource "aws_s3_bucket_public_access_block" "static" {
  bucket                  = aws_s3_bucket.static.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "static" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.static.iam_arn]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.static.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "static" {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.static.json
}

# static cloudfront
resource "aws_cloudfront_origin_access_identity" "static" {
  comment = "${local.project}-oai-static-${local.env}"
}

resource "aws_cloudfront_distribution" "static" {
  origin {
    origin_id   = aws_s3_bucket.static.id
    domain_name = aws_s3_bucket.static.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.static.cloudfront_access_identity_path
    }
  }
  comment         = "${local.project}-cloudfront-static-${local.env}"
  enabled         = true
  is_ipv6_enabled = true
  aliases = [
    "v2-static.n-hub.io"
  ]
  default_cache_behavior {
    target_origin_id = aws_s3_bucket.static.id
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD", "OPTIONS"]
    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    compress               = true
    viewer_protocol_policy = "redirect-to-https"
  }
  restrictions {
    geo_restriction {
      restriction_type = "none"
      locations        = []
      # restriction_type = "whitelist"
      # locations        = ["KR"]
    }
  }
  custom_error_response {
    error_caching_min_ttl = 10
    error_code            = 403
    response_code         = 200
    response_page_path    = "/"
  }
  viewer_certificate {
    acm_certificate_arn      = local.acm_nhub_io_useast1_arn
    minimum_protocol_version = "TLSv1.2_2021"
    ssl_support_method       = "sni-only"
  }
}