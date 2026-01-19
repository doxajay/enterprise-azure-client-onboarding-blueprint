############################################
# Azure Policy – Deploy NSG Diagnostics
# Streams NSG logs to Log Analytics workspace
############################################

# Get current subscription (for assignment scope)
data "azurerm_subscription" "current" {}

# Lookup the built-in policy definition
data "azurerm_policy_definition" "diag_nsg_to_law" {
  display_name = "Configure diagnostic settings for Azure Network Security Groups to Log Analytics workspace"
}

# Assign the policy at subscription scope
resource "azurerm_policy_assignment" "diag_nsg_to_law" {
  name                 = "deploy-nsg-diagnostics-to-law"
  scope                = data.azurerm_subscription.current.id
  policy_definition_id = data.azurerm_policy_definition.diag_nsg_to_law.id
  display_name         = "Deploy NSG diagnostic settings to Log Analytics"

  # Required for DeployIfNotExists
  identity {
    type = "SystemAssigned"
  }

  # Policy parameters (must match policy schema exactly)
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

############################################
# RBAC – Allow policy to deploy diagnostics
############################################

# Allow policy to configure diagnostic settings
resource "azurerm_role_assignment" "diag_nsg_monitoring_contributor" {
  scope                = data.azurerm_subscription.current.id
  role_definition_name = "Monitoring Contributor"
  principal_id         = azurerm_policy_assignment.diag_nsg_to_law.identity[0].principal_id
}

# Allow policy to write to Log Analytics
resource "azurerm_role_assignment" "diag_nsg_law_contributor" {
  scope                = azurerm_log_analytics_workspace.law.id
  role_definition_name = "Log Analytics Contributor"
  principal_id         = azurerm_policy_assignment.diag_nsg_to_law.identity[0].principal_id
}
