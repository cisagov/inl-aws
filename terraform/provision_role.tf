data "aws_iam_policy_document" "assume_role_doc" {
  statement {
    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.users_account_id}:root",
      ]
    }
  }
}

resource "aws_iam_role" "provisionaccount_role" {
    assume_role_policy = data.aws_iam_policy_document.assume_role_doc.json
    name               = "ProvisionAccount"
    description        = "Role to assume for provisioning resources"
}

resource "aws_iam_role_policy_attachment" "provisionaccount_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  role       = aws_iam_role.provisionaccount_role.name
}