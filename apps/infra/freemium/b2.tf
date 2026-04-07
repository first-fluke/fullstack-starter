resource "b2_bucket" "main" {
  bucket_name = "${var.project_prefix}-storage"
  bucket_type = "allPrivate"
}

resource "b2_application_key" "main" {
  key_name     = "${var.project_prefix}-key"
  bucket_id    = b2_bucket.main.bucket_id
  capabilities = ["readFiles", "writeFiles", "listFiles", "deleteFiles"]
}
