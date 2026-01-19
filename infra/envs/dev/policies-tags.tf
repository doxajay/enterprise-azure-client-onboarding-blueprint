

data "azurerm_policy_definition" "require_tag" {
  display_name = "Require a tag on resources"
}

resource "azurerm_policy_assignment" "require_environment_tag" {
  name                 = "require-environment-tag"
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_definition.require_tag.id
  display_name         = "Require Environment tag on all resources"

  parameters = jsonencode({
    tagName = { value = "Environment" }
    effect  = { value = "Deny" }
  })
}
