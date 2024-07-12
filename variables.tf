variable "project_id" {
  description = "The ID of the Google Cloud project"
  type        = string
  default     = "sukrit-singh-426716"  # Replace with your actual project ID
}

variable "region" {
  description = "The region for resources like the MIG"
  type        = string
  default     = "us-central1"  # Replace with your desired region
}

variable "zone" {
  
  description = "The zone for resources like the MIG"
  type        = string
  default     = "us-central1-c"  # Replace with your desired zone
}

variable "instance_type" {
  description = "The machine type for instances in the MIG"
  type        = string
  default     = "e2-medium"  # Example instance type, adjust as needed
}
