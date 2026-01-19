############################################
# Azure Policy – Deploy NSG Diagnostics to Log Analytics
############################################

data "azurerm_policy_definition" "diag_nsg_to_law" {
  display_name = "Configure diagnostic settings for Azure Network Security Groups to Log Analytics workspace"
}

resource "azurerm_subscription_policy_assignment" "diag_nsg_to_law" {
  name                 = "deploy-nsg-diagnostics-to-law"
  subscription_id      = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_definition.diag_nsg_to_law.id
  display_name         = "Deploy NSG diagnostic settings to Log Analytics"

  identity {
    type = "SystemAssigned"
  }

  parameters = jsonencode({
    NetworkSecurityGroupEventEnabled        = { value = "True" }
    NetworkSecurityGroupRuleCounterEnabled  = { value = "True" }
    diagnosticsSettingNameToUse             = { value = "setByPolicy" }
    effect                                  = { value = "DeployIfNotExists" }
    logAnalytics                            = { value = azurerm_log_analytics_workspace.law.id }
  })
}

############################################
# RBAC – Allow policy to deploy diagnostics
############################################

resource "azurerm_role_assignment" "diag_nsg_monitoring_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_subscription_policy_assignment.diag_nsg_to_law.identity[0].principal_id
}

resource "azurerm_role_assignment" "diag_nsg_law_contributor" {
  scope                = azurerm_log_analytics_workspace.law.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_subscription_policy_assignment.diag_nsg_to_law.identity[0].principal_id
}
