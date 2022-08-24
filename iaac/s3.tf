resource aws_s3_bucket static {
  // important to provide a global unique bucket name
  bucket = "boodyvo-go-example-static"
}

resource aws_s3_bucket_ownership_controls meta_static_resources {
  bucket = aws_s3_bucket.static.bucket

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource aws_s3_bucket_acl static {
  bucket = aws_s3_bucket.static.id
  acl    = "private"
}

data aws_iam_policy_document oai_access_policy {
  statement {
    actions   = ["s3:GetObject"]
    // as we use the bucket only for static content we provide an access for all objects in the bucket
    resources = ["${aws_s3_bucket.static.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.frontend.iam_arn]
    }
  }
}

resource aws_s3_bucket_policy oai_access {
  bucket = aws_s3_bucket.static.id
  policy = data.aws_iam_policy_document.oai_access_policy.json
}

resource aws_s3_bucket_cors_configuration website {
  bucket = aws_s3_bucket.static.id

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    expose_headers  = []
    max_age_seconds = 3600
  }
}

resource aws_s3_bucket_public_access_block website_bucket_public_access_block {
  bucket                  = aws_s3_bucket.static.id
  ignore_public_acls      = true
  block_public_acls       = true
  restrict_public_buckets = true
  block_public_policy     = true
}

resource aws_s3_bucket_website_configuration static {
  bucket = aws_s3_bucket.static.id

  index_document {
    suffix = "index.html"
  }

  routing_rule {
    redirect {
      replace_key_with = "index.html"
    }
  }
}

resource aws_s3_object assets {
  for_each = fileset("${path.module}/../frontend", "**")

  bucket = aws_s3_bucket.static.id
  key    = each.value
  source = "${path.module}/../frontend/${each.value}"
  etag   = filemd5("${path.module}/../frontend/${each.value}")

  // simplification of the content type serving
  content_type = length(split(".", basename(each.value))) > 1 ? "text/${split(".", basename(each.value))[length(split(".", basename(each.value))) - 1]}; charset=UTF-8" : "text/html; charset=UTF-8"
}
