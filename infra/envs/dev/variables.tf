variable "db_username" {
  description = "PostgreSQL username"
  type        = string
  default     = "postgres"
}

variable "db_password" {
  description = "PostgreSQL password"
  type        = string
  sensitive   = true
}

variable "gemini_api_key" {
  description = "Google Gemini API Key for sentiment analysis"
  type        = string
  sensitive   = true
}
