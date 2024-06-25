# s3
resource "aws_s3_bucket" "webapp" {
  bucket = "${local.project}-s3-webapp-${local.env}"
}

resource "aws_s3_bucket_public_access_block" "webapp" {
  bucket                  = aws_s3_bucket.webapp.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

data "aws_iam_policy_document" "webapp" {
  statement {
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.webapp.iam_arn]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.webapp.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "webapp" {
  bucket = aws_s3_bucket.webapp.id
  policy = data.aws_iam_policy_document.webapp.json
}



# cloudfront
resource "aws_cloudfront_origin_access_identity" "webapp" {
  comment = "${local.project}-oai-webapp-${local.env}"
}


resource "aws_cloudfront_function" "webapp" {
  name    = "${local.project}-function-webapp-${local.env}"
  runtime = "cloudfront-js-1.0"
  publish = true
  code    = file("./webapp_cloudfront_function.js")
}

resource "aws_cloudfront_distribution" "webapp" {
  origin {
    origin_id   = aws_s3_bucket.webapp.id
    domain_name = aws_s3_bucket.webapp.bucket_regional_domain_name
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.webapp.cloudfront_access_identity_path
    }
  }
  comment         = "${local.project}-cloudfront-webapp-${local.env}"
  web_acl_id      = aws_wafv2_web_acl.webapp.arn
  enabled         = true
  is_ipv6_enabled = true
  aliases = [
    "v2.n-hub.io",
  ]
  default_cache_behavior {
    target_origin_id = aws_s3_bucket.webapp.id
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
    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.webapp.arn
    }
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


# waf 

resource "aws_wafv2_web_acl" "webapp" {
  provider = aws.virginia
  name     = "${local.project}-acl-webapp-${local.env}"
  scope    = "CLOUDFRONT"

  custom_response_body {
    key          = "BadRequest"
    content      = "400 Bad Request"
    content_type = "TEXT_PLAIN"
  }

  custom_response_body {
    key          = "ComingSoon"
    content      = "Coming Soon..."
    content_type = "TEXT_PLAIN"
  }

  default_action {
    # block {
    #   custom_response {
    #     response_code            = 200
    #     custom_response_body_key = "ComingSoon"
    #   }
    # }
    allow {}
  }

  # rule {
  #   name     = "${local.project}-overseas-block-rule"
  #   priority = 100
  #   action {
  #     block {
  #       custom_response {
  #         response_code            = 400
  #         custom_response_body_key = "BadRequest"
  #       }
  #     }
  #   }
  #   statement {
  #     not_statement {
  #       statement {
  #         geo_match_statement {
  #           country_codes = ["KR"]
  #         }
  #       }
  #     }
  #   }
  #   visibility_config {
  #     metric_name                = "${local.project}-overseas-block-rule"
  #     cloudwatch_metrics_enabled = false
  #     sampled_requests_enabled   = false
  #   }
  # }

  visibility_config {
    metric_name                = "${local.project}-acl-webapp-${local.env}"
    cloudwatch_metrics_enabled = false
    sampled_requests_enabled   = false
  }
}



