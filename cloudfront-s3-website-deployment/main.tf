resource "aws_s3_bucket" "website_bucket" {
  bucket        = var.bucket_name
  force_destroy = true
  tags          = merge({ "serviceType" = "S3" }, var.tags)
}

resource "aws_s3_bucket_public_access_block" "s3_bucket_public_access_block_origin" {
  bucket = aws_s3_bucket.website_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.website_bucket.bucket
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "index.html"
  }
  # NOT NECESSARY RIGHT NOW!
  #routing_rule {
  #  condition {
  #    key_prefix_equals = "docs/"
  #  }
  #  redirect {
  #    replace_key_prefix_with = "documents/"
  #  }
  #}
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket     = aws_s3_bucket.website_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.s3_bucket_public_access_block_origin]
  policy     = <<EOF
{
    "Version": "2012-10-17",
    "Statement": {
        "Sid": "AllowCloudFrontServicePrincipalReadOnly",
        "Effect": "Allow",
        "Principal": "*",
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::${var.bucket_name}/*"
    }
}

EOF
}

resource "aws_cloudfront_distribution" "s3_distribution" {
  count = var.create_http_rewrite_function ? 0 : 1
  origin {
    #domain_name = aws_s3_bucket.website_bucket.bucket_regional_domain_name #old config
    domain_name = aws_s3_bucket_website_configuration.website_config.website_endpoint
    origin_id   = var.origin_id
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only" # or "https-only" # This is the key to using the S3 website endpoint
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }
  }
  tags                = merge({ "serviceType" = "CloudFront" }, var.tags)
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Terraform managed"
  default_root_object = "index.html"

  # Aliases not allowed it becomes complicated.
  aliases = var.cname_list

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    prefix          = var.bucket_name
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Tell AWS that the web-app will handle the redirections
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/404.html"
  }
  # Tell AWS that the web-app will handle the redirections
  custom_error_response {
    error_code    = 404
    response_code = var.custom_error_response_response_code

    response_page_path = var.custom_error_response_page_path
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.arn_certificate
    ssl_support_method             = "sni-only"
    minimum_protocol_version       = "TLSv1.2_2021"
  }
}

### HTTP_REWRITE
resource "aws_cloudfront_function" "http_rewrite" {
  count   = var.create_http_rewrite_function ? 1 : 0
  name    = "http_rewrite-${var.bucket_name}"
  runtime = "cloudfront-js-1.0"
  comment = "rewrite URI to append index.html on the fly"
  publish = true
 # code    = file("{path.module}/templates/function_http_rewrite.js")
  code = templatefile("${path.module}/templates/function_http_rewrite.js", {
     cname_target = var.cname_list[0]
  })
}

resource "aws_cloudfront_distribution" "s3_distribution_with_redirect" {
  count = var.create_http_rewrite_function ? 1 : 0
  origin {
    domain_name = aws_s3_bucket_website_configuration.website_config.website_endpoint
    origin_id   = var.origin_id
    custom_origin_config {
      http_port                = 80
      https_port               = 443
      origin_protocol_policy   = "http-only" # or "https-only" # This is the key to using the S3 website endpoint
      origin_keepalive_timeout = 5
      origin_read_timeout      = 30
      origin_ssl_protocols     = ["SSLv3", "TLSv1", "TLSv1.1", "TLSv1.2"]
    }

  }
  tags                = merge({ "serviceType" = "CloudFront" }, var.tags)
  enabled             = true
  is_ipv6_enabled     = false
  comment             = "Terraform managed"
  default_root_object = "index.html"

  aliases = var.cname_list

  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.log_bucket.bucket_domain_name
    prefix          = var.bucket_name
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = var.origin_id

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.http_rewrite[0].arn
    }


    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    viewer_protocol_policy = "redirect-to-https"
    min_ttl                = 0
    default_ttl            = 0
    max_ttl                = 0
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # Tell AWS that the web-app will handle the redirections
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/404.html"

  }
  # Tell AWS that the web-app will handle the redirections
  custom_error_response {
    error_code    = 404
    response_code = var.custom_error_response_response_code

    response_page_path = var.custom_error_response_page_path
  }

  viewer_certificate {
    cloudfront_default_certificate = false
    acm_certificate_arn            = var.arn_certificate
    ssl_support_method             = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

#############################
# Users
#############################

resource "aws_iam_user" "user" {
  count = var.create_deployment_user ? 1 : 0
  name  = var.bucket_name
  tags  = merge({ "serviceType" = "IAM" }, var.tags)
}

resource "aws_iam_access_key" "access_key" {
  count = var.create_deployment_user ? 1 : 0
  user  = aws_iam_user.user[0].name
}

resource "aws_iam_user_policy_attachment" "policy-attach-cloud-formation" {
  count      = var.create_deployment_user ? 1 : 0
  user       = aws_iam_user.user[0].name
  policy_arn = aws_iam_policy.policy-deployment-bucket[0].arn
}

resource "aws_iam_policy" "policy-deployment-bucket" {
  count       = var.create_deployment_user ? 1 : 0
  name        = "${var.bucket_name}-deployment-bucket"
  path        = "/"
  description = "S3 for ${var.bucket_name}. Terraform managed."
  policy      = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "VisualEditor0",
            "Effect": "Allow",
            "Action": [
                "s3:GetAccessPoint",
                "s3:PutAccountPublicAccessBlock",
                "s3:GetAccountPublicAccessBlock",
                "s3:ListAllMyBuckets",
                "s3:ListAccessPoints",
                "s3:ListJobs",
                "s3:CreateJob",
                "s3:HeadBucket"
            ],
            "Resource": "*"
        },
        {
            "Sid": "VisualEditor1",
            "Effect": "Allow",
            "Action": "s3:*",
            "Resource": ["arn:aws:s3:::${var.bucket_name}/*",
            "arn:aws:s3:::${var.bucket_name}"
            ]
        }
    ]
}
EOF
  tags        = merge({ "serviceType" = "IAM" }, var.tags)
}

resource "aws_s3_bucket" "log_bucket" {
  bucket = "${var.bucket_name}-log"
  #acl    = "private"
  tags = merge({ "serviceType" = "S3" }, var.tags)
}

resource "aws_s3_bucket_ownership_controls" "log_bucket" {
  bucket = aws_s3_bucket.log_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "ownership" {
  depends_on = [aws_s3_bucket_ownership_controls.log_bucket]
  bucket     = aws_s3_bucket.log_bucket.id
  acl        = "private"
}
