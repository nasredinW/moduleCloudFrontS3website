variable "bucket_name" {
  description = "Name of the bucket that will store the static website"
  type        = string
}

variable "cname_list" {
  description = "Extra  CNAMs(alternate domain names)"
  type        = list(string)
}

variable "arn_certificate" {
  description = "ARN of certificate to use"
  type        = string
}

variable "create_deployment_user" {
  description = "Create user to deploy code, or not."
  type        = bool
}

variable "create_http_rewrite_function" {
  description = "Create function: rewrite URI to append index.html on the fly"
  type        = bool
  default     = false
}

variable "custom_error_response_response_code" {
  description = "Response code for custom error page"
  default     = 200
  type        = number
}

variable "custom_error_response_page_path" {
  description = "Error page content for custom error page"
  default     = "/index.html"
  type        = string
}

variable "origin_id" {
  description = "Id of your origin"
  type        = string
}

variable "account_id" {
  description = "Id of your account"
  type        = string
}

variable "tags" {
  description = "A map of tags to use on all resources"
  type        = map(string)
  default     = {}
}
