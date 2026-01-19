data "azurerm_subscription" "current" {}

data "azurerm_policy_definition" "diag_nsg_to_law" {
  display_name = "Configure diagnostic settings for Azure Network Security Groups to Log Analytics workspace"
}

resource "azurerm_policy_assignment" "diag_nsg_to_law" {
  name                 = "deploy-diag-nsg-to-law"
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_definition.diag_nsg_to_law.id
  display_name         = "Deploy NSG diagnostic settings to Log Analytics"

  # DeployIfNotExists policies typically need an identity to perform the deployment
  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    effect = {
      value = "DeployIfNotExists"
    }

    logAnalytics = {
      value = azurerm_log_analytics_workspace.law.id
    }

    diagnosticsSettingNameToUse = {
      value = "setByPolicy"
    }

    NetworkSecurityGroupEventEnabled = {
      value = "True"
    }

    NetworkSecurityGroupRuleCounterEnabled = {
      value = "True"
    }
  })
}
