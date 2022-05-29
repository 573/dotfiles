locals {
  owner = split("/", var.repo_name)[0]
  repo = split("/", var.repo_name)[1]
}

provider "github" {
  alias = "owner"
  owner = local.owner
  token = var.github_token
}

provider "github" {
  alias = "bot"
  token = var.bot_github_token
}

data "github_user" "current" {
  username = ""
  provider = github.bot
}

resource "github_repository_collaborator" "bot" {
  repository = local.repo
  username   = data.github_user.current.login
  permission = "push"
  provider = github.owner
}

resource "github_actions_secret" "bot" {
  repository       = local.repo
  secret_name      = var.actions_secret_name
  plaintext_value  = var.bot_github_token
  provider = github.owner
}

resource "github_user_invitation_accepter" "bot" {
  invitation_id = github_repository_collaborator.bot.invitation_id
  provider = github.bot
}
