variable "project_id" {
    description = "ID for the project"
    type = string
}

variable "project_apis" {
    description = "List of APIs to enable"
    type = list(string)
}