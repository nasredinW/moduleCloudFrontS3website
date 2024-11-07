output "cloudfront_domain_name" {
  value = aws_cloudfront_distribution.s3_distribution.*.domain_name
}
output "cloudfront_domain_name_with_redirect" {
  value = aws_cloudfront_distribution.s3_distribution_with_redirect.*.domain_name
}
output "access_key" {
  value = aws_iam_access_key.access_key.*.id
}
output "secret" {
  value = aws_iam_access_key.access_key.*.secret
}
output "bucket_name" {
  value = var.bucket_name
}
