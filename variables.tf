variable "environment" {
  description = "Enter environment e.g. UAT, Production, Development, SharedServices"
}

variable "profile" {
  type = map(string)
}


variable "environmentVariables" {
  type      = map(string)
  sensitive = true

}

variable "secret_string" {
  default = {
    username = "FS-username"
    password = "FS-secret-password"
    host = "FS-secret-hostname"
    share = "FS-secret-sharename"
  }
  type = map(string)
}