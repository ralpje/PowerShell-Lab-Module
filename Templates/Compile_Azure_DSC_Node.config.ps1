#region Azure Login

Login-AzureRmAccount

#endregion

#region upload config



Import-AzureRmAutomationDscConfiguration -SourcePath "<fill me in>" `
                                         -Published `
                                         -ResourceGroupName "<fill me in>" `
                                         -AutomationAccountName "<fill me in>" `
                                         -Force

#endregion

#region compile config

$ConfigData = @{             
    AllNodes = @(             
        @{             
            Nodename = "*"             
        }

        @{             
            Nodename = "<fill me in>"
            Role = "<fill me in>"             
        }
        
       
   )             
}             

Start-AzureRmAutomationDscCompilationJob -ResourceGroupName "<fill me in>" `
                                         -AutomationAccountName "<fill me in>" `
                                         -ConfigurationName "<fill me in>" `
                                         -ConfigurationData $ConfigData

#endregion