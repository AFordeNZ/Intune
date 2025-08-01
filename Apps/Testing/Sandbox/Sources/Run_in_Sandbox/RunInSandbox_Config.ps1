# Get the directory where this script is located
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition

# Load required .NET assemblies for WPF and MahApps.Metro UI
[System.Reflection.Assembly]::LoadWithPartialName('presentationframework') | out-null
[System.Reflection.Assembly]::LoadFrom("$ScriptDir\assembly\MahApps.Metro.dll") | out-null
[System.Reflection.Assembly]::LoadFrom("$ScriptDir\assembly\MahApps.Metro.IconPacks.dll") | out-null

# Function to load a XAML file and return the XML document
function LoadXml ($global:file1) {
    $XamlLoader = (New-Object System.Xml.XmlDocument)
    $XamlLoader.Load($file1)
    return $XamlLoader
}

# Load the main window XAML definition
$XamlMainWindow = LoadXml("$ScriptDir\RunInSandbox_Config.xaml")
$Reader = (New-Object System.Xml.XmlNodeReader $XamlMainWindow)
# Parse the XAML into a WPF window object
$Form_PS1 = [Windows.Markup.XamlReader]::Load($Reader)

# Get references to all UI controls by their XAML names
$Check_Uncheck_All = $Form_PS1.findname("Check_Uncheck_All")
$Run_EXE = $Form_PS1.findname("Run_EXE")
$Run_MSI = $Form_PS1.findname("Run_MSI")
$Run_PS1 = $Form_PS1.findname("Run_PS1")
$Run_VBS = $Form_PS1.findname("Run_VBS")
$Run_MSIX = $Form_PS1.findname("Run_MSIX")
$Run_PPKG = $Form_PS1.findname("Run_PPKG")
$Run_HTML = $Form_PS1.findname("Run_HTML")
$Extract_ZIP = $Form_PS1.findname("Extract_ZIP")
$Extract_ISO = $Form_PS1.findname("Extract_ISO")
$Share_Folder = $Form_PS1.findname("Share_Folder")
$Run_Reg = $Form_PS1.findname("Run_Reg")
$Run_Intunewin = $Form_PS1.findname("Run_Intunewin")
$Multiple_Apps = $Form_PS1.findname("Multiple_Apps")
$Apply_install = $Form_PS1.findname("Apply_install")
$Run_CMD = $Form_PS1.findname("Run_CMD")
$Open_PDF = $Form_PS1.findname("Open_PDF")

# Add event handler for the 'Check/Uncheck All' checkbox
$Check_Uncheck_All.add_click({
    If($Check_Uncheck_All.IsChecked -eq $True)
    {
        # Check all feature checkboxes
        $Run_EXE.IsChecked = $True
        $Run_MSI.IsChecked = $True
        $Run_PS1.IsChecked = $True
        $Run_VBS.IsChecked = $True
        $Run_PPKG.IsChecked = $True
        $Run_HTML.IsChecked = $True
        $Run_MSIX.IsChecked = $True
        $Extract_ZIP.IsChecked = $True
        $Extract_ISO.IsChecked = $True
        $Share_Folder.IsChecked = $True
        $Run_Reg.IsChecked = $True
        $Run_Intunewin.IsChecked = $True
        $Multiple_Apps.IsChecked = $True
        $Open_PDF.IsChecked = $True
        $Run_CMD.IsChecked = $True
    } else{
        # Uncheck all feature checkboxes
        $Run_EXE.IsChecked = $False
        $Run_MSI.IsChecked = $False
        $Run_PS1.IsChecked = $False
        $Run_VBS.IsChecked = $False
        $Run_PPKG.IsChecked = $False
        $Run_HTML.IsChecked = $False
        $Run_MSIX.IsChecked = $False
        $Extract_ZIP.IsChecked = $False
        $Extract_ISO.IsChecked = $False
        $Share_Folder.IsChecked = $False
        $Run_Reg.IsChecked = $False
        $Run_Intunewin.IsChecked = $False
        $Multiple_Apps.IsChecked = $False
        $Open_PDF.IsChecked = $False
        $Run_CMD.IsChecked = $False
    }
})

# Add event handler for the 'Apply' button
$Apply_install.add_click({
    # Define config file path
    $Run_in_Sandbox_Folder = "C:\ProgramData\Run_in_Sandbox"
    $XML_Config = "$Run_in_Sandbox_Folder\Sandbox_Config.xml"
    $Get_XML_Content = [xml] (Get-Content $XML_Config)

    # Get the status of each feature checkbox
    $EXE_Status = ($Run_EXE.IsChecked).ToString()
    $MSI_Status = ($Run_MSI.IsChecked).ToString()
    $PS1_Status = ($Run_PS1.IsChecked).ToString()
    $VBS_Status = ($Run_VBS.IsChecked).ToString()
    $PPKG_Status = ($Run_PPKG.IsChecked).ToString()
    $HTML_Status = ($Run_HTML.IsChecked).ToString()
    $MSIX_Status = ($Run_MSIX.IsChecked).ToString()
    $ZIP_Status = ($Extract_ZIP.IsChecked).ToString()
    $ISO_Status = ($Extract_ISO.IsChecked).ToString()
    $Folder_Status = ($Share_Folder.IsChecked).ToString()
    $Reg_Status = ($Run_Reg.IsChecked).ToString()
    $Intunewin_Status = ($Run_Intunewin.IsChecked).ToString()
    $MultipleApp_Status = ($Multiple_Apps.IsChecked).ToString()
    $Open_PDF_Status = ($Open_PDF.IsChecked).ToString()
    $Run_CMD_Status = ($Run_CMD.IsChecked).ToString()

    # Update the XML config with the new values
    $Get_XML_Content.Configuration.ContextMenu_EXE         = $EXE_Status
    $Get_XML_Content.Configuration.ContextMenu_MSI         = $MSI_Status
    $Get_XML_Content.Configuration.ContextMenu_PS1         = $PS1_Status
    $Get_XML_Content.Configuration.ContextMenu_VBS         = $VBS_Status
    $Get_XML_Content.Configuration.ContextMenu_PPKG        = $PPKG_Status
    $Get_XML_Content.Configuration.ContextMenu_HTML        = $HTML_Status
    $Get_XML_Content.Configuration.ContextMenu_MSIX        = $MSIX_Status
    $Get_XML_Content.Configuration.ContextMenu_ZIP         = $ZIP_Status
    $Get_XML_Content.Configuration.ContextMenu_ISO         = $ISO_Status
    $Get_XML_Content.Configuration.ContextMenu_Folder      = $Folder_Status
    $Get_XML_Content.Configuration.ContextMenu_Reg         = $Reg_Status
    $Get_XML_Content.Configuration.ContextMenu_Intunewin   = $Intunewin_Status
    $Get_XML_Content.Configuration.ContextMenu_MultipleApp = $MultipleApp_Status
    $Get_XML_Content.Configuration.ContextMenu_PDF         = $Open_PDF_Status
    $Get_XML_Content.Configuration.ContextMenu_CMD         = $Run_CMD_Status

    # Save the updated XML config and close the window
    $Get_XML_Content.Save($XML_Config)
    $Form_PS1.Close()
})

# Show the configuration window
$Form_PS1.ShowDialog() | Out-Null