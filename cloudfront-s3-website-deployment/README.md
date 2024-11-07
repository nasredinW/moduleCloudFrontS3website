
#  Module Amazon CloudFront Secure S3 Website Dynamic Endpoint

## Overview
This module serves as a template for the creation of a new terraform module under AWS following the [best practice IaC]() .

This Terraform module sets up an S3-based static website with integrated CloudFront distribution. 


---

### Key Points:

- **CloudFront** optimizes content delivery by caching frequently accessed objects at edge locations.
- The **S3 bucket** serves as the origin, hosting the website content.
- **HTTP-to-HTTPS redirection** and other custom behaviors can be configured in **CloudFront** for better security and performance.
- The flow ensures a **fast and efficient user experience** by reducing latency and offloading traffic from the S3 origin.

This setup minimizes the load on your S3 bucket and leverages CloudFront's global network of edge locations to ensure that content is delivered quickly to users, regardless of their location.


# CloudFront and S3 Integration Flow

This section explains how the CloudFront distribution interacts with the S3 bucket to serve content to end-users.

### Flow Overview

1. **Viewer Request**  
   The viewer accesses the website at `project.[stg,ppr,prod].domain.com`.

2. **Cache Check**
    - If the requested object is already cached in **CloudFront**, it is returned directly from the cache to the viewer.

3. **Cache Miss**
    - If the object is **not cached**, CloudFront forwards the request to the S3 bucket origin:  
      `bucket-name.s3-website.eu-central-1.amazonaws.com/object`.

4. **S3 Response**
    - The S3 bucket retrieves the object and returns it to **CloudFront**.

5. **Caching the Object**
    - **CloudFront** caches the object for future requests, ensuring faster delivery.

6. **Serving from Cache**
    - The object is returned to the viewer, and any subsequent requests for the same object are served directly from **CloudFront's cache**.

---

### Diagram of Request Flow:


The following diagram shows an overview of how the solution works:
![Architecture](./etc/docs/)

## Requirements
You must have registered domain name  ,AWS account ,ARN of certificate to use,You must have IAM permissions to launch templates that create IAM roles,
and to create  the  AWS resources in the solution.

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.59 |



## Usage
Basic usage of this module is as follows:
```hcl
module "my_module_name" {
  	 source  = "z/<module-name>/aws"
  	 version  = "<x.x.x>"
  
	 # Required variables
  	 account_id  = 
  	 arn_certificate  = 
  	 bucket_name  = 
  	 cname_list  = 
  	 create_deployment_user  = 
  	 origin_id  = 
  
	 # Optional variables
  	 create_http_rewrite_function  = false
  	 custom_error_response_page_path  = "/index.html"
  	 custom_error_response_response_code  = 200
  	 tags  = {}
}
```
## Resources

| Name | Type |
|------|------|
| [aws_cloudfront_distribution.s3_distribution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_distribution.s3_distribution_with_redirect](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_function.http_rewrite](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_function) | resource |
| [aws_iam_access_key.access_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_access_key) | resource |
| [aws_iam_policy.policy-deployment-bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_user.user](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user) | resource |
| [aws_iam_user_policy_attachment.policy-attach-cloud-formation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_user_policy_attachment) | resource |
| [aws_s3_bucket.log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.website_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.ownership](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_ownership_controls.log_bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.allow_access_from_another_account](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.s3_bucket_public_access_block_origin](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_website_configuration.website_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_website_configuration) | resource |
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Id of your account | `string` | n/a | yes |
| <a name="input_arn_certificate"></a> [arn\_certificate](#input\_arn\_certificate) | ARN of certificate to use | `string` | n/a | yes |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the bucket that will store the static website | `string` | n/a | yes |
| <a name="input_cname_list"></a> [cname\_list](#input\_cname\_list) | Extra  CNAMs(alternate domain names) | `list(string)` | n/a | yes |
| <a name="input_create_deployment_user"></a> [create\_deployment\_user](#input\_create\_deployment\_user) | Create user to deploy code, or not. | `bool` | n/a | yes |
| <a name="input_create_http_rewrite_function"></a> [create\_http\_rewrite\_function](#input\_create\_http\_rewrite\_function) | Create function: rewrite URI to append index.html on the fly | `bool` | `false` | no |
| <a name="input_custom_error_response_page_path"></a> [custom\_error\_response\_page\_path](#input\_custom\_error\_response\_page\_path) | Error page content for custom error page | `string` | `"/index.html"` | no |
| <a name="input_custom_error_response_response_code"></a> [custom\_error\_response\_response\_code](#input\_custom\_error\_response\_response\_code) | Response code for custom error page | `number` | `200` | no |
| <a name="input_origin_id"></a> [origin\_id](#input\_origin\_id) | Id of your origin | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A map of tags to use on all resources | `map(string)` | `{}` | no |
## Outputs

| Name | Description |
|------|-------------|
| <a name="output_access_key"></a> [access\_key](#output\_access\_key) | n/a |
| <a name="output_bucket_name"></a> [bucket\_name](#output\_bucket\_name) | n/a |
| <a name="output_cloudfront_domain_name"></a> [cloudfront\_domain\_name](#output\_cloudfront\_domain\_name) | n/a |
| <a name="output_cloudfront_domain_name_with_redirect"></a> [cloudfront\_domain\_name\_with\_redirect](#output\_cloudfront\_domain\_name\_with\_redirect) | n/a |
| <a name="output_secret"></a> [secret](#output\_secret) | n/a |











