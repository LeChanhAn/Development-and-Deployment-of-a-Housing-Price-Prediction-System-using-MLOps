data "aws_iam_policy_document" "repository_policy" {
  dynamic "statement" {
    for_each = length(var.allow_pull_principals) > 0 ? [1] : []
    content {
      sid    = "AllowPull"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.allow_pull_principals
      }
      actions = [
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchGetImage",
        "ecr:BatchCheckLayerAvailability"
      ]
    }
  }

  dynamic "statement" {
    for_each = length(var.allow_push_principals) > 0 ? [1] : []
    content {
      sid    = "AllowPush"
      effect = "Allow"
      principals {
        type        = "AWS"
        identifiers = var.allow_push_principals
      }
      actions = [
        "ecr:PutImage",
        "ecr:InitiateLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:CompleteLayerUpload"
      ]
    }
  }
}