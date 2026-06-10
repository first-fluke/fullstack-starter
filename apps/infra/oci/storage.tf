# Object Storage buckets (mirror aws/storage.tf). Bucket names are unique per
# namespace, so no account-id suffix is needed.

# Uploads bucket (private)
resource "oci_objectstorage_bucket" "uploads" {
  compartment_id = oci_identity_compartment.main.id
  namespace      = local.namespace
  name           = "${local.name_prefix}-uploads"

  access_type = "NoPublicAccess"
  versioning  = var.environment == "prod" ? "Enabled" : "Disabled"

  auto_tiering = "Disabled"

  freeform_tags = local.common_tags
}

# Lifecycle: expire old uploads after 90 days (aws/storage.tf parity).
# Requires the Object Storage service permission created in iam.tf
# (oci_identity_policy.object_lifecycle).
resource "oci_objectstorage_object_lifecycle_policy" "uploads" {
  namespace = local.namespace
  bucket    = oci_objectstorage_bucket.uploads.name

  rules {
    name        = "expire-old-uploads"
    action      = "DELETE"
    is_enabled  = true
    time_amount = 90
    time_unit   = "DAYS"
  }

  depends_on = [oci_identity_policy.object_lifecycle]
}

# Static assets bucket.
# Private by design: OCI has no first-party CDN (no CloudFront / Cloud CDN /
# Front Door equivalent — see README Notes). Serve objects either through
# pre-authenticated requests (PARs) generated per object/prefix:
#   oci os preauth-request create --bucket-name <bucket> --access-type ObjectRead ...
# or put a third-party CDN (e.g. Cloudflare) in front and switch access_type
# to ObjectRead for public reads.
resource "oci_objectstorage_bucket" "static" {
  compartment_id = oci_identity_compartment.main.id
  namespace      = local.namespace
  name           = "${local.name_prefix}-static"

  access_type = "NoPublicAccess"
  versioning  = "Disabled"

  auto_tiering = "Disabled"

  freeform_tags = local.common_tags
}
